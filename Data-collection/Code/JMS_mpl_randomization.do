
/*******************************************************************************
File:			mpl_randomization.do

Version:		v1.0

Description:	This dofile uses a pre-defined sample, including any 
				stratification variables, to define the randomization variables
				that define the randomized presentation of MPL.
				
				For a detailed description of how to use this template, please
				see: https://github.com/MPL-WTP/MPL-WTP 

Inputs:			MPL input: spreadsheet with list of options -- MPL_input.csv				
				Pre-defined sample: A csv file containing a pre-defined sample 
				with an ID variable for each individual and all stratification 
				variables -- sampledata.csv
				Stata globals: See below for required user inputs
					
Outputs:		Sample data with appended randomization variables in csv format
				-- sampledata_rand.csv

Authors:		Kelsey Jack, Kathryn McDermott, Anja Sautmann,
				Kenneth Chan, Lei Yue


*******************************************************************************/




********************************************************************************
********************************************************************************

*						SECTION 1: SET PARAMETERS

********************************************************************************
********************************************************************************


// Version number, input/output paths along with file names.



clear all
macro drop _all
set more off
version 14.2


****************** User Edit Section ******************

*** !!! To users: please make necessary EDITS here ***
* Edits start --> ###


** 1. Please specify your file paths for inputs and outputs * 
* With relative paths, use path from input folder to outputfolder for outputpath
global inputpath   /yourpath/MPL-WTP/1_Data_Collection/Example/Input/
global outputpath   ../Output/


** 2. Please specify the csv file defining the MPL options
global INPUT JMS_example_mpl_input.csv


** 3. Please specify sample  data in csv format, omitting .csv file ending
global SAMPLE JMS_example_sampledata


** 4. Please specify options in different MPLs
* If there are e.g. 3 options in total (A,B,C), specify which options are option 1 and option 2 in each mpl. 
* eg: global mpl1 AB. In this example, in MPL1, option A will be option 1
* and option B will be option 2. 
global mpl1 AB
global mpl2 AC
global mpl3 BC

** 5. Please specify number of MPLs asked of each respondent.
* If this is left blank it will automatically be set to 1.
global NO_MPL 2

** 6. Please specify identifying variable in the pre-defined sample.
global IDvar id


********** Optional inputs **************

* Stratification variables

** 7. Please specify names of strata, e.g. location = strata1, income = strata2
global STRATA strata1 strata2 

** 8. Please specify if you would like to use screen side and choice order randomization
* Screen side randomization. 
* Set to 1 for side of screen randomization and 0 for no screen side randomization
global SCREEN_RAND 1

* Choice order randomization
* Set to 1 for choice order randomization and 0 for no choice order randomization. 
global CHOICE_ORDER_RAND 1

* MPL order randomisation
* Set to 1 for randomisation of MPL displayed. If there is no randomisation, 
* MPLs will be displayed in numerical order
global MPL_ORDER_RAND 0

** 9. Please specify a random seed
* Random seed
global SEED 2397542 

********************************************************************************


cd "${inputpath}"


* Number of options
import delimited "${INPUT}", clear case(preserve)

qui ds option*

local opt "`r(varlist)'"

global NO_OPTIONS : list sizeof local(opt)

global NO_BINARY_CHOICES `c(N)'


* define SAMPLEext global to include file extension

global SAMPLEext "${SAMPLE}.csv"

* If there are pre-defined stratification variables:

* store number of categories in each in STRATA`i'

local pre_sample : list sizeof global(SAMPLEext)
if `pre_sample' != 0 {
	clear 
	import delimited ${SAMPLEext}
	local i 1
	foreach var in $STRATA {
		qui tab `var'
		global STRATA`i' `r(r)'
		local ++i
	}
}

qui ds
local samp_vars `r(varlist)'


* store no. of stratification groups in local i by multiplying out # of categories
local i 1
local s_len : list sizeof global(STRATA)

forval s = 1/`s_len' {
	local i = `i' * ${STRATA`s'}
	
	di "`i'"
}

global NO_STRATA `i'

* Check the number of possible combinations of MPL
local stop 0
local mpl_comb = 1
while `stop' == 0 {
	if missing("${mpl`mpl_comb'}") {
		local stop 1
		local --mpl_comb
	}
	else {
		local ++mpl_comb
	}
}

di "Number of different MPL: `mpl_comb'"
di "Number of MPL per subject: ${NO_MPL}"


