*** Stata 16
*** Master file to replicate "Dual Returns to Experience" by Jose Garcia-Louzao, Laura Hospido, and Alessandro Ruggieri
*** December 2022


clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f

** Set main directory
global path "{Replication_files}" // main directory here but recall one needs to have the sub-folders within the diretory, i.e., do_files, dta_files, cohorts_2018, tables, figures
cd ${path}

** Installation of external programs required for estimation or saving results

* ftools (remove program if it existed previously)
ssc install ftools, replace
ssc install gtools, all replace

* reghdfe 
ssc install reghdfe, replace

* ivreghdfe 
ssc install ivreg2, replace // the core package ivreg2 is required
ssc install ivreghdfe, replace

* outreg 
ssc install outreg2, replace


** Routines to obtain the final results 
*  routines should be stored in ${path}\do_files\

* 1) Data extraction 

do ${path}\do_files\11_ReadMCVL2018.do //requires PastInfo2018.do to be in the do_files folder
do ${path}\do_files\12_MergeMCVL2018_olderversion.do 
do ${path}\do_files\12_MergeMCVL2018_newversion.do 
do ${path}\do_files\13_MonthlyVars2018.do
do ${path}\do_files\14_ReshapeData2018.do
do ${path}\do_files\15_OtherVars2018.do
do ${path}\do_files\16_DatosFiscales${v}.do
do ${path}\do_files\17

* 2) Panel creation

do ${path}\do_files\21.Monthly_Panel_Males.do
do ${path}\do_files\22.Monthly_Panel_Females.do
do ${path}\do_files\23.Starting_Sample.do
do ${path}\do_files\24.Censoring_Correction.do // requires censoredtobit_CHK.ado to be in the do_files folder
do ${path}\do_files\25.Final_Sample.do 
do ${path}\do_files\26.Estimation_Sample.do


* 3) Results 

do ${path}\do_files\31_Outcomes_sec_4.do
do ${path}\do_files\31_Outcomes_sec_5.2.do
do ${path}\do_files\31_Outcomes_sec_5.3.do
do ${path}\do_files\31_Outcomes_sec_5.4_AKM.do
do ${path}\do_files\31_Outcomes_sec_5.4_BLM.do
do ${path}\do_files\31_Outcomes_sec_5.4_MatchQuality.do // requires provtoreg.do to be in the do_files folder
do ${path}\do_files\31_Outcomes_sec_6.1.do
do ${path}\do_files\31_Outcomes_sec_6.2.do
