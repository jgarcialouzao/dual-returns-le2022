
clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f


global fvars "sme young"
global xvars "ed2 ed3 female"
global jvars "sk2 sk3 parttime dummyT c.tenure##c.tenure"
global fevars "pexpgroup year sector provfirm_cc2"



*load data
use "${path}/dta_files/estimation_sample.dta", clear

*Merge with IV: subsidies
rename province province_tmp
rename provfirm_cc2 province
qui do "${path}/do_files/provtoreg.do"
sort region year female
rename year year_tmp
gen year = year_tmp-1
merge m:1 region year female using "${path}/dta_files/subsidies.dta", keep(1 3)
gen subsidies=(_merge==3)
drop _merge
drop year
rename year_tmp year
rename province provfirm_cc2
rename province_tmp province



*Keep employment observations
keep if E==1

*Dep variable
gen lnw = log(w)

*Potential experience
gen pexpgroup=pexp
recode pexpgroup(1/3=1) (4/6=2) (7/9=3) (10/12=4) (13/15=5)

*Tenure
gen tenure_sq=tenure^2



*Within-firm/contract average of experience
bys pid firm_cc2 : egen avg_aexp=mean(aexp)
bys pid  dummyT: egen avg_aexp_oec2=mean(aexp_oec)
bys pid  dummyT: egen avg_aexp_ftc2=mean(aexp_ftc)
bys pid firm_cc2 dummyT: egen avg_aexp_oec=mean(aexp_oec)
bys pid firm_cc2 dummyT: egen avg_aexp_ftc=mean(aexp_ftc)
bys pid firm_cc2 : egen avg_tenure=mean(tenure)
bys pid firm_cc2 : egen avg_tenure_sq=mean(tenure^2)

*De-meaned experience
bys pid firm_cc2 : gen dev_aexp=aexp-avg_aexp
bys pid dummyT: gen dev_aexp_oec2=aexp_oec-avg_aexp_oec2
bys pid dummyT: gen dev_aexp_ftc2=aexp_ftc-avg_aexp_ftc2
bys pid firm_cc2 dummyT: gen dev_aexp_oec=aexp_oec-avg_aexp_oec
bys pid firm_cc2 dummyT: gen dev_aexp_ftc=aexp_ftc-avg_aexp_ftc
bys pid firm_cc2 : gen dev_tenure=tenure-avg_tenure
bys pid firm_cc2 : gen dev_tenure_sq=tenure^2-avg_tenure_sq


*TABLE 3 - Match Quality
** Altonji and Shakotko (demeaning experience at contract level)
set more off
xtivreg lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec2 dev_aexp_ftc2 dev_tenure dev_tenure_sq)   ///
i.ed2 i.ed3 i.female i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, /// 
fe vce(cluster pid)
outreg2 using "${path}/tables/reg_returns2exp_IV.tex" , replace keep(aexp_oec aexp_ftc) ctitle(IV) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


** Altonji and Shakotko (demeaning experience at contract-match level)
set more off
xtivreg lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec dev_aexp_ftc dev_tenure dev_tenure_sq)   ///
i.ed2 i.ed3 i.female i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, /// 
fe vce(cluster pid)
outreg2 using "${path}/tables/reg_returns2exp_IV.tex" , append keep(aexp_oec aexp_ftc) ctitle(IV) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

** Altonji and Shakotko (demeaning experience at contract level) + subsidies
set more off
xtivreg lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec2 dev_aexp_ftc2 dev_tenure dev_tenure_sq subsidies)   ///
i.ed2 i.ed3 i.female i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, /// 
fe vce(cluster pid)
outreg2 using "${path}/tables/reg_returns2exp_IV.tex" , append keep(aexp_oec aexp_ftc) ctitle(IV) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

** IV: Altonji and Shakotko  (demeaning experience at contract-match level) + subsidies 
set more off
xtivreg lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec dev_aexp_ftc dev_tenure dev_tenure_sq subsidies  )   ///
i.ed2 i.ed3 i.female i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2,  /// 
fe vce(cluster pid)
outreg2 using "${path}/tables/reg_returns2exp_IV.tex" , append keep(aexp_oec aexp_ftc) ctitle(IV) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)



* Table A.12: Dual Returns to Experience: Match Quality - First stage
set more off
ivreghdfe lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec2 dev_aexp_ftc2 dev_tenure dev_tenure_sq)   ///
i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, first /// 
absorb(pid) cluster(pid) 
matrix list e(first)

* Table A.13: Dual Returns to Experience: Match Quality - First stage
ivreghdfe lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec dev_aexp_ftc dev_tenure dev_tenure_sq)   ///
i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, first /// 
absorb(pid) cluster(pid) 
matrix list e(first)

* Table A.14: Dual Returns to Experience: Match Quality - First stage
ivreghdfe lnw (aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec2 dev_aexp_ftc2 dev_tenure dev_tenure_sq subsidies)   ///
i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, first /// 
absorb(pid) cluster(pid) 
matrix list e(first)

* Table A.15: Dual Returns to Experience: Match Quality - First stage
set more off
ivreghdfe lnw ( aexp_oec aexp_ftc tenure tenure_sq =  dev_aexp_oec dev_aexp_ftc dev_tenure dev_tenure_sq subsidies  )   ///
i.sme i.young i.sk2 i.sk3 i.parttime i.dummyT i.pexpgroup i.year i.sector i.provfirm_cc2, first  /// 
absorb(pid) cluster(pid) 
matrix list e(first)
