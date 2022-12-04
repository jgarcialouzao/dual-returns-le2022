clear all
capture log close
cap set more off
set matsize 8000
set maxvar 10000

*Globals
global fvars "sme young"
global xvars "ed2 ed3 female"
global jvars "sk2 sk3 parttime dummyT c.tenure##c.tenure"
global fevars "pexpgroup year sector provfirm_cc2"


*Load data
use "${path}/dta_files/estimation_sample.dta", replace

*Keep only employed
keep if E==1

*Dep variable
gen lnw = log(w)

*Potential experience
gen pexpgroup=pexp
recode pexpgroup(1/3=1) (4/6=2) (7/9=3) (10/12=4) (13/15=5)



* TABLE 1 - Dual Returns to Experience
*OLS
set more off
reghdfe lnw aexp $xvars $jvars $fvars, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp.tex" , replace keep(dummyT aexp) ctitle(OLS) tex(frag) nocons dec(4)  nonotes label

reghdfe lnw aexp_oec aexp_ftc $xvars $jvars $fvars, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(OLS) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*FE
set more off
reghdfe lnw aexp $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp.tex" , append keep(dummyT aexp) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


* TABLE A.2 - Gap in Returns to Experience
*OEC vs FTC
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_comparison.tex" , replace keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Male vs Female
reghdfe lnw aexp c.aexp#i.female  $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_comparison.tex" , append keep(dummyT aexp c.aexp#i.female) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*College vs Non-college
reghdfe lnw aexp c.aexp#i.ed3  $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_comparison.tex" , append keep(dummyT aexp c.aexp#i.ed3 ) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
	


* TABLE A.3 - Robustness to Income Measure
*Alternative income definitions
gen lnw_orig = log(w_orig)
gen lnw_tax = log(w_tax)
gen lnw_total = log(w_total)

*Censored
reghdfe lnw_orig aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_defw.tex" , replace keep(aexp_oec aexp_ftc) ctitle(Censored) tex(frag) nocons dec(4)  nonotes label

*Tax Data
reghdfe lnw_tax  aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_defw.tex" , append keep(aexp_oec aexp_ftc) ctitle(Tax Data) tex(frag) nocons dec(4)  nonotes label

*Pooled Income
reghdfe lnw_total aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_defw.tex" , append keep(aexp_oec aexp_ftc) ctitle(Pooled Annual Income) tex(frag) nocons dec(4)  nonotes label

drop lnw_total lnw_orig lnw_tax


* TABLE A.4 - Robustness to Life-Cycle Control
*Cubic potential experience
gen pexp1 = pexp
gen pexp2 = pexp*pexp
gen pexp3 = pexp2*pexp

