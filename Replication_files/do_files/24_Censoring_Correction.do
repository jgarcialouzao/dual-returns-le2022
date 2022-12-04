*Stata 14
*The scarring effects of job instability
*Hospido, Garcia-Louzao, Ruggieri
*Censoring correction

clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13

***********************CORRECTION STRATEGY: a la Card Heining Kline (2013)
foreach g in males females {
 foreach c in bboomers genx millennials {
use ${path}\dta\asample_`c'_`g'.dta, clear
qui keep if E==1
qui keep pid firm_cc2 time year month E age skill dailyw topados group parttime sector provfirm_cc2 fage
*Remove pre 1980 observations, no income information
qui drop if year<1980

qui gen logdailywages = log(dailyw)
	
** For each individual construct individual specific components for the Tobit regressions - following Card, Heining and Kline (2013	
*Generate average individual wage in other periods except the censored	
qui bys pid: gen nobs = _N
qui	gen oneobs = 1 if nobs==1
qui	recode oneobs .=0
qui bys pid: gegen meanw=mean(logdailywages)	
qui gen meanw_noT=(meanw - logdailywages/nobs)*nobs/(nobs-1)
qui gegen meanpop=mean(logdailywages)	
qui	replace meanw_noT=meanpop if oneobs==1
qui	drop meanpop
	
*Generate fraction of other month-year that the individual's wage is max censored
qui bys pid: gegen meantop=mean(topados)
qui gen meantop_noT=(meantop - topados/nobs)*nobs/(nobs-1)
qui gegen meanpop=mean(topados)
qui	replace meantop_noT = meanpop if oneobs==1
qui	drop meanpop

qui compress
qui gen agei=1 if age<25
qui replace agei=2 if age>=25&age<35
qui replace agei=3 if age>=35&age<45
qui replace agei=4 if age>=45&age<55
qui replace agei=5 if age>=55

qui gen agroup=1 if skill==3
qui replace agroup=2 if skill==2
qui replace agroup=3 if skill==1

tempfile cohort`c'data
save `cohort`c'data', replace
}
*Append cohorts
use `cohortbboomersdata', clear
append using `cohortgenxdata'
append using `cohortmillennialsdata'

keep pid year month agroup top logdailywages group agei age oneobs meanw_noT meantop_noT parttime provfirm_cc2 sector fage
qui gen cens=1 if top==1
qui replace cens=0 if cens==.

*** Define cell**
qui egen cell = group(agei agroup year)

qui xi i.sector
qui rename _I* *
qui drop sector
qui xi i.fage
qui rename _I* *
qui drop fage
qui rename provfirm_cc2 provfirm
qui xi i.provfirm
qui rename _I* *
drop provfirm
qui xi i.month
qui rename _I* *
qui gen mu=.
qui gen sigma=.
qui compress
qui bys cell: censoredtobit_CHK // ado file to implement cell-by-cell tobit model

qui compress
save ${path}\dta_files\CensTobit`g'_CHK, replace

use  ${path}\dta_files\CensTobit`g'_CHK, clear
*Simulate wages
qui keep if cens==1 
keep pid year month logdailywages mu sigma group cens
qui compress
merge m:1 year month group using ${path}\dta_files\realbounds.dta
keep if _merge==3
drop _merge min_base
qui compress
	
qui gen k = ( log(max_base/30) - mu )/sigma
qui gen k_norm = normal(k)
qui gen u = runiform()
	
qui gen     e = invnormal( k_norm + u*(1 - k_norm) ) if k_norm<.9999
*few observations have k_norm==1 => e_max  is non-defined, i.e. missing value generated
*assing 3.71902. Value of invnormal(.9999) following Card et al. (2013)
qui replace e = 3.71902  if  k_norm>=.9999 & k_norm!=.

qui g logdailywagespred_CHK=mu+(sigma*e) 
drop if logdailywagespred==.
qui keep pid year month logdailywagespred_CHK cens
qui compress
save ${path}\dta_files\simwages_CHK_`g'.dta, replace

}

