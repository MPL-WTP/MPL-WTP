# MPL-WTP
This repository accompanies *Jack, McDermott, Sautmann* (Forthcoming) and contains user-written Stata commands for estimating willingness to pay (WTP) using a multiple price list (MPL) choice experiment as well as templates for collecting survey data using SurveyCTO and preparing the data for analysis. We also provide example input and output to recreate an MPL between cash and prepaid electricity described in *Jack, McDermott, Sautmann* (Forthcoming).  

For a full description of the contents of this repository please see the technical appendix of *Jack, McDermott, Sautmann* (Forthcoming).  

## Contributors
Kelsey Jack, Kathryn McDermott, Anja Sautmann, Kenneth Chan, Lei Yue

## Recommended citation
Jack, B.K, McDermott, K., Sautmann, A., Chen, K., Yue, L. (2022). Data Collection and Analysis of Multiple Price Lists for Willingness to Pay Elicitation. https://github.com/MPL-WTP/MPL-WTP 


## Contents

### 1_Data_Collection
**Code**  
* [*JMS_create_surveycto_form.do*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Code#:~:text=JMS_create_surveycto_form.do) Stata do file that produces a SurveyCTO survey form for implementing an MPL  
* [*JMS_mpl_randomization.do*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Code#:~:text=JMS_mpl_randomization.do) Stata do file that randomizes the elements of one or more MPL. 
  
**Example**  
- **Input**
  - [*JMS_example_mpl_input.csv*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Example/Input#:~:text=JMS_example_mpl_input.csv) Template csv file used for defining the available MPL options  
  - [*JMS_example_sampledata.csv*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Example/Input#:~:text=JMS_example_sampledata.csv) Example of a pre-existing dataset for sample stratification  
  - [*JMS_example_surveyCTO_form.xlsx*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Example/Input#:~:text=JMS_example_surveyCTO_form.xlsx) Template blank SurveyCTO survey form  


- **Output**
  - [*JMS_example_surveyCTO_form.xlsx*}(https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Example/Output#:~:text=JMS_example_surveyCTO_form.xlsx) Example SurveyCTO form with appended contents using JMS_create_surveycto_form.do (Note that the input and output file have the same name). 
  - [*JMS_example_sampledata_rand.csv*](https://github.com/MPL-WTP/MPL-WTP/tree/main/1_Data_Collection/Example/Output#:~:text=JMS_example_sampledata_rand.csv) Example file containing randomization assignments for sample created using *JMS_mpl_randomization.do* (Note: this file is an output of the randomization do file, but an input for the SurveyCTO form creation do file)


### 2_Data_Processing
**Code**
  - [*JMS_clean_SurveyCTO_for_MPL.do*](https://github.com/MPL-WTP/MPL-WTP/tree/main/2_Data_Processing/Code#:~:text=JMS_clean_SurveyCTO_for_MPL.do) Stata do file that prepares survey data for analysis  
  
**Example**  
- **Input**
  - [*JMS_example_surveydata.dta*](https://github.com/MPL-WTP/MPL-WTP/tree/main/2_Data_Processing/Example/Input#:~:text=JMS_example_surveydata.dta) Example of survey data collected using JMS_example_surveyCTO_form.xlsx
  - [*JMS_example_mpl_input.csv*](https://github.com/MPL-WTP/MPL-WTP/tree/main/2_Data_Processing/Example/Input#:~:text=JMS_example_mpl_input.csv) Template csv file used for defining the available MPL options (note: this is the same file as above)


- **Output**  
  - [*JMS_example_processed_mpl.dta*](https://github.com/MPL-WTP/MPL-WTP/tree/main/2_Data_Processing/Example/Output#:~:text=JMS_example_processed_mpl.dta)  Survey data that is prepared using JMS_clean_SurveyCTO_for_MPL.do for analysis with *mplwtp.ado*


### 3_Data_Analysis
- **ado**
  - [*mplwtp.ado*](https://github.com/MPL-WTP/MPL-WTP/tree/main/3_Data_Analysis/ado#:~:text=.%E2%80%8A.-,mplwtp.ado,-Add%20data%20analysis) Stata ado file to define the mplwtp program
  - [*mplwtp_xtset.ado*](https://github.com/MPL-WTP/MPL-WTP/tree/main/3_Data_Analysis/ado#:~:text=1%20hour%20ago-,mplwtp_xtset.ado,-Add%20data%20analysis) Stata ado file to implement bootstrapping for mplwtp.ado


## Report a bug
The best way to report a bug is to log an issue on Github. Please include the following:
- The file name(s) where an error was found
- File version number
- Detailed steps on how to recreate the bug
