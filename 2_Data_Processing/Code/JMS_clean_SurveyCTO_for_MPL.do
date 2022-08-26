/*******************************************************************************
File: 			JMS-SurveyCTO_Clean_for_MPL.do

Description:	Prepares data from completed SurveyCTO survey for analysis
				using 

Version: 		v1.0

Inputs: 		MPL input: spreadsheet with list of options -- MPL_input.csv
				Survey data: Stata .dta file with survey responses -- `your_mpl_from_SurveyCTO'.dta

Output:	    	Analysis ready dataset `MPL_your_cleaned_data'.dta
			
Authors:		Kelsey Jack, Kathryn McDermott, Anja Sautmann,
				Kenneth Chan, Lei Yue

Date:	    	August 23, 2022
*******************************************************************************/

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
global inputpath  "~/MPL-WTP/2_Data_Processing/Example/Input"
global outputpath   ../Output/

** 2. Please specify the input .csv file with options
global INPUT JMS_example_mpl_input.csv


** 3. Please specify .dta file from SurveyCTO
global SCTO_DATA JMS_example_surveydata.dta 

** 4. Please options in different MPLs
*     Should be the same as what you specified in JMS_create_surveycto_form.do file
global mpl1 AB
global mpl2 AC
global mpl3 BC


* 5. Please specify the name of output .dta file
global OUTPUT JMS_example_processed_mpl.dta

** <-- Edits end ###

*******************************************************


cd "${inputpath}"


* Number of options
import delimited "${INPUT}", clear case(preserve) stringcols(_all)

qui ds option*

local opt "`r(varlist)'"

global NO_OPTIONS : list sizeof local(opt)

global NO_BINARY_CHOICES `c(N)'

* Assign letters to each MPL option in the input file
local x 0
global let
global n_mpl 0
	
	foreach l in `c(ALPHA)' {
		local ++x
		if `x' <= ${NO_OPTIONS}	{
			global let = "$let `l'"
			local n_mpl = `n_mpl' + 1
		}
		else {
			continue
		}
	
	}
	

* Generate files to merge to survey answers to calculate value difference
foreach l in $let {
	preserve
		keep option`l' value_option`l' 
		
		rename *`l' *
		
		gen binary_choice_no = _n
		
		gen option1 = "`l'"
				
		tempfile file_opt`l'1
		save `file_opt`l'1'
		
		rename option1 option2
		
		gsort -binary_choice_no
		replace binary_choice_no = _n

		tempfile file_opt`l'2
		save `file_opt`l'2'
		
	restore
}	
	

	
********************************************************************************
****	Open file and create long data
********************************************************************************

use ${SCTO_DATA}, clear

drop next* 
drop c_mpl*

* check number of MPLs that can be asked
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


** find the number of choice sets asked to each respondent
if `mpl_comb' == 1{
	gen rand_mpl_1 = "1"
}
	qui ds rand_mpl*
	local no_mpl "`r(varlist)'"
	global NO_MPL: list sizeof local(no_mpl)



tostring id, replace


* Generate variable with choices
qui{
	local mplvars ""
	forval i = 1/ $NO_MPL {
		forval x = 1 / $NO_BINARY_CHOICES {
			gen mpl_`x'_`i' = ""
			if `i' == 1 {
				local mplvars "`mplvars' mpl_`x'_"
				local randvars "`randvars' screen_side_rand_`x'_"
			}
		}
		
	}

	forval i = 1/ $NO_MPL {
		forval x = 1 / $NO_BINARY_CHOICES {
			forval j = 1/`mpl_comb' {
				replace mpl_`x'_`i' = mpl`j'_order1_side1_choice`x'_`i'    if choice_order_rand_`i' == "1" & screen_side_rand_`x'_`i' == "1" & rand_mpl_`i' == "`j'"
				replace mpl_`x'_`i' = mpl`j'_ordern1_side1_choice`x'_`i'   if choice_order_rand_`i' == "-1" & screen_side_rand_`x'_`i' == "1" & rand_mpl_`i' == "`j'"
				replace mpl_`x'_`i' = mpl`j'_order1_siden1_choice`x'_`i'   if choice_order_rand_`i' == "1" & screen_side_rand_`x'_`i' == "-1" & rand_mpl_`i' == "`j'"
				replace mpl_`x'_`i' = mpl`j'_ordern1_siden1_choice`x'_`i'  if choice_order_rand_`i' == "-1" & screen_side_rand_`x'_`i' == "-1" & rand_mpl_`i' == "`j'"
			}
		}
	}
}

* Clean up
drop mpl*_order*_side*_choice* 

