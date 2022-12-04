*Stata 14
*The scarring effects of job instability
*Hospido, Garcia-Louzao, Ruggieri
*Estimation sample (worker-year)

clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13

foreach g in males females {
foreach cohort in bboomers genx millennials {
use ${path}\dta_files\asample_`cohort'_`g'.dta, clear
merge 1:1 pid year month using ${path}\dta_files\simwages_CHK_`g', keepusing(logdailywagespred_CHK cens) keep(1 3)
qui gen dailywpred=exp(logdailywagespred_CHK)
qui replace dailywpred = dailyw if dailywpred==.
qui drop logdailywages* _m
qui gen total_incpred = total_inc - dailyw*days + dailywpred*days 
qui replace total_incpred = 0 if total_incpred==.

qui bys pid firm_cc2 year: egen firm_yinc = total(dailywpred*days) 

qui bys pid firm_cc2 year: egen firm_yinc_orig = total(dailyw*days) 
qui bys pid firm_cc2 year: egen firm_yinc_tax = total(wage) 
qui bys pid firm_cc2 year: egen firm_ydays = total(days) 

qui bys pid year: egen total_yinc = total(total_incpred)
qui bys pid year: egen total_ydays = total(daysworked)
qui bys pid year: egen total_ydays_oec = total(daysworked_oec) 
qui bys pid year: egen total_ydays_ftc = total(daysworked_ftc) 

qui bys pid firm_cc2 alta (time): gen job = _n == 1
qui bys pid (time): gen tmp = sum(job)
qui bys pid year: gen nojobs = tmp[_N]
drop job tmp

*Each year select observation with main employer
*Criteria: higher total earnings and last obs in the year
qui bys pid year: egen year_inc_max = max(firm_yinc)
qui keep if firm_yinc == year_inc_max
qui bys pid year (time): keep if _n == _N
qui drop year_inc_max

*Employment and mobility: earnings of at least one quarter of full-time work at half the minimum wage
qui drop E
qui gen E= (firm_yinc>3*NMW/2 & firm_yinc<.) & year>=1980
qui replace E = 0 if firm_yinc==0
qui replace E=1 if firm_ydays>90 & year<1980
qui replace E=0 if firm_ydays<=90 & year<1980
qui label var E "Emplyoment status"

*Experience variables
qui gen pexp = year - pygrad
qui label var pexp "Potential experience"

*adjust dummy of temporary contracts
gen dummyT_orig = dummyT
bys pid (year): replace dummyT = 0 if dummyT==1 & dummyT[_n-1]==0 & firm_cc2==firm_cc2[_n-1] 
qui gen missingcontract = dummyT==.
qui replace dummyT=. if E==0

*Tenure
qui bys pid (year): gen tenure = 1 if (firm_cc2!=firm_cc2[_n-1] | E[_n-1]==0)
qui bys pid (year): replace tenure  = tenure[_n-1] + 1 if firm_cc2==firm_cc2[_n-1] & E==E[_n-1]
qui replace tenure =. if firm_cc2==""
qui label var tenure  "Tenure"


qui bys pid (year): gen tenure_days = firm_ydays if (firm_cc2!=firm_cc2[_n-1] | E[_n-1]==0)
qui bys pid (year): replace tenure_days = tenure_days[_n-1] + firm_ydays if firm_cc2==firm_cc2[_n-1] & E==E[_n-1]
qui replace tenure_days=. if firm_cc2==""
qui label var tenure_days "Tenure"

*adjust skill
qui replace skill = 1 if  group >= 8 & group <= 11 &E==1
qui replace skill = 2 if (group == 4 | group == 5 | group == 6 | group ==7)  &E==1
qui replace skill = 3 if (group == 1 | group == 2 | group == 3)  &E==1

*Before 1980 no earnings, discard
qui drop if year<1980

*Drop monthly level variables/no needed
qui drop dailywpred total_incpred days daysworked daysworked_oec daysworked_ftc total_incpred total_inc total_wage episodesmonth min_base max_base topados wage inc missingw country provinceaf nationality faddress2 month

qui gen `cohort' = 1
tempfile `cohort'
save ``cohort'', replace
}

*Extract time effects
use `bboomers'
qui append using `genx'
qui append using `millennials'

qui replace genx = 0 if genx==.
qui replace mill = 0 if millennials==.

qui compress

save ${path}/dta_files/final_sample_`g'.dta, replace

}

