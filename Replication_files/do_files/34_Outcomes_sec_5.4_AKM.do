clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f

*Load data
use "${path}/dta_files/final_sample_males.dta", clear
append using "${path}/dta_files/final_sample_females.dta"

*Select years
keep if year>1996

*Keep employees
keep if E==1

*Dep variable
gen lnw = log(firm_yinc / firm_ydays)

*Generate firm FE
keep firm_* pid year age lnw parttime dummyT
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

reghdfe lnw parttime, absorb(firmfe = firm_cc1  workerfe = pid  year age) keepsing
keep firm_cc2 firmfe workerfe 
bys firm_cc2: keep if _n == 1

*Store firm FE
save "${path}/dta_files/firmFE_MCVL.dta", replace



*Load final data
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

*Merge with firm FE
merge m:1 firm_cc2 year using `nobs', keep(1 3)
drop _m
merge m:1 firm_cc2 using "${path}/dta_files/firmFE_MCVL.dta" , keep(1 3)


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

gen match = _m==3

* Table A.10 - Worker Observed in the Matched Sample
reg match aexp ed3 female sk3 parttime dummyT tenure manuf construction services bigcity, cluster(pid)
outreg2 using "${path}/tables/reg_match.tex" , replace  tex(frag) nocons dec(4)  nonotes label


* Table 2 -  Dual Returns to Experience: Firm Heterogeneity
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex" , replace keep(aexp_oec aexp_ftc) ctitle((1)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if _merge==3, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}//tables/reg_returns2exp_firmFE.tex" , append keep(aexp_oec aexp_ftc) ctitle((2)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

reghdfe lnw aexp_oec aexp_ftc $jvars $fvars firmfe if _merge==3, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_firmFE.tex" , append keep(aexp_oec aexp_ftc) ctitle((3)) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)



