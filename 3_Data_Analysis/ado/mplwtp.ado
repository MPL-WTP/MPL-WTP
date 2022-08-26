/*******************************************************************************
File:			mplwtp.ado

Version			v1.0

Description:	This program file carries out willingness to pay estimation from 
		multiple price list data. 
				
		For a detailed description of how to use this command, please
		see: https://github.com/MPL-WTP/MPL-WTP 

Inputs:			mplwtp_xtset.ado

Authors:		Kelsey Jack, Kathryn McDermott, Anja Sautmann,
			Kenneth Chan, Lei Yue


*******************************************************************************/


capture program drop mplwtp

/////////////////////////////////////////////////////////
program define mplwtp, eclass
/////////////////////////////////////////////////////////
	version 14.2 

	syntax varlist(min=3) [if] [in] [, bootstrap(string) vce(string) intp(real 12) sim(real 100) checkintp(string) pause(string) rawoutput(string)] panelvar(varname)

		* varlist inputs (required)
		// depvar:        outcome: dummy for choosing option 1
		// scalevar:      difference in value: (option1 - option2) (fixed for given MPL choice (same choice ID))	
		// indepvarlist:  includes a dummy or dummies for each population group or set of MPL for which the WTP should be estimated (at least one required; can be constant 1); and any covariates, including order bias variables 
	    
		* required:
		// panelvar:      used to xtset the panel variable (required): binary choice ID within the MPL
		
		* bootstrap:      
		// input: 	      yes, or no (default, delta method used to calculate scaled estimates)

		
		* rawoutput:      whether to show the raw (unscaled) output of xtprobit
		// input: 	      yes, or no (default, only scaled estimates will be shown)
		
		* other input:		
		// sim: 	      number of bootstrap replications (default is 100)
			    
		// intp:          intpoints - number of quadrature points (default set at 12, same as xtprobit default)
		
		// checkintp:     whether to use quadchk command to check the number of quadrature points
		//				  yes, or no (default)
		
		// pause:         pause(on) -- pauses execution after checking the quadrature points before continuing
		//			      can be used only with checkintp(yes)
		
		// vce:           choice of standard error for xtprobit command
		//				vce(cluster `panelvar') recommended

	    * [if]: sampling conditions

/////////////////////////////////////////////////////////
		
	xtset, clear
	capture drop depvar scalevar panelvar
	
//////////////////
* Input variables
//////////////////

qui{
	
// generate variables with the required names:	
	
	local varlist_count = wordcount("`varlist'")
	
	** error message for less than three input variables
	if `varlist_count' < 3{
		exit 102
	}
	
	
	scalar j = 0 // input order of `varlist'
	
	// locate depvar, scalevar, indepvars:
	
	foreach var in `varlist'{
		
		scalar j = j+1
		
		if j == 1 {
			gen depvar = `var'      	    // type of depvar: variable
			local depvar `var'
		}
		if j ==2 {
			gen scalevar = `var' 		    // type of scalevar: variable
			local scalevar "`var'"
		}
		if j == 3 {
			local indepvarlist "`var'" 		// type of `indepvarlist': local varlist
		}
		if j > 3 {
			local indepvarlist "`indepvarlist' `var'"
		}
	}
	
	 
   // locate panelvar:
	gen panelvar = `panelvar'
		
   // use bootstrap or not:	
	if "`bootstrap'" == "" local bootstrap "no"
	
	if "`bootstrap'" != "yes" & "`bootstrap'" != "no"{
		di as error "bootstrap option can only be yes or no (default)"
		exit 198
	} 

   // quadchk or not
	if "`checkintp'" == "" local checkintp "no"
	
	if "`checkintp'" != "yes" & "`checkintp'" != "no"{
		di as error "checkintp option can only be yes or no (default)"
		exit 198
	} 
	
   // pause or not
	if "`pause'" == "" local pause ""
	
	if "`pause'" != "" & "`checkintp'" == "no"{
		di as error "pause option can be turned on only when checkintp option is yes"
		exit 198
	}
	
	if "`pause'" != "on" & "`pause'" != "" {
		di as error "pause option can only be empty or on"
		exit 198
	}
	
	
   // show raw output or not
	if "`rawoutput'" == "" local rawoutput "no"
	
	if "`rawoutput'" != "yes" & "`rawoutput'" != "no"{
		di as error "rawoutput option can only be yes or no (default)"
		exit 198
	} 
	
   // others:
	local boots=`sim'
	
	if "`checkintp'" == "yes"{
		pause `pause'
	
   // check integration points
		qui xtset panelvar
		qui xtprobit `depvar' `scalevar' `indepvarlist' `if' `in' , re nocons vce(`vce') intp(`intp')

		quadchk, nooutput

		di _newline "It is recommended for the magnitude of the relative difference to be smaller than 0.0001 to confidently interpret the coefficients."
		di _newline "Increase the integration points if the relative difference is too large." 
		di as text _newline
		pause type q to continue or BREAK (in caps) to terminate the command now	
	}

	
