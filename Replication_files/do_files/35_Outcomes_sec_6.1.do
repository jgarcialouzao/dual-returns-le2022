
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


*Merge with IV:US empshare
sort sector year
merge m:1 sector year using "${path}/dta_files/empshare_merge.dta"
drop _merge


*Movers
bys pid (year): gen M = firm_cc2!=firm_cc2[_n-1] & E==1 & E[_n-1]==1

*Movers within same sector
bys pid (year): gen M_same = firm_cc2!=firm_cc2[_n-1] & E==1 & E[_n-1]==1  & sector==sector[_n-1]

*Involuntary movers
bys pid (year): gen l1_bajareason=bajareason[_n-1] if firm_cc2!=firm_cc2[_n-1] & E==1 & E[_n-1]==1
gen dummy_exo=.
replace dummy_exo=1 if (l1_bajareason==77 | l1_bajareason==91 | l1_bajareason==54 | l1_bajareason==92 | l1_bajareason==93 | l1_bajareason==94)
replace dummy_exo=0 if (l1_bajareason!=77 & l1_bajareason!=91 & l1_bajareason!=54 & l1_bajareason!=92 & l1_bajareason!=93 & l1_bajareason!=94)

* Convive
gen convive_1664=.
replace convive_1664=1 if convive_06==0 & convive_715==0 & convive_m65==0
replace convive_1664=0 if (convive_06==1 |  convive_715==1 | convive_m65==1)

* High skill 
bys pid: egen share_sk3=mean(sk3)

*Construct distance across sectors
gen sk1=.
replace sk1=1 if sk2==0 & sk3==0
replace sk1=0 if sk2==1  
replace sk1=0 if sk3==1 
sort sector
merge m:1 sector using "${path}/dta_files/sector_skill_composition.dta"
bys pid (year): gen distance = sqrt( (avg_sk1-avg_sk1[_n-1])^2  + (avg_sk2-avg_sk2[_n-1])^2 + (avg_sk3-avg_sk3[_n-1])^2)  if M==1
drop _merge


*Dep variable
gen lnw = log(w)

*Potential experience
gen pexpgroup=pexp
recode pexpgroup(1/3=1) (4/6=2) (7/9=3) (10/12=4) (13/15=5)



preserve

* keep only employed
keep if E==1

set more off
*Table A.20 - Job switching selection equation 
*Column 1
xtset pid year
probit M  i.convive_06 i.convive_715 i.convive_1664  $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2  if E==1, cluster(pid)
outreg2 using "${path}/tables/reg_selection_movers.tex" , replace  ctitle(Univariate) tex(frag) nocons dec(4)  nonotes label

predict phat, xb
gen imr_M = normalden(phat)/normal(phat)
drop phat



*Table A.21 - Conditional industry switching selection equation 
* Columns 1 and 2
set more off
xtset pid year
heckprobit M_same l.lnw Dempshare $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2 , sel(M= i.convive_06 i.convive_715 i.convive_1664 $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2) cluster(pid)  
outreg2 using "${path}/tables/reg_selection_movers_conditional_seq.tex" , replace  ctitle(Multinomial) tex(frag) nocons dec(4)  nonotes label 

predict phat, xb
gen imr_Msector_cond_seq = normalden(phat)/normal(phat)
drop phat

*Drop entrants
bys pid (year): drop if _n == 1

*Keep only switchers
keep if M==1

*Job switchers (ALL)
*Column 1- FE
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_overall.tex" , append keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 2- FE+Heckman (job switching)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/evidence/tables/reg_returns2exp_movers_overall_heck.tex" , append keep(dummyT imr_M aexp_oec aexp_ftc) ctitle(FE+Heck) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


