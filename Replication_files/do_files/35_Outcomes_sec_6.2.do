clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13
set cformat %5.4f


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

*Tenure 
gen tenuregroup=ten
recode tenuregroup(1/2=1) (3/4=2) (5/6=3) (7/9=4) (10/30=5)


* Share of time spent in high skill occupation
bys pid: egen share_sk3=mean(sk3)


*Table 6 - Dual Returns to Experience: Observed Ability

*Fixed-Effects by EDUCATION
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if ed3==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_noncollege.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  if ed3==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_college.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Fixed-Effects by OCCUPATION
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if share_sk3<0.5, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_lowskill.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if share_sk3>=0.5, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_highskill.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


* Figure 2 - Dual Returns to Experience: Unobserved Ability


*Number of bootstrap repetitions
gen Nboot=50 

*OEC contracts
gen dummyP=1-dummyT


*HOMOGENEOUS RETURN
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid, savefe) keepsing cluster(pid) 
gen pid_fe = __hdfe5__
drop __hdfe5__


*HETEROGENEOUS RETURN - De la Roca and Puga (2017) estimation
gen toler=0.001 
gen distance=1
gen pid_fe_het = pid_fe

while (distance>toler) {
qui: reghdfe lnw c.aexp_oec c.aexp_ftc c.aexp_oec#c.pid_fe_het c.aexp_ftc#c.pid_fe_het $jvars $fvars, absorb($fevars pid, savefe) keepsing cluster(pid) 

egen diff=mean(abs(__hdfe5__ - pid_fe_het))
replace distance = diff
drop diff
sum distance
replace pid_fe_het = __hdfe5__
drop  __hdfe1*
}


forval i=1(1)99{
egen pid_fe_het_p`i'=pctile(pid_fe_het), p(`i')
}


*ESTIMATE HET RETURN REGRESSION WITH FINAL FE
reghdfe lnw c.aexp_oec c.aexp_ftc c.aexp_oec#c.pid_fe_het c.aexp_ftc#c.pid_fe_het $jvars $fvars, absorb($fevars pid, savefe) resid keepsing cluster(pid) 
predict XB
predict u, residuals


forval i=1(1)99{
gen beta_aexp_ftc_p`i' = _b[aexp_ftc] + _b[c.aexp_ftc#c.pid_fe_het]*pid_fe_het_p`i'
gen beta_aexp_oec_p`i' = _b[aexp_oec] + _b[c.aexp_oec#c.pid_fe_het]*pid_fe_het_p`i'
}

save "${path}/dta_files/hetreturn_estimates.dta", replace



*WILD-BOOTSTRAP STARTS HERE
use "${path}/dta_files/hetreturn_estimates.dta", clear

forvalues s= 1(1)100 {
disp in red "`s'"

preserve

*Sample residuals with Clustered Rademacher draws 
bys pid: gen byte v = cond( runiform () <.5 ,1 , -1) if _n == 1
bys pid (v): replace v=v[1] if v==.

*CREATE SYNTHETIC DEPENDENT VARIABLE
gen ystar = XB + u*v

*RUN FE REGRESSION AGAIN
reghdfe ystar c.aexp_oec c.aexp_ftc c.aexp_oec#c.pid_fe_het c.aexp_ftc#c.pid_fe_het $jvars $fvars, absorb($fevars pid) keepsing cluster(pid) 

*CREATE and KEEP ONLY MARGINAL EFFECTS
forval i=1(1)99{
gen beta_aexp_ftc_p`i' = _b[aexp_ftc] + _b[c.aexp_ftc#c.pid_fe_het]*pid_fe_het_p`i'
gen beta_aexp_oec_p`i' = _b[aexp_oec] + _b[c.aexp_oec#c.pid_fe_het]*pid_fe_het_p`i'
}

keep beta_aexp_ftc_p* beta_aexp_oec_p*
keep if _n==1

* STORE 
tempfile bsample`s'
save `bsample`s''
restore
}


*APPEND ACROSS BOOTSTRAPPED REPLICATIONS
use `bsample1', clear
forvalues s =2(1)50 {
append using `bsample`s''
}


*COMPUTE ST.DEVIATION OF BOOTSTRAPPED SAMPLE
forval i=1(1)99{
egen std_beta_aexp_ftc_p`i' = sd(beta_aexp_ftc_p`i') 
egen std_beta_aexp_oec_p`i' = sd(beta_aexp_oec_p`i') 
}

gen id=_n
reshape long beta_aexp_ftc_p beta_aexp_oec_p std_beta_aexp_ftc_p std_beta_aexp_oec_p, i(id) j(p)
reshape wide beta_aexp_ftc_p beta_aexp_oec_p std_beta_aexp_ftc_p std_beta_aexp_oec_p, i(p) j(id)
keep p std_beta_aexp_ftc_p1 std_beta_aexp_oec_p1
rename std_beta_aexp_ftc_p1 std_beta_aexp_ftc_p
rename std_beta_aexp_oec_p1 std_beta_aexp_oec_p
sort p
save "${path}/dta_files/hetreturn_sterrors.dta", replace



*COMBINE ESTIMATES with ST.ERROR AND PLOT FIGURE
use "${path}/dta_files/hetreturn_estimates.dta", clear
keep beta_aexp_ftc_p* beta_aexp_oec_p*
keep if _n==1
gen id=1
reshape long beta_aexp_ftc_p beta_aexp_oec_p, i(id) j(p)
sort p 
merge p using "${path}/dta/hetreturn_sterrors.dta"
drop _merge

gen beta_aexp_ftc_p_low = beta_aexp_ftc_p -1.96*std_beta_aexp_ftc_p
gen beta_aexp_ftc_p_high = beta_aexp_ftc_p +1.96*std_beta_aexp_ftc_p

gen beta_aexp_oec_p_low = beta_aexp_oec_p -1.96*std_beta_aexp_oec_p
gen beta_aexp_oec_p_high = beta_aexp_oec_p +1.96*std_beta_aexp_oec_p
 
qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern


tw (rcap beta_aexp_ftc_p_low beta_aexp_ftc_p_high p, lcolor(orange_red) sort ) ///
   (rcap beta_aexp_oec_p_low beta_aexp_oec_p_high p, lcolor(midblue) sort )  ///
   (connect beta_aexp_ftc_p p, lcolor(orange_red) mcolor(orange_red) lpattern(dash)) ///
   (connect beta_aexp_oec_p p, lcolor(ebblue) mcolor(ebblue) lpattern(dash)), ///
   legend(order(3 "FTC" 4 "OEC"))
   
qui graph export "${path}/figures/ftcgap_hetreturn.png", as(png) replace