//////////////////
* xtprobit
//////////////////


	xtset panelvar
  
	if "`rawoutput'" == "no"{
		xtprobit `depvar' `scalevar' `indepvarlist' `if' `in', re nocons vce(`vce') intp(`intp') 
	}
  
	if "`rawoutput'" == "yes"{
		pause on
		noisily di " "
		noisily di " "
		noisily di "{bf:Results from xtprobit:}"
		noisily di " "
		noisily xtprobit `depvar' `scalevar' `indepvarlist' `if' `in', re nocons vce(`vce') intp(`intp') 
		pause type q to continue or BREAK (in caps) to terminate the command now
		noisily di as text "{hline 100}"
  }
	
	scalar N = e(N)
	scalar N_g = e(N_g)


//////////////////
* SE by delta (default)
//////////////////		
	
	if "`bootstrap'" == "no"{
		
	   // sigma_eps (point estimate: scaled standard deviation of the error)
		matrix sigma_eps = 1/_b[`scalevar'] 
	
	   // sigma_u (point estimate: scaled SD of the random effect)
		matrix sigma_u = e(sigma_u)/_b[`scalevar']  
		
	   // write scaled coefficients as input for nlcom command  
			foreach indep of varlist `indepvarlist'{
				local nlcom_eq "(`indep': _b[`indep']/_b[`scalevar'])"
				local nlcom_indepvarlist "`nlcom_indepvarlist' `nlcom_eq'"
			}
		
		noisily di " "
		noisily di " "
		noisily di "{bf:Results from mplwtp:}"
	    noisily di " "
		
		nlcom `nlcom_indepvarlist', post
		noisily nlcom
		
	   // stored b in matrix: scaled point estimates
		matrix temp_b = e(b) 
		
	   // stored V in matrix
		matrix temp_V = e(V) 			

	}



//////////////////
* SE by Bootstrap
//////////////////	
	

	if "`bootstrap'" == "yes"{

		local bs_indepvarlist = ""
	
		foreach indep of varlist `indepvarlist'{
			local bs_eq "`indep' = r(`indep')"
			local bs_indepvarlist "`bs_indepvarlist' `bs_eq'"
		}	
	
		global indepvarlist_bs `indepvarlist'
		global if_bs `if'
		global in_bs `in'
		global vce_bs `vce' 
		global intp_bs `intp'
	    
		noisily di " "
		noisily di " "
		noisily di "{bf:Results from mplwtp:}"
	    noisily di " "
		
		noisily bootstrap `bs_indepvarlist' sigma_eps = r(sigma_eps) sigma_u = r(sigma_u), cluster(`panelvar') idcluster(newid) reps(`sim'): mplwtp_xtset
	
		matrix temp_b = 0
		
		foreach indep of varlist `indepvarlist'{
			matrix temp_b = temp_b, _b[`indep']
		}
		matrix temp_b = temp_b[1...,2...]
		matrix rownames temp_b = b
		matrix colnames temp_b = `indepvarlist'
					
		matrix temp_V = e(V)
	
		// sigma_u
		matrix sigma_u = _b[sigma_u]
				
		// sigma_eps
		matrix sigma_eps = _b[sigma_eps]	
	}


//////////////////
* Store in ereturn
//////////////////	
        
	ereturn clear
	
		if "`bootstrap'" == "no"{	
			
			* V
			matrix V = temp_V
			
			* se method
			estadd local se_method "Delta Method"

		}
		
		if "`bootstrap'" == "yes"{		
			
			* V
			matrix V = J(`varlist_count'-2, `varlist_count'-2, 0) 
			matrix rownames V = `indepvarlist'
			matrix colnames V = `indepvarlist'
		
			foreach indep1 of varlist `indepvarlist'{
				foreach indep2 of varlist `indepvarlist'{
				    matrix V[rownumb(V,"`indep1'"),colnumb(V,"`indep2'")] = temp_V["`indep1'", "`indep2'"]
				}
			}

			* se method
			estadd local se_method "Bootstrap"
			
			* num of simulation
			estadd scalar N_sim `sim'
			
		}
		
	// same storing commands for both methods:
		
	matrix b = temp_b
		
	ereturn post b V

	* title
	estadd local title "Scaled random effects probit estimates" 
		
	* sigma_eps, sigma_u
	estadd scalar sigma_eps = sigma_eps[1,1]
	estadd scalar sigma_u = sigma_u[1,1]

	
	* others
	estadd scalar N = N
	estadd scalar N_g = N_g
	estadd local depvar `depvar'
	estadd local ivar `panelvar'
	estadd local model "re"
	estadd local vce `vce'
	
	
		

///////////////////

drop panelvar depvar scalevar 

}

//////////////////
* Display
//////////////////	

	di "SD of individual error (sigma_eps):" _col(40) " " %8.4f  e(sigma_eps)
	di "SD of RE (sigma_u):" _col(40)  " " %8.4f e(sigma_u)
	di "N:" _col(41)  " " e(N)
	di " "

xtset, clear

ereturn local cmd "mplwtp"	

qui eststo


end
