* Number of combinations of different MPL 
global COMB = round(exp(lnfactorial(`mpl_comb'))/(exp(lnfactorial(`mpl_comb'-${NO_MPL}))))

di "Number of MPL combinations: ${COMB}$"


* Assign mpl combinations a numeric value //AS: this needs editing.
preserve

	forval x = 1/$NO_MPL {
		clear
		set obs `mpl_comb'
		gen rand_mpl_`x' = _n
		tempfile file`x'
		save `file`x''
		local tm = "`tm' rand_mpl_`x'"
	}

	use `file1', clear
	forval x=  2/$NO_MPL  {
		cross using `file`x''
	}

	forval x=  1/$NO_MPL  {
	local y 1
		while `y' < $NO_MPL  {
			if `x' == `y' {
			 local ++y
			}
			else {
*				count if mpl_`y'
				drop if rand_mpl_`y' == rand_mpl_`x'
				local ++y
			}
		}
	}
		
	sort `tm'


	gen mpl_c = _n

	tempfile mpl_cd
	save `mpl_cd'

restore



**

* Number of obs per strata
local s_size = ceil(_N/`i') 
local `s_size'
di `s_size'



* Randomize

* Generate random variable
set seed $SEED


gen rand = runiform()
gen rand2 = runiform()




* Observations per strata
bysort $STRATA: gen size=_N

gen misfit_order = mod(size, $COMB)



* Assigned MPL - if more than one
gen mpl_c = .

sum size

local e `r(max)'

local i 1

while `i' <= `e' {

	forval j = 1/$COMB {
		bys $STRATA (rand) : replace mpl_c = `j' if _n ==  `i' 
		local ++i
		
	}

}


* misfits
* bys $STRATA (rand) : replace mpl_c = . if _n >= _N - misfit_order + 1
sum misfit 
local e = `r(max)' - 1

local i 0


tempvar t1 t2

sort $STRATA rand
gen `t1' = _n in 1/$COMB
bys rand2: gen `t2' = _n if `t1' != .
bys `t2': replace `t2' = _n if `t2' != .

tab `t1' `t2' `t3'

gen temp = .
forval i = 1/$COMB{
	qui sum `t2' if `t1' == `i'
	replace temp = `r(mean)' if mpl_c == `i' 
	
}

bys $STRATA (rand) : replace mpl_c = temp if _n >= _N - misfit_order + 1
		

drop rand rand2


merge m:1 mpl_c using `mpl_cd', nogen




drop mpl_c 


if $MPL_ORDER_RAND == 0 {
	reshape long rand_mpl_, i(id) j(j) 
	sort id rand_mpl_
	bys id: replace j = _n
	reshape wide rand_mpl_, i(id) j(j) 
}


* Choice order
sort id

forval i = 1/$NO_MPL {
	gen rand`i' =  runiform()
	bys $STRATA (rand`i'): gen choice_order_rand_`i' = _n > _N/2
	replace choice_order_rand_`i' = -1 if choice_order_rand_`i' == 0
	label var choice_order_rand_`i' "Order MPL `i'"
}

* Misfits choice order
forval i = 1/$NO_MPL {
	gen mis`i' = mod(size, 2)
	bys $STRATA (rand`i'): gen rep`i' = round(runiform())  if _n == _N & mis`i' == 1
	replace choice_order_rand_`i' = -1 if choice_order_rand_`i' == 0
	drop mis`i' 
}




* Side of screen order

if $SCREEN_RAND == 1 {
	forval i = 1/$NO_MPL {
		forval x = 1/$NO_BINARY_CHOICES {
			gen tscreen_side_rand_`i'_`x' = .
		}
		reshape long tscreen_side_rand_`i'_ , i(id)
		gen randside`i' = runiform()
		bys id (randside`i'): replace tscreen_side_rand_`i'_ = _n > _N/2
		replace tscreen_side_rand_`i'_ = -1 if tscreen_side_rand_`i'_ == 0
		drop randside`i'

		reshape wide tscreen_side_rand_`i'_ , i(id) j(_j)
		
		rename tscreen_side_rand_`i'* screen_side_rand*_`i'
		forval x = 1/$NO_BINARY_CHOICES {
			label var screen_side_rand_`x'_`i' "Order choice `x' of MPL `i'"
		}

		order screen_side_rand_1_`i'-screen_side_rand_${NO_BINARY_CHOICES}_`i' , last

	}
	

	
	
}
else {
	forval i = 1/$NO_MPL {
		forval x = 1/$NO_BINARY_CHOICES {
			gen screen_side_rand_`x'_`i' = 1
		}
		
	}
}	

* replace all choice order = 1 if set to not randomize
if $CHOICE_ORDER_RAND == 0 {
	forval i = 1/$NO_MPL {
		replace choice_order_rand_`i' = 1
	}
}






keep `samp_vars' rand_mpl* choice* screen*
order `samp_vars'  rand_mpl* choice* screen*

***
* Show randomization
di "**************************"
di "Randomization Verification"
di "**************************"


forval i = 1/$NO_MPL {
	bys $STRATA: tab choice_order_rand_`i'
}
	
forval i = 1/2 {	
	forval x = 1/$NO_BINARY_CHOICES {
		tab screen_side_rand_`x'_`i' 
	}
}


 sort ${IDvar}


 export delimited "${outputpath}${SAMPLE}_rand.csv" , replace


clear all