*Job switchers (Within industry)
*Column 3- FE
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars   						    if M_same==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors.tex" , replace keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 4- FE+Heckman (job switching)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M  						if M_same==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors.tex" , append keep(imr_M aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 5 -FE+Heckman (conditional job switching)
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  imr_Msector_cond_seq 		if M_same==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_seq.tex" , append keep(imr_Msector_cond_seq aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


*Job switchers (Between industry)
*Column 6- FE
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  							if M_same==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 7- FE+Heckman (job switching)
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M 						if M_same==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors.tex" , append keep(imr_M aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 8 - FE+Heckman (conditional job switching)
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  imr_Msector_cond_seq 		if M_same==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_seq.tex" , append keep(imr_Msector_cond_seq aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4) nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)



*Min and avg distance
qui: sum distance if distance>0
gen avg_distance=r(mean)
gen max_distance=r(max)


*Table 5 - Industry mobility and skills 
*Column 1
reghdfe lnw aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance $jvars $fvars  if M==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_bydistance.tex" , replace keep(aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*avg_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*avg_distance)-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*max_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*max_distance)-1)

*Column 2
reghdfe lnw aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance $jvars $fvars imr_M  if M==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_bydistance.tex" , append keep(aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance imr_M) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*avg_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*avg_distance)-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*max_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*max_distance)-1)

restore






preserve
set more off

* keep only employed
keep if E==1

*Table A.20 - Job switching selection equation with Bartik instrument
*Column 2
xtset pid year
probit M  i.convive_06 i.convive_715 i.convive_1664 Dempshare $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2  if E==1, cluster(pid)
outreg2 using "${path}/tables/reg_selection_movers_bartik.tex" , replace  ctitle(Univariate) tex(frag) nocons dec(4)  nonotes label

predict phat, xb
gen imr_M = normalden(phat)/normal(phat)
drop phat


*Table A.21 - Conditional industry switching selection equation with Bartik instrument
* Columns 3 and 4
set more off
xtset pid year
heckprobit M_same l.lnw Dempshare $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2 , sel(M= i.convive_06 i.convive_715 i.convive_1664 Dempshare $xvars l.sk2 l.sk3 l.dummyT l.parttime l.sme l.young l.tenure l.tenure_sq i.pexp i.year i.l.sector i.l.provfirm_cc2) cluster(pid)  
outreg2 using "${path}/tables/reg_selection_movers_conditional_seq_bartik.tex" , replace  ctitle(Multinomial) tex(frag) nocons dec(4)  nonotes label 

predict phat, xb
gen imr_Msector_cond_seq = normalden(phat)/normal(phat)
drop phat


*Drop entrants
bys pid (year): drop if _n == 1

*Keep only switchers
keep if M==1


*Table A.18 - Job switching with expanded heckman correction (Bartik instrument)
*ALL
*Column 1
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_overall_heck_bartik.tex" , replace (dummyT imr_M aexp_oec aexp_ftc) ctitle(FE+Heck) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Within industries
*Column 2
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M  						if M_same==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_bartik.tex" , append keep(imr_M aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Column 3
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  imr_Msector_cond_seq 		if M_same==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_seq_bartik.tex" , append keep(imr_Msector_cond_seq aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)

*Between industries
*Column 4
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars imr_M 						if M_same==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_bartik.tex" , append keep(imr_M aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Column 5
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  imr_Msector_cond_seq 		if M_same==0, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_sectors_seq_bartik.tex" , append keep(imr_Msector_cond_seq aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4) nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


*Min and avg distance
qui: sum distance if distance>0
gen avg_distance=r(mean)
gen max_distance=r(max)


*Table A.19 - Industry mobility and skills  with Bartik instrument
reghdfe lnw aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance $jvars $fvars imr_M  if M==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_movers_bydistance_bartik.tex" , append keep(aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance imr_M) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*avg_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*avg_distance)-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*max_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*max_distance)-1)

restore




preserve

* keep only employed
keep if E==1

*Drop entrants
bys pid (year): drop if _n == 1

*Keep only switchers
keep if M==1

*Min and avg distance
qui: sum distance if distance>0
gen avg_distance=r(mean)
gen max_distance=r(max)


*Table A.16 - Involuntary movers
*Column 1 - All
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars if dummy_exo==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_invmovers.tex" , replace keep(dummyT aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Column 2 - Within industry
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars   						    if M_same==1 & dummy_exo==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_invmovers.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
*Column 3 - Between industry
set more off
reghdfe lnw aexp_oec aexp_ftc $jvars $fvars  							if M_same==0 & dummy_exo==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_invmovers.tex" , append keep(aexp_oec aexp_ftc) ctitle(FE) tex(frag) nocons dec(4)  nonotes label
nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)


*Table A.17 - Industry mobility and skills for Involuntary movers
reghdfe lnw aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance $jvars $fvars  if M==1 & dummy_exo==1, absorb($fevars pid) keepsing cluster(pid)
outreg2 using "${path}/tables/reg_returns2exp_invmovers_bydistance.tex" , replace keep(aexp_oec aexp_ftc c.aexp_oec#c.distance c.aexp_ftc#c.distance  distance) ctitle(FE) tex(frag) nocons dec(4)  nonotes label

nlcom 100*(_b[aexp_oec]/_b[aexp_ftc]-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*avg_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*avg_distance)-1)
nlcom 100*( (_b[aexp_oec]+ _b[c.aexp_oec#c.distance]*max_distance)/(_b[aexp_ftc]+_b[c.aexp_ftc#c.distance]*max_distance)-1)


restore



