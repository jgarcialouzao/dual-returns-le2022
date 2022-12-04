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


* FIGURE 1 - Incidence of Temporary Employment
bys year: quantiles aexp if aexp>0, gen(Ebin) n(100)
recode Ebin(1/4=1) (5/7=5) (8/10=8) (11/15=11) (16/20=16) (21/25=21) (26/30=26) (31/35=31) (36/40=36) (41/45=41) (46/50=46) (51/55=51) (56/60=56) (61/65=61) (66/70=66) (71/75=71) (76/80=76) (81/85=81) (86/90=86) (91/94=91) (95/97=95) (98/100=100)
replace Ebin=0 if aexp==0

qui tab Ebin, gen(Ebin_)


*Fixed Effects
preserve
forvalues n=2(1)23 {

gen Ebin_`n'_rel_ftc30 =  Ebin_`n'==1 & aexp_ftc/aexp>=0.3 & aexp_ftc/aexp<=0.9
gen Ebin_`n'_rel_ftc90 =  Ebin_`n'==1 & aexp_ftc/aexp>0.9 & aexp_ftc/aexp<.
}

set more off
reghdfe lnw Ebin_2-Ebin_23 Ebin_2_rel_ftc30-Ebin_23_rel_ftc90 $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)

qui  g lnw_gapFE30= .
qui  g lnw_gapFE30_ci_low = .
qui  g lnw_gapFE30_ci_high= .

qui  g lnw_gapFE90= .
qui  g lnw_gapFE90_ci_low = .
qui  g lnw_gapFE90_ci_high= .

