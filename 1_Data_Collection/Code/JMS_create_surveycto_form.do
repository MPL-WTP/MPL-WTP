/*******************************************************************************
File:			JMS_create_surveycto_form.do

Version			v1.0

Description:	Ths dofile creates a SurveyCTO survey form to implement a 
				multiple price list choice experiment. 
				
				For a detailed description of how to use this template, please
				see: https://github.com/MPL-WTP/MPL-WTP 

Inputs:			MPL input: spreadsheet with list of options -- 		MPL_input.csv				
				Blank SurveyCTO template form 				
				Stata globals: See below for required user inputs
					
Outputs:		SurveyCTO survey form in xlsx format 

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
global inputpath   /yourpath/MPL-WTP/1_Data_Collection/Example/Input
global outputpath   ../Output/


* Set choice parameters -------------------------------------------------------


** 2. Please specify the input .csv file with options
global INPUT JMS_example_mpl_input.csv

** 3. Please specify blank SurveyCTO form 
global SCTO_FORM JMS_example_surveyCTO_form.xlsx

** 4. Optional: please specify the file containing the randomization variables
* This file can be created from a pre-defined sample by JMS_mpl_randomization.do.
* If no such file is specified, all randomization will be carried out using 
* SurveyCTO's internal random numbers generator.
global RAND_DATA JMS_example_sampledata_rand.csv

** 5. Please specify options in different MPLs
* If there are e.g. 3 options in total (A,B,C), specify which options are option 1 and option 2 in each mpl. 
* eg: global mpl1 AB. In this example, in MPL1, option A will be option 1
* and option B will be option 2.
* Please use the same macros and ordering of MPLs as in the randomization file.
global mpl1 AB
global mpl2 AC
global mpl3 BC

** 6. Please specify number of MPLs asked of each respondent.
* If this is left blank it will automatically be set to 1.
global NO_MPL 2

** 7. Please specify survey question phrasing

* Question start:
global Q_START "Which would you prefer: "

* Or
global Q_OR " or "

* Instruction
global Q_INSTR "Tap one of the pictures to make your choice."

* Next
global Q_NEXT "Please tap Next when you have made you decision." 



** <-- Edits end ###

*******************************************************

cd "${inputpath}"






********************************************************************************
********************************************************************************

*				SECTION 3: PROGRAM SURVEY FORM

********************************************************************************
********************************************************************************

* Variable names in surveycto form
import excel "${SCTO_FORM}", clear firstrow sheet("survey")

qui ds 
global SCTOVARS `r(varlist)'



* Number of options and binary choices
import delimited "${INPUT}", clear case(preserve)

qui ds option*

local opt "`r(varlist)'"

global NO_OPTIONS : list sizeof local(opt)

global NO_BINARY_CHOICES `c(N)'






*-------------------------------------------------------------------------------
*	3.1. Calculations and randomization
*-------------------------------------------------------------------------------

/*	
	This sections checks if preloaded data is specified. 
	If preloaded data is specified, random variables will come from data
	If no data is specified, randomization will be done in SurveyCTO 
*/



foreach var in $SCTOVARS {
	gen `var' = ""
}

* Check if randomization data is specified. 
local e_d : list sizeof global(RAND_DATA)
* if no prepopulated data specified, `e_d' = 0


* check for randomization variable
if `e_d' > 0 {
	import delimited "${outputpath}${RAND_DATA}", clear
	

}

	cap ds rand_mpl*
	if _rc == 0 {
		local rand_mpl 1
	}
	else {
		local rand_mpl 0
	}
	
	cap ds choice_order_rand*
	if _rc == 0 {
	 
		local choice_order_rand 1
	}
	else {
		local choice_order_rand 0
	}
	
	cap ds screen_side_rand*
	if _rc == 0 {
		local screen_side_rand 1
	}
	else {
		local screen_side_rand 0
	}

	cap ds rand_pay*
	if _rc == 0 {
		local rand_pay 1
	}
	else {
		local rand_pay 0
	}
	
	cap ds id 
	if _rc == 0 {
		global ID id
	}


clear 	
local obs = 2*${NO_MPL} + ${NO_BINARY_CHOICES}*${NO_MPL} + 5
di "`obs'"
set obs `obs'

foreach var in $SCTOVARS {
	gen `var' = ""
}


