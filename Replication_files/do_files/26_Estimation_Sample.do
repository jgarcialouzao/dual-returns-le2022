clear all
capture log close
cap set more off
set matsize 8000
set maxvar 10000


use "${path}\dta_files\final_sample_males.dta", clear
gen female = 0
append using "${path}\dta_files\final_sample_females.dta"
replace female = 1 if female==.

keep if pygrad>=1996
drop if pexp>15

*If missing days under both contracts but days positive, remove workers
gen flag = 1 if total_ydays_oec+total_ydays_ftc!=total_ydays
bys pid (flag): replace flag = flag[1] if flag==.
drop if flag==1
drop flag

*Lagged actual experience
qui bys pid (year): gen aexp= (sum(total_ydays)-total_ydays)/360

qui bys pid (year): gen aexp_oec = (sum(total_ydays_oec)-total_ydays_oec)/360
qui bys pid (year): gen aexp_ftc = (sum(total_ydays_ftc)-total_ydays_ftc)/360
qui bys pid (year): gen nojob =  nojobs[_n-1]

*Transform (daily) tenure into years
replace tenure_days = tenure_days/360

*First observation, experience variables are zero
foreach v in aexp aexp_oec aexp_ftc nojobs {
qui replace `v' = 0 if `v'==.	
	
}

*Outcome variables
gen w = firm_yinc / firm_ydays
gen w_orig = firm_yinc_orig/firm_ydays 
gen w_tax = firm_yinc_tax/firm_ydays 
replace w_tax = . if year<2005
gen w_total = total_yinc/total_ydays 
gen days = total_ydays
gen days_oec = total_ydays_oec
gen days_ftc = total_ydays_ftc

drop total_*

*Dummy for HH composition
qui gen convive_06=(tamanno_06>0)
qui gen convive_715=(tamanno_715>0)
qui gen convive_m65=(tamanno_m65>0)


*Firm size and age dummies
gen sme = fsize<50

gen young = fage<3

*educ andskill dummies
qui tab educ,gen(ed)
qui tab skill,gen(sk)

global fvars "sme young"
global xvars "ed2 ed3 convive_06 convive_715 convive_m65"
global jvars "sk2 sk3 parttime dummyT* missingcontract"
global FEvars "sector prov* year tenure*"

qui keep  firm_cc2 pid female time yearbirth pygrad E w* pexp aexp* days* nojobs baja* alta $jvars $xvars $fvars $FEvars
qui compress

save "${path}\dta_files\estimation_sample.dta", replace