reghdfe lnw aexp_oec aexp_ftc $jvars $fvars pexp pexp2 pexp3, absorb(year sector provfirm_cc2 pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_lifecycle.tex" , replace keep(aexp_oec aexp_ftc) ctitle(Cubic) tex(frag) nocons dec(4)  nonotes label

*Excluding pexp
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb(year sector provfirm_cc2 pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_lifecycle.tex" , append keep(aexp_oec aexp_ftc) ctitle(No Pexp) tex(frag) nocons dec(4)  nonotes label

*Age effects
recode age(16/20=1) (21/25=2) (26/30=3) (31/35=4) (36/38=5)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb(age year sector provfirm_cc2 pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_lifecycle.tex" , append keep(aexp_oec aexp_ftc) ctitle(Age) tex(frag) nocons dec(4)  nonotes label



* TABLE A.5 - Robustness to 2012 EPL Reform
*Dummy pre- and post-2012 reform
gen dummy_post2012=.
replace  dummy_post2012=0 if year<2012
replace  dummy_post2012=1 if year>=2012

*OLS
reghdfe lnw  aexp c.aexp#i.dummy_post2012 $xvars $jvars $fvars, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_prereform.tex" , replace ctitle(OLS) tex(frag) nocons dec(4)  nonotes label

reghdfe lnw aexp_oec c.aexp_oec#i.dummy_post2012 aexp_ftc c.aexp_ftc#i.dummy_post2012 $xvars $jvars $fvars, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_prereform.tex" , append  ctitle(OLS) tex(frag) nocons dec(4)  nonotes label

*Fixed-Effects
reghdfe lnw aexp c.aexp#i.dummy_post2012 $jvars $fvars, absorb($fevars pid) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_prereform.tex" , append  ctitle(FE) tex(frag) nocons dec(4)  nonotes label

reghdfe lnw aexp_oec c.aexp_oec#i.dummy_post2012 aexp_ftc c.aexp_ftc#i.dummy_post2012 $jvars $fvars, absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_prereform.tex" , append ctitle(FE) tex(frag) nocons dec(4)  nonotes label




* TABLE A.6 - Robustness to Cohort Analysis
*Graduation year cohort=1996
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if pygrad==1996 , absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_bycohort.tex" , replace ctitle(FE) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label

*Graduation year cohort=1997
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if pygrad==1997 , absorb($fevars pid, savefe) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_bycohort.tex" , append ctitle(FE) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label
 
*Graduation year cohort=1998
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if pygrad==1998 , absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_bycohort.tex" , append ctitle(FE) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label

*Graduation year cohort=1999
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if pygrad==1999 , absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_bycohort.tex" , append ctitle(FE) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label


* TABLE A.7 - Robustness to Contract-Specific Tenure
*OLS
reghdfe lnw aexp_oec aexp_ftc i.dummyT#c.tenure i.dummyT#c.tenure#c.tenure ///
$xvars $jvars $fvars, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_tenureinter.tex" , replace  ctitle(OLS) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label
*FE
reghdfe lnw aexp_oec aexp_ftc i.dummyT#c.tenure i.dummyT#c.tenure#c.tenure ///
$jvars $fvars, absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_tenureinter.tex" , append  ctitle(FE) keep(aexp_oec aexp_ftc)  tex(frag) nocons dec(4)  nonotes label
*OLS
reghdfe lnw aexp_oec aexp_ftc i.dummyT#c.tenure i.dummyT#c.tenure#c.tenure i.dummyT#c.tenure#c.tenure#c.tenure ///
$xvars $jvars $fvars c.tenure#c.tenure#c.tenure , absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_tenureinter_2.tex" , append  ctitle(OLS) keep(aexp_oec aexp_ftc) tex(frag) nocons dec(4)  nonotes label
*FE
reghdfe lnw aexp_oec aexp_ftc i.dummyT#c.tenure i.dummyT#c.tenure#c.tenure i.dummyT#c.tenure#c.tenure#c.tenure ///
$jvars $fvars c.tenure#c.tenure#c.tenure , absorb($fevars pid, savefe) keepsing cluster(pid) 
outreg2 using "${path}/tables/reg_returns2exp_tenureinter_2.tex" , append  ctitle(FE) keep(aexp_oec aexp_ftc) tex(frag) nocons dec(4)  nonotes label




* TABLE A.8 - Robustness to Gender-Specific Returns
*Males
*OLS
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if female==0, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_gender.tex" , replace keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Fixed-effects
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if female==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_gender.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Females
*OLS
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  if female==1, absorb($fevars) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_gender.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Fixed-effects
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  if female==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_gender.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)



* FIGURE A.6 - Robustness to Non-Parametric Experience:
*Non-Parametric aexp
bys year: quantiles aexp_ftc if aexp_ftc>0, gen(Ebin_ftc) n(100)
recode Ebin_ftc(1/4=1) (5/7=5) (8/10=8) (11/15=11) (16/20=16) (21/25=21) (26/30=26) (31/35=31) (36/40=36) (41/45=41) (46/50=46) (51/55=51) (56/60=56) (61/65=61) (66/70=66) (71/75=71) (76/80=76) (81/85=81) (86/90=86) (91/94=91) (95/97=95) (98/100=100)
replace Ebin_ftc=0 if aexp_ftc==0

bys year: quantiles aexp_oec if aexp_oec>0, gen(Ebin_oec) n(100)
recode Ebin_oec(1/4=1) (5/7=5) (8/10=8) (11/15=11) (16/20=16) (21/25=21) (26/30=26) (31/35=31) (36/40=36) (41/45=41) (46/50=46) (51/55=51) (56/60=56) (61/65=61) (66/70=66) (71/75=71) (76/80=76) (81/85=81) (86/90=86) (91/94=91) (95/97=95) (98/100=100)
replace Ebin_oec=0 if aexp_oec==0

qui tab Ebin_oec, gen(Ebin_oec_)
qui tab Ebin_ftc, gen(Ebin_ftc_)

reghdfe lnw Ebin_oec_2-Ebin_oec_23 Ebin_ftc_2-Ebin_ftc_23 $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_nonparametric.xls" , replace  keep(Ebin_oec_2-Ebin_oec_23) ctitle(OEC) tex(frag) nocons dec(4)  nonotes label 
outreg2 using "${path}/tables/reg_returns2exp_nonparametric.xls" , append keep(Ebin_ftc_2-Ebin_ftc_23) ctitle(FTC) tex(frag) nocons dec(4)  nonotes label

drop Ebin_oec* Ebin_ftc* 