* ID variables

replace type = "text" in 1
replace label = "Input ID" in 1
replace name = "id" in 1

//index so that each calculation is in a new row
local i 2

* if(expression, valueiftrue, valueiffalse)

	* randomly assign choice_set
	if  `e_d' == 0 | `rand_mpl' == 0 {
	
		forval x = 1/$NO_MPL {
			replace calculation = "once(round(random()*$NO_OPTIONS, 0))" in `i'
			replace type = "calculate" in `i'
			replace name = "rand_mpl_`x'" in `i'
			
			local ++i
		}
	}
	else {
		if $NO_MPL > 1 {
			 
			forval x = 1/$NO_MPL {
				replace calculation = "pulldata('$RAND_DATA', 'rand_mpl_`x'', '$ID', \${$ID})" in `i'
				replace type = "calculate" in `i'
				replace name = "rand_mpl_`x'" in `i'
				
				local ++i
			}
		}
	
	
	}
	
	* randomly specify order in which questions asked (direction)
	if `e_d' == 0 | `choice_order_rand' == 0 {
	
		forval x = 1/$NO_MPL {
			replace calculation = "once(random() > 0.5, 1, -1)" in `i'
			replace type = "calculate" in `i'
			replace name = "choice_order_rand_`x'" in `i'
			
			local ++i
		}
	}
	else {
		forval x = 1/$NO_MPL {
			replace calculation = "pulldata('$RAND_DATA', 'choice_order_rand_`x'', '$ID', \${$ID})" in `i'
			replace type = "calculate" in `i'
			replace name = "choice_order_rand_`x'" in `i'
			
			local ++i
		}
	
	}
	
	* randomly specify side of the screen
	if `e_d' == 0 | `screen_side_rand' == 0 {
	
		forval x = 1/$NO_MPL {
			forval y = 1/$NO_BINARY_CHOICES {
				replace calculation = "once(random() > 0.5, 1, -1)" in `i'
				replace type = "calculate" in `i'
				replace name = "screen_side_rand_`y'_`x'" in `i'
				
				local ++i
			}
		}
	}
	else {
	
		forval x = 1/$NO_MPL {
			forval y = 1/$NO_BINARY_CHOICES {
				replace calculation = "pulldata('$RAND_DATA', 'screen_side_rand_`y'_`x'', '$ID', \${$ID})" in `i'
				replace type = "calculate" in `i'
				replace name = "screen_side_rand_`y'_`x'" in `i'
				
				local ++i
			}
		}
	
	
	
	}
	
	* randomly choose payout mpl
	if `e_d' == 0 | `rand_pay' == 0 {

		replace calculation = "once(round(random()*($NO_MPL - 1), 0) + 1)" in `i'
		replace type = "calculate" in `i'
		replace name = "realized_mpl" in `i'
		
		local ++i

	}
	else {
		replace calculation = "pulldata('$RAND_DATA', 'rand_payout', '$ID', \${$ID})" in `i'
		replace type = "calculate" in `i'
		replace name = "realized_mpl" in `i'
		
		local ++i	
	
	}
	
	* randomly choose payout choice
	local e_cs : list sizeof global(PAYOUT)
	if `e_d' == 0 | `rand_pay' == 0 {

		replace calculation = "once(round(random()*($NO_BINARY_CHOICES - 1), 0) + 1)" in `i'
		replace type = "calculate" in `i'
		replace name = "realized_choice" in `i'
		
		local ++i

	}
	else {
		replace calculation = "pulldata('$RAND_DATA', 'rand_payout', '$ID', \${$ID})" in `i'
		replace type = "calculate" in `i'
		replace name = "realized_choice" in `i'
		
		local ++i	
	
	}
	

	
	keep $SCTOVARS
	order $SCTOVARS

	tempfile calculate
	save `calculate'


////////////////////////////////////////////////////////////////////////////////

*------------------------------------------------------------------------------
*   	3.2. Create all possible choice sets
*------------------------------------------------------------------------------

import delimited "${INPUT}", clear case(preserve)


local x 0
global let
	
	foreach l in `c(ALPHA)' {
		local ++x
		if `x' <= ${NO_OPTIONS}	{
			global let = "$let `l'"
		}
		else {
			continue
		}
	
	}
	

