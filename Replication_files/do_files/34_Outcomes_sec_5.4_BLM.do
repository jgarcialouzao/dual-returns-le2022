
clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f

*load data
use "${path}/dta_files/final_sample_males.dta", clear
append using "${path}/dta_files/final_sample_females.dta"

*Select years
keep if year>1996

*Keep employed workers
keep if E==1

*Dep variable
gen lnw = log(firm_yinc / firm_ydays)

*generate clusters
bys firm_cc1 year: gen nobs = _N
preserve
tempfile nobs
bys firm_cc2 year: keep if _n == 1
keep firm_cc2 year nobs
save `nobs'
restore
gen flag = 1 if nobs<10
bys firm_cc1 (flag): replace flag=flag[1] if flag==.
drop if flag==1

keep firm_* pid lnw parttime year age parttime educ

qui reghdfe lnw , absorb(year age parttime educ) res keepsing
rename _reg lnw_res 


*Create within firm average log-wage
bys firm_cc1: egen avg_firm_lnw=mean(lnw) 

*K-means clustering (based on https://journals.sagepub.com/doi/pdf/10.1177/1536867X1201200213)
foreach k of numlist 5 10 50 {
cluster kmeans avg_firm_lnw, k(`k') start(random(123)) name(cs`k')
}


rename cs5 firm_clus5
rename cs10 firm_clus10
rename cs50 firm_clus50
keep firm_cc2 firm_clus* 
bys firm_cc2: keep if _n == 1

*store clusters
save "${path}/dta_files/firmFE_BLM_MCVL.dta", replace


*load data
use "${path}/dta_files/estimation_sample.dta", clear

global fvars "sme young"
global xvars "ed2 ed3 female"
global jvars "sk2 sk3 parttime dummyT c.tenure##c.tenure"
global fevars "pexpgroup year sector provfirm_cc2"


*Keep employment observations
keep if E==1

*Dep variable
gen lnw = log(w)

*Potential experience
gen pexpgroup=pexp
recode pexpgroup(1/3=1) (4/6=2) (7/9=3) (10/12=4) (13/15=5)

*Merge with clusters
merge m:1 firm_cc2 year using `nobs', keep(1 3)
drop _m
merge m:1 firm_cc2 using "${path}/dta_files/firmFE_BLM_MCVL.dta" , keep(1 3)
rename _m blm


*Sectors
qui gen manuf = sector==2
label var manuf  "Manufcaturing"
qui gen construction = sector==3
label var construction "Construction"
qui gen services = sector>3

*Located in 4 largest metropolitan areas (Madrid, Barcelona, Sevilla, Valencia)
gen bigcity= 1 if provfirm_cc2==8 | provfirm_cc2==28 | provfirm_cc2==41 | provfirm_cc2==46
recode bigcity .=0
label var bigcity "Big city"


*Table A.11 -  Dual Returns to Experience: Firm-cluster fixed effects (BLM, 2022)

*Baseline Sample 
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex" , replace keep(aexp_oec aexp_ftc) ctitle((1)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*BLM Restricted Sample (2)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if blm==3, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex", append keep(aexp_oec aexp_ftc) ctitle((2)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*BLM Restricted Sample (3)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if blm==3, absorb($fevars pid firm_clus5) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex" , append keep(aexp_oec aexp_ftc) ctitle((3)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*BLM Restricted Sample (4)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if blm==3, absorb($fevars pid firm_clus10) keepsing cluster(pid)
outreg2 using "${path}//tables/reg_returns2exp_firmFE.tex" , append keep(aexp_oec aexp_ftc) ctitle((3)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*BLM Restricted Sample (5)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if blm==3, absorb($fevars pid firm_clus50) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex", append keep(aexp_oec aexp_ftc) ctitle((3)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)