reshape long `mplvars' `randvars' rand_mpl_ choice_order_rand_, i(id) j(mpl_order)

rename *_ *

gen t_id = id + string(mpl_order)

reshape long mpl_ screen_side_rand_, i (t_id) j(binary_choice_no)

rename *_ *
drop t_id



gen option1 = ""
gen option2 = ""
gen mpl_option1 = ""
gen mpl_option2 = ""
gen value_option1 = ""
gen value_option2 = ""


forval x = 1/`mpl_comb' {
	replace option1 = substr("${mpl`x'}", 1, 1) if rand_mpl == "`x'"
	replace option2 = substr("${mpl`x'}", 2, 1) if rand_mpl == "`x'"
}


* Merge to options spreadsheet generate values varaibles

qui{
	foreach l in $let {
		merge m:1 option1 binary_choice_no using `file_opt`l'1', nogen keep(1 3)
		replace mpl_option1 = option if mpl_option1 == ""
		replace value_option1 = value_option if value_option1 == ""
	
		drop option value_option

		merge m:1 option2 binary_choice_no using `file_opt`l'2', nogen  keep(1 3)
		replace mpl_option2 = option if mpl_option2 == ""
		replace value_option2 = value_option if value_option2 == ""

		drop option value_option


	}
}

* calulate value difference
destring value_option1, replace
destring value_option2, replace

gen     value_chosen = value_option1 if mpl == option1
replace value_chosen = value_option2 if mpl == option2

gen     option_chosen = 1 if mpl == option1
replace option_chosen = 2 if mpl == option2
label var option_chosen "MPL option chosen (1 or 2)"

gen valdiff = value_option1 - value_option2
label var valdiff "value of Option 1 - Option 2"

rename mpl mpl_chosen
label var mpl_chosen "MPL chosen"


* choice order
lab var choice_order_rand "binary choice order (asc -1 or desc 1)"
label define choice_order_rand -1 "asc (in terms of valdiff): Option 1 low to high value" 1 "des (in terms of valdiff): Option 1 high to low value"

* screen order
lab var screen_side_rand "screen side (left 1 or right -1)"
label define screen_side_rand -1 "Option 1 on right" 1 "Option 1 on left"

sort id mpl_order binary_choice_no
order id mpl_order binary_choice_no rand_mpl choice_order_rand screen_side_rand mpl_chosen ///
	option_chosen valdiff


label var id "Subject ID"	
label var binary_choice_no "Binary choice number w/i MPL"
label var option1 "Option 1"
label var option2 "Option 2"
label var mpl_option1 "Option 1's type and value"
label var mpl_option2 "Option 2's type and value"
label var value_option1 "Value of Option 1"
label var value_option2 "Value of Option 2"
label var realized_mpl "Realized MPL"
label var realized_choice "Realized choice number w/i realized MPL"
label var mpl_chosen "MPL option chosen (letter)"
label var value_chosen "MPL option chosen (value)"
label var mpl_order  "Order of MPL w/i subject" 

destring choice_order_rand,  replace
destring screen_side_rand,  replace
destring rand_mpl,  replace
	

* generate indicator for choosing Option 1
gen     wtp_chose_option1 = .
replace wtp_chose_option1 = 1 if option_chosen == 1
replace wtp_chose_option1 = 0 if option_chosen == 2
label var wtp_chose_option1 "Option 1 value is chosen (0/1)"

* generate wtp dummies for MPLs
forval x = 1/`mpl_comb' {
	local o1 = substr("${mpl`x'}", 1, 1)
	local o2 = substr("${mpl`x'}", 2, 1)
	gen WTP_`o1'_vs_`o2' = 0
	replace WTP_`o1'_vs_`o2' = 1 if rand_mpl == `x'
	lab var WTP_`o1'_vs_`o2' "Dummy for MPL `o1' vs `o2'"
}


egen subject_mpl_id = group(id mpl_order)
lab var subject_mpl_id "MPL by subject ID"

rename rand_mpl mpl_type
lab var mpl_type "MPL type"


order id  subject_mpl_id  mpl_order mpl_type binary_choice_no  ///
	wtp_chose_option1 valdiff  WTP* choice_order_rand screen_side_rand ///
	option1 option2 mpl_option1 mpl_option2 value_option1 value_option2 ///
	mpl_chosen option_chosen value_chosen ///
	realized_mpl realized_choice ///
	deviceid subscriberid simid devicephonenum username duration caseid  ///
	formdef_version key submissiondate starttime endtime

********************************************************************************
****	Save .dta for xtprobit analysis (using `mplwtp' command)
********************************************************************************

save "${outputpath}${OUTPUT}", replace