di "$let"



* Check if image files included. Add if do not exist
qui {
	cap ds image_option*
	if _rc != 0 {
		foreach x in $let {
			gen image_option`x' = ""
		}
	}

}
* Generate variable with order of options
gen order = _n

foreach i in $let {
	preserve
		keep option`i' value_option`i' order image_option`i'
		
		
		gen choice_no_asc = order
		
		gen choice_no_desc = $NO_BINARY_CHOICES + 1 - choice_no_asc
		
		drop order
		
		tempfile o`i'
		save `o`i''
	restore
	
}

clear

set obs $NO_BINARY_CHOICES


local i 1
local cont 1

while `cont' == 1 {
	cap macro list mpl`i'
	if _rc == 0 {
		
		clear

		set obs $NO_BINARY_CHOICES

		gen mpl_no = `i'

		local opt1 = substr("${mpl`i'}", 1, 1)
		local opt2 = substr("${mpl`i'}", 2, 1)

		


		gen option1 = "`opt1'"
		gen option2 = "`opt2'"

		gen choice_no_asc = _n
		gen choice_no_desc = _n

		merge 1:1 choice_no_asc using `o`opt1'', gen(asc)
		merge 1:1 choice_no_desc using `o`opt2'', gen(desc)


		gen q_o1 = option`opt1'
		gen q_o2 = option`opt2'

		gen value1 = value_option`opt1'
		gen value2 = value_option`opt2'


		gen image1 = image_option`opt1' 
		gen image2 = image_option`opt2'

		cap append using `temp'
		tempfile temp
		save `temp'
	
			
		local ++i
		
	}
	else {
		local cont 0
	}

}




use `temp', clear
keep option1 option2 choice_no_asc q_o1 q_o2 value1 value2 image1 image2 mpl

rename choice_no choice_no

* create a variable of the order is appears to subjects
clonevar view_choice_no = choice_no

sort option1 option2 choice_no



gen dir = "1"


tempfile dir1
save `dir1'

replace view_choice_no = $NO_BINARY_CHOICES + 1 - choice_no

sort option1 option2 view_choice_no

replace dir = "N1"

append using `dir1'


sort mpl_no dir view_choice_no

** Create the full choice sets
* starting point for creating multiple choice sets
tempfile tempstart
save `tempstart'
* Numbe of different choice sets asked


forval cs = 1/$NO_MPL {
	use `tempstart', clear
	
	di "** CHOICE SET `cs' **"
	
	
	* roman numbers for up to 9 MPLS (starting at II
	
	if `cs' == 1 {
		gen rn = "II"
	}
	if `cs' == 2 {
		gen rn = "III"
	}	
	if `cs' == 3 {
		gen rn = "IV"
	}
	if `cs' == 4 {
		gen rn = "V"
	}
	if `cs' == 5 {
		gen rn = "VI"
	}	
	if `cs' == 6 {
		gen rn = "VII"
	}	
	
	
	
	
		*-------------------------------------------------------------------
		* HTML formatting for questions
		
		
		* header unicode value
		local h_val = 1  + `cs' - 1

		
		forval i = 1/5 {
			tempvar v`i'
		}

		gen `v1' = "<p><h1 style = "
		gen `v2' = "text-align: center;"
		gen `v3' = ">&nbsp;<span style="
		gen `v4' = "font-size: 300%;"
		gen `v5' = ">" + rn + " " + string(view_choice_no) + "</span></h1></p>"

		egen header = concat( `v1' `v2' `v3' `v4' `v5'  ), punct(`"""')


		gen header_val = "`rn'" + string(view_choice_no)

		forval i = 1/4 {
			tempvar  v`i'
		}

		gen `v1' = "<p><span style = "
		gen `v2' = "font-size:32px"
		gen `v3' = ">$Q_START "
		gen `v4' = " "

		egen start_q =  concat( `v1' `v2' `v3'), punct(`"""')

		gen or = " $Q_OR "


		////
		* end of choice

		gen end = "? <br><br /> $Q_INSTR </span></p>"
		*******************************************************************
		

		gen lr = "1"

		gen mpl_order = `cs'

					
		* Create a wide "dataset" for each choice ------------------------- 
		
		* Start  group choice set (which choice set asked)
		gen c1 = "g_mpl" + string(mpl_no) + "_" + string(mpl_order) if view_choice_no == 1 & dir == "1"
		
		* Start group choice_order (order of binary questions)
		gen c2 = "g_mpl" + string(mpl_no) + "_" + "choice_order" + dir + "_" + string(mpl_order) if view_choice_no == 1 



		* Start group choice number (a group for each choice in a choice set)
		gen c3 = "g_mpl"  + string(mpl_no)  + "_" + "order" + dir + "_" + "choice" + string(choice_no) + "_" + string(mpl_order)


		* Questions as they appear to the respondent. 
		egen c4 = concat(header start_q q_o1 or q_o2 end)
		egen c5 = concat(header start_q q_o2 or q_o1 end)

		* Calculate - SurveyCTO assigns a value to options - These get the actual options
		gen c6 = "c_mpl" + string(mpl_no) + "_order" + dir + "_side1" + "_choice" + string(choice_no) + "_" + string(mpl_order)
		gen c7 = "c_mpl" + string(mpl_no) + "_order" + dir + "_sideN1" + "_choice" + string(choice_no) + "_" + string(mpl_order)
		
		* Once a choice is made, respondents confirm they have made their choice
		gen c8 = "n_" + string(mpl_order)

		* End group choice number
		gen c9 = c3

		* Enf group direction
		gen c10 = "g_choice_order" + dir + "_" + string(mpl_order) if view_choice_no == $NO_BINARY_CHOICES 

		* End group choice set asked
		gen c11 = "g_mpl" + string(mpl_no) + "_" + string(mpl_order) if view_choice_no == $NO_BINARY_CHOICES  & dir == "N1"
		
		gen c12 = ""


		* Drop unnecesary variables
		keep option1 option2 mpl_no choice_no  dir lr mpl_order c* header_val q_o1 q_o2 image1 image2 view_choice_no rn

		gen id = _n
		
		* Reshape 
		reshape long c, i(id)

		
		replace lr = "N1" if _j == 5 | _j == 7
		replace lr = "" if _j < 4 | _j > 7 

		


	tempfile temp_cs`cs'
	save `temp_cs`cs''

}

* Append all MPL asked to the respondent
use `temp_cs1'
forval i = 2/$NO_MPL {
	append using `temp_cs`i''
	
}
* Generate surveycto columns. NOTE underscores need to be replaced with spaces
* for variable names to be correct for surveyCTO

foreach var in $SCTOVARS {
	gen `var' = ""
}

* Add correct text to each column
* label - the questions as a respondent will see them
replace label = c 	 if inlist(_j, 4, 5)

* name - name of the variable
replace name = c if inlist(_j, 1, 2, 3, 6, 7, 9, 10, 11)

replace name = "mpl" + string(mpl_no) + "_order" + dir + "_" + "side1_choice" + string(choice_no) + "_" + string(mpl_order) if _j == 4
replace name = "mpl" + string(mpl_no) + "_order" + dir + "_" + "sideN1_choice" + string(choice_no) + "_" + string(mpl_order) if _j == 5

replace name = "next" + string(mpl_no) + "_order" + dir + "_" + string(choice_no) + "_" + string(mpl_order)  if _j == 8

* label for "next" - the confirmation that respondent has made a choice
forval i = 1/5 {
	tempvar tv`i'
}
gen `tv1' = "<font size = "
gen `tv2' = "5"
gen `tv3' = ">$Q_NEXT</font>"

egen tlab = concat(`tv1' `tv2' `tv3'), punct(`"""')

replace label = tlab if _j == 8 
drop tlab



* type - type of variable in surveyCTO
replace type = "begin group" 					if inlist(_j, 1, 2, 3)
replace type = "end group" 						if inlist(_j, 9, 10, 11)
replace type = "select_one " + "next" 			if inlist(_j, 8)
replace type = "calculate"						if inlist(_j, 6, 7)

replace type = "select_one " + "mpl" + string(mpl_no) + "_" + "side1_" + string(choice_no) 	if inlist(_j, 4)
replace type = "select_one " + "mpl" + string(mpl_no) + "_" + "sideN1_" + string(choice_no) 		if inlist(_j, 5)

replace type = "" if name == ""


* appearance - how questions will appear
replace appearance = "field-list" if _j == 3
replace appearance = "compact-2" if _j == 4 | _j == 5
replace appearance = "quickcompact" if type == "select_one next"



* relevance - when questions should be shown

* Choice sets
if $NO_MPL > 1 {
	forval j = 1/$NO_MPL {
		forval i = 1/$NO_OPTIONS {

			replace relevance = "\${rand_mpl" + "_" + string(mpl_order) +  "} = " + string(mpl_no) if  _j == 1 & name != ""

		}
	}
}

* Direction
forval j = 1/$NO_MPL {
	replace relevance = "\${choice_order_rand" + "_" + string(mpl_order) +  "} = 1"  if   _j == 2 & dir == "1"
	replace relevance = "\${choice_order_rand" + "_" + string(mpl_order) +  "} = -1"  if  _j == 2 & dir == "N1"

	
}

* Side of screen
replace relevance = "\${screen_side_rand" + "_" + string(choice_no) + "_" + string(mpl_order) +  "} = 1" if _j == 4 
replace relevance = "\${screen_side_rand" + "_" + string(choice_no) + "_" + string(mpl_order) +  "} = -1" if _j == 5 
		
* calculation


gen labname = name[_n - 2] if _j == 6 | _j == 7
replace calculation = "choice-label(\${" + labname + "}, \${" + labname + "})" if _j == 6 | _j == 7


* required - respondents must give an answer before moving on	
replace required = "yes" if _j == 4 | _j == 5 | _j == 8

* required message: The message that will display if a respondent tries to move 
* to the next quesitons without making a choice
replace requiredmessage = "Please tap on the option you want. The option you choose will be outlined in orange" if inlist(_j, 4, 5)

* Drop empty variables
drop if inlist(_j, 10, 11, 1,2) & name == ""

tempfile questions
save `questions'

////////////////////////////////////////////////////////////////////////////////

*------------------------------------------------------------------------------
* 							3.3. Display results
*------------------------------------------------------------------------------
/*
After the choice sets, once choice is randomly selected to be paid out. 
The choice number is displayed in large text across the whole screen. Then
the option that was chosen in that choice is displayed. 
*/
keep if inlist(_j, 4 )
keep if mpl_no == 1 & dir == "1"
 
* rn view_choice_no choice_no mpl_no dir mpl_order choice_no _j

gen see_order = $NO_BINARY_CHOICES + 1 - choice_no
replace see_order = choice_no if dir == "1"

/*
foreach var in $SCTOVARS {
	cap gen `var' = ""
	
}
*/
replace name = "note_result_" +"mpl" + string(mpl_order) + string(choice_no) if _j == 4
replace type = "note" if _j == 4

forval i = 1/3 {
	tempvar v`i'
}

gen `v1' = "<h1>&nbsp;<span style="
gen `v2' = "font-size: 1400%;"
gen `v3' = ">" + rn + " " + string(choice_no) + "</span></h1>"
egen tl = concat( `v1' `v2' `v3'), punct(`"""')
replace label = tl if _j == 4


*replace relevance = "\${realized_mpl} = " + string(mpl_no) if _j == 1

replace relevance = "\${realized_choice} = " + string(view_choice_no) + " and " + "\${realized_mpl} = " + string(mpl_order) if _j == 4

qui count
local o = `r(N)' + 2

set obs `o'
gen n = _n + 1
bys name : replace n = _n if _n == 1 & name == ""

replace n = _N if  name == "" & n != 1

sort n

forval i = 1/7 {
	tempvar v`i'
}

gen `v1' = "<font size = "
gen `v2' = "6"
gen `v3' = ">Now the tablet will randomly choose one of your choices. This will determine what you will get.</font>"

egen start = concat( `v1' `v2' `v3' ), punct(`"""')
replace label = start in 1
drop start
replace name = "note_showres" in 1
replace type = "note" in 1

replace name = subinstr(name, "g_", "g_disp_results_", .)

replace appearance = ""
replace requiredmessage = ""
replace required = ""

keep $SCTOVARS
order $SCTOVARS

tempfile result
save `result'

*******************************************************************************
* Display the option chosen for the choice that pays out

use `questions', clear
drop if inlist(_j, 3, 4, 5, 8, 9)


replace name = subinstr(name, "g_", "g_result_", .)

* Text that displays payout
forval i = 1/3 {
	tempvar v`i'
}


gen `v1' = "<p><span style = "
gen `v2' = "font-size:32px"
gen `v3' = ">The tablet chose " + rn + " " + string(view_choice_no) + " " + ///
	"which means you will get: " + "\${" + name + "}.</font>"
	
egen temp = concat( `v1' `v2' `v3') if _j == 6 | _j == 7, punct(`"""')
replace label = temp if _j == 6 | _j == 7
*drop temp

replace type = "note" if type == "calculate"
replace name = "note_" + name if type == "note"
replace calculation = ""

*drop if inlist(_j, 2, 10, 11, 12) & type == ""



* Relevance

gen see_order = $NO_BINARY_CHOICES + 1 - choice_no
replace see_order = choice_no if dir == "1"


gen realized_choice = .


forval x = 1/$NO_MPL {
	
	local y = (`x' - 1) * $NO_BINARY_CHOICES
	replace realized_choice = `y' + choice_no if dir == "1" 
	replace realized_choice = `y' + $NO_BINARY_CHOICES + 1 - choice_no if dir == "N1"
	
}


*replace relevance = "\${realized_mpl} = " + string(mpl_no) if _j == 1



replace relevance = "\${screen_side_rand_" + string(see_order) + "_" + string(mpl_order) +  ///
	"} = 1 and \${realized_choice} = " + string(see_order) + " and \${realized_mpl} = " + string(mpl_order) if _j == 6 


replace relevance = "\${screen_side_rand_" + string(see_order) + "_" + string(mpl_order) +  ///
	"} = -1 and \${realized_choice} = " + string(see_order) + " and \${realized_mpl} = " + string(mpl_order) if _j == 7 



tempfile display_payout
save `display_payout'


* Append all the survey form sections

use `calculate'
append using  `questions'
append using `result'
append using `display_payout'


keep $SCTOVARS
order $SCTOVARS


* first copy the surveycto form to the output path. 
* Survey form needs to be modified with existing formattting
cap erase "${outputpath}/${SCTO_FORM}"

copy "${inputpath}/${SCTO_FORM}" "${outputpath}/${SCTO_FORM}"

export excel "${outputpath}/${SCTO_FORM}", sheetmodify sheet("survey") cell(A20)
********************************************************************************
********************************************************************************

********************************************************************************
********************************************************************************

*				SECTION 4: Choices Sheet

********************************************************************************
********************************************************************************



* The choices sheet contains the options in each choice 


use `questions', clear

keep if _j == 4 | _j == 5
keep if dir == "1" & mpl_order == 1

sort mpl_no _j choice_no

gen label1 = q_o1 if lr == "1"
gen label2 = q_o2 if lr == "1"

replace label2 = q_o1 if lr == "N1"
replace label1 = q_o2 if lr == "N1"


* gen value varibles = to the MPL number
gen v1 = ""
gen v2 = ""

replace v1 = option1 if lr == "1"
replace v2 = option2 if lr == "1"

replace v2 = option1 if lr == "N1"
replace v1 = option2 if lr == "N1"

* add images

rename image1 imageA
rename image2 imageB 

gen image1 = ""
gen image2 = ""


replace image1 = imageA if lr == "1"
replace image2 = imageB if lr == "1"

replace image2 = imageA if lr == "N1"
replace image1 = imageB if lr == "N1" 



gen list_name = subinstr(type, "select_one ", "", .)

keep list_name label1 label2 v1 v2 image1 image2 _j

gen id = _n

reshape long label v image, i(id) j(_j2)

rename v value
order list_name value label image

keep list_name value label image

preserve
	drop if _n > 1
	
	replace list_name = "next"
	replace value = "1"
	replace label = "Next"
	replace image = ""
	
	tempfile next
	save `next'
restore

append using `next'


export excel "${outputpath}/${SCTO_FORM}", sheetmodify sheet("choices") cell(A4)

clear all 
macro drop _all




