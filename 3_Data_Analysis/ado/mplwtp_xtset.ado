/*******************************************************************************
File:			mplwtp_xtset.ado

Version			v1.0

Description:	This program file carries out the bootstrap draws for the 
		mplwtp.ado program. 
				
		For a detailed description of how to use this command, please
		see: https://github.com/MPL-WTP/MPL-WTP 

Authors:		Kelsey Jack, Kathryn McDermott, Anja Sautmann,
			Kenneth Chan, Lei Yue


*******************************************************************************/


capture program drop mplwtp_xtset

/////////////////////////////////////////////////////////
program define mplwtp_xtset, rclass 
/////////////////////////////////////////////////////////

	xtset newid 
	qui xtprobit depvar scalevar $indepvarlist_bs $if_bs $in_bs , re nocons vce($vce_bs) intp($intp_bs)
	
	foreach indep of varlist $indepvarlist_bs{
		return scalar `indep' = _b[`indep']/_b[scalevar]
	}
	
	* sigma_eps
	return scalar sigma_eps = 1/_b[scalevar]
	
	* sigma_u
	return scalar sigma_u = e(sigma_u)/_b[scalevar]
		
	exit

	ereturn local cmd "mplwtp_xtset"	
end