forvalues n=2(1)23 {
qui  replace lnw_gapFE30= 100*(_b[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_low= 100*(_b[Ebin_`n'_rel_ftc30]  - 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_high= 100*(_b[Ebin_`n'_rel_ftc30] + 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1 

qui  replace lnw_gapFE90= 100*(_b[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_low= 100*(_b[Ebin_`n'_rel_ftc90]  - 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_high= 100*(_b[Ebin_`n'_rel_ftc90] + 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1 
	
	
} 
* Construct figure here
gcollapse (mean) *_gap*, by(Ebin)

qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern

tw (connect lnw_gapFE30 Ebin, lcolor(ebblue) mcolor(ebblue%50)) ///
(rcap lnw_gapFE30_ci_low lnw_gapFE30_ci_high Ebin, lcolor(midblue) sort) ///
(connect lnw_gapFE90  Ebin, lcolor(orange_red) mcolor(orange_red%50) lpattern(dash)) ///
(rcap lnw_gapFE90_ci_low lnw_gapFE90_ci_high Ebin, lcolor(orange_red) sort) , ///
 xtitle("Percentiles of Experience", size(*.95)) ytitle("Percent", size(*.95) height(5)) xlabel(0(10)100, labsize(*1.1)) legend(size(*1.1) symxsize(*.75) row(1)  order(1 "Medium-FTC" 3 "High-FTC")) ylabel(-20(5)5, labsize(*1.1))  yline(0, lcolor(black%10)) 

qui graph export "${path}/figures/ftcgap_w_threshold3090.png", as(png) replace

restore


* FIGURE A.7 - Robustness to Thresholds: Incidence of Temporary Employment
preserve
forvalues n=2(1)23 {

gen Ebin_`n'_rel_ftc30 =  Ebin_`n'==1 & aexp_ftc/aexp>=0.5 & aexp_ftc/aexp<=0.9
gen Ebin_`n'_rel_ftc90 =  Ebin_`n'==1 & aexp_ftc/aexp>0.9 & aexp_ftc/aexp<.
}


set more off
reghdfe lnw Ebin_2-Ebin_23 Ebin_2_rel_ftc30-Ebin_23_rel_ftc90 $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)

qui  g lnw_gapFE30= .
qui  g lnw_gapFE30_ci_low = .
qui  g lnw_gapFE30_ci_high= .

qui  g lnw_gapFE90= .
qui  g lnw_gapFE90_ci_low = .
qui  g lnw_gapFE90_ci_high= .

forvalues n=2(1)23 {
qui  replace lnw_gapFE30= 100*(_b[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_low= 100*(_b[Ebin_`n'_rel_ftc30]  - 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_high= 100*(_b[Ebin_`n'_rel_ftc30] + 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1 

qui  replace lnw_gapFE90= 100*(_b[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_low= 100*(_b[Ebin_`n'_rel_ftc90]  - 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_high= 100*(_b[Ebin_`n'_rel_ftc90] + 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1 
	
	
} 


gcollapse (mean) *_gap*, by(Ebin)

qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern

tw (connect lnw_gapFE30 Ebin, lcolor(ebblue) mcolor(ebblue%50)) ///
(rcap lnw_gapFE30_ci_low lnw_gapFE30_ci_high Ebin, lcolor(midblue) sort) ///
(connect lnw_gapFE90  Ebin, lcolor(orange_red) mcolor(orange_red%50) lpattern(dash)) ///
(rcap lnw_gapFE90_ci_low lnw_gapFE90_ci_high Ebin, lcolor(orange_red) sort) ,  ///
xtitle("Percentiles of Experience", size(*.95)) ytitle("Percent", size(*.95) height(5)) xlabel(0(10)100, labsize(*1.1)) legend(size(*1.1) symxsize(*.75) row(1)  order(1 "Medium-FTC" 3 "High-FTC")) ylabel(-20(5)5, labsize(*1.1))  yline(0, lcolor(black%10)) 

qui graph export "${path}/figures/ftcgap_w_threshold5090.png", as(png) replace

restore


preserve
forvalues n=2(1)23 {

gen Ebin_`n'_rel_ftc30 =  Ebin_`n'==1 & aexp_ftc/aexp>=0.3 & aexp_ftc/aexp<=0.6
gen Ebin_`n'_rel_ftc90 =  Ebin_`n'==1 & aexp_ftc/aexp>0.6 & aexp_ftc/aexp<.
}

*FE
reghdfe lnw Ebin_2-Ebin_23 Ebin_2_rel_ftc30-Ebin_23_rel_ftc90 $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)

qui  g lnw_gapFE30= .
qui  g lnw_gapFE30_ci_low = .
qui  g lnw_gapFE30_ci_high= .

qui  g lnw_gapFE90= .
qui  g lnw_gapFE90_ci_low = .
qui  g lnw_gapFE90_ci_high= .

forvalues n=2(1)23 {
qui  replace lnw_gapFE30= 100*(_b[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_low= 100*(_b[Ebin_`n'_rel_ftc30]  - 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1  
qui  replace lnw_gapFE30_ci_high= 100*(_b[Ebin_`n'_rel_ftc30] + 1.96*_se[Ebin_`n'_rel_ftc30]) if Ebin_`n'==1 

qui  replace lnw_gapFE90= 100*(_b[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_low= 100*(_b[Ebin_`n'_rel_ftc90]  - 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1  
qui  replace lnw_gapFE90_ci_high= 100*(_b[Ebin_`n'_rel_ftc90] + 1.96*_se[Ebin_`n'_rel_ftc90]) if Ebin_`n'==1 
	
	
} 



gcollapse (mean) *_gap*, by(Ebin)

qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern

tw (connect lnw_gapFE30 Ebin, lcolor(ebblue) mcolor(ebblue%50)) ///
(rcap lnw_gapFE30_ci_low lnw_gapFE30_ci_high Ebin, lcolor(midblue) sort) ///
(connect lnw_gapFE90  Ebin, lcolor(orange_red) mcolor(orange_red%50) lpattern(dash)) ///
(rcap lnw_gapFE90_ci_low lnw_gapFE90_ci_high Ebin, lcolor(orange_red) sort) ,  ///
xtitle("Percentiles of Experience", size(*.95)) ///
ytitle("Percent", size(*.95) height(5)) xlabel(0(10)100, labsize(*1.1)) ///
legend(size(*1.1) symxsize(*.75) row(1)  order(1 "Medium-FTC" 3 "High-FTC")) ylabel(-20(5)5, labsize(*1.1))  yline(0, lcolor(black%10)) 

qui graph export "${path}/figures/ftcgap_w_threshold3060.png", as(png) replace

restore





* TABLE A.9 - Continuously Employed Workers

*Actual experience,% of potential experience
gen aexp_oec_share = aexp_oec/(1+aexp)
gen aexp_ftc_share = 1-aexp_oec_share

* employed >=0% of their life
reghdfe lnw aexp_ftc_share $xvars $jvars $fvars , absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_contemp.tex" , replace keep(dummyT aexp_ftc_share) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

* employed >=50% of their life
reghdfe lnw aexp_ftc_share $xvars $jvars $fvars if aexp>=0.5*(pexp-1), absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_contemp.tex" , append keep(dummyT aexp_ftc_share) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

* employed >=80% of their life
reghdfe lnw aexp_ftc_share $xvars $jvars $fvars if aexp>=0.8*(pexp-1), absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_contemp.tex" , append keep(dummyT aexp_ftc_share) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

* employed >=90% of their life
reghdfe lnw aexp_ftc_share $xvars $jvars $fvars if aexp>=0.9*(pexp-1), absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_contemp.tex" , append keep(dummyT aexp_ftc_share) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

* employed >=100% of their life
reghdfe lnw aexp_ftc_share $xvars $jvars $fvars if aexp==pexp-1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_contemp.tex" , append keep(dummyT aexp_ftc_share) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
