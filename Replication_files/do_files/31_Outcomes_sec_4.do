clear all
capture log close
cap set more off
set matsize 8000
set maxvar 10000

*Style
qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern

*Globals
global fvars "sme young"
global xvars "ed2 ed3 female"
global jvars "sk2 sk3 parttime dummyT c.tenure##c.tenure"
global fevars "pexpgroup year sector provfirm_cc2"


*Load data
use "${path}/dta_files/estimation_sample.dta", replace

*Keep only employed
keep if E==1


* TABLE A.1 - Descriptive Statistics
xtset pid year
gen w_growth = (log(w) -log(l1.w))

bys pid (year): gen ftc_entry = 1 if dummyT == 1 & _n == 1
bys pid (ftc_entry): replace ftc_entry = ftc_entry[1] if ftc_entry==.
replace ftc_entry = 0 if ftc_entry == .

bys pid: egen tmp = total(dummyT)
gen never_ftc = tmp==0

gen age = year - yearbirth

gunique pid  if ed2==0 & ed3==0
gen dropouts = `r(N)'

gunique pid  if ed2==1
gen hs = `r(N)'

gunique pid  if  ed3==1
gen college = `r(N)'

preserve
gcollapse (firstnm) female age_entry = age ed2 ed3 w_entry = w days* nojobs_entry = nojobs (lastnm) pexp nojobs aexp* never_ftc dropouts hs college (mean) w_growth , by(pid ftc_entry)

label var female "Female"
label var age_entry "Age at Entry"
label var w_entry "Wage at Entry"
label var nojobs_entry "No. Jobs at Entry"
label var days "Days Worked at Entry"
label var days_oec "under OEC"
label var days_ftc "under FTC"

label var nojobs "No. Jobs"
label var aexp "Experience (yrs)"
label var aexp_oec "under OEC"
label var aexp_ftc "under FTC"
label var never_ftc "Never on FTC"
label var w_growth "Annual Wage Growth"

estpost summarize age_entry female ed3 w_entry nojobs_entry days* pexp aexp* nojobs never_ftc w_growth 
est store desc
estpost summarize age_entry female ed3 w_entry nojobs_entry days* pexp aexp* nojobs never_ftc w_growth if ftc_entry==1
est store desc1
estpost summarize age_entry female ed3 w_entry nojobs_entry days* pexp aexp* nojobs never_ftc w_growth if ftc_entry==0
est store desc2
esttab desc desc1 desc2 using "${path}/tables/desc.tex", replace cells("mean(fmt(a3))") label nonum gaps f compress
restore 




* FIGURE A.1 - Distribution of Contract Duration
*Length of contracts
preserve
bys pid firm_cc2 alta baja: keep if _n == 1
gen finaldate = mdy(12, 31, 2018)
gen enddate = mdy(12, 31, 2099)
 
gen length=baja-alta+1
replace length=finaldate-alta+1 if baja==enddate

keep length dummyT

sum length if dummyT==1 ,d 

tw (hist length if dummyT==1 , width(60) color(ebblue%25)) (scatteri 0 180 0.004 180, recast(line) lcolor(orange_red) lpattern(dash) lwidth(thin))  (scatteri 0 296 0.004 296, recast(line) lcolor(forest_green) lwidth(thin)), xtitle("Number of Days", size(*.95)) ytitle("Density", size(*.95) height(5))  xlabel(0(1000)9000)  legend(size(*1.1) symxsize(*.75) row(1)  order(2 "Median" 3 "Mean")) ylabel(0(0.001)0.004)
qui graph export "${path}/figures/length_density_FTC.png", as(png) replace

sum length if dummyT==0 ,d

tw (hist length if dummyT==0 , width(60) color(ebblue%25)) (scatteri 0 759 0.0012 759, recast(line) lcolor(orange_red) lpattern(dash) lwidth(thin))  (scatteri 0 1274 0.0012 1274, recast(line) lcolor(forest_green) lwidth(thin)), xtitle("Number of Days", size(*.95)) ytitle("Density", size(*.95) height(5))  xlabel(0(1080)9000)  legend(size(*1.1) symxsize(*.75) row(1)  order(2 "Median" 3 "Mean")) ylabel(0(0.0003)0.0012) xlabel(0(1000)9000) 
qui graph export "${path}/figures/length_density_OEC.png", as(png) replace
restore


* FIGURE A.2 - Distribution of Workers by Relative FTC Experience
gen share_ftc = 100*(aexp_ftc/aexp)
gen aexp1= int(aexp)
preserve 
qui grstyle init
qui grstyle set plain, compact grid dotted /*no grid*/
qui grstyle color major_grid gs13
qui grstyle set symbol
qui grstyle set lpattern
twoway (hist share_ftc  if aexp1==3, w(2.5)   percent lcolor(none) fcolor("146 195 51 %33") ) (hist share_ftc if aexp1==6 , w(2.5)  percent fcolor(none) lwidth(thin) lcolor("64 105 166") lpattern(shortdash)  ) (hist share_ftc if aexp1==9 , w(2.5)  percent fcolor(none) lwidth(thin) lcolor("255 86 29") ), xtitle("Relative FTC Experience") ytitle("Percentage of Workers")  legend(order( 1 "3 Years" 2 "6 Years" 3 "9 Years" ) rows(1)) xlabel(0(5)100) ylabel(0(5)35,format(%5.0f)) 
qui graph export "${path}/figures/distribution_ftcexp.png", as(png) replace
restore



* FIGURE A.3 - Fixed-Term Contract Rate across Sectors
label var dummyT "Fixed-Term Contract Rate (%)"
label var sector "Sector of Activity"
label var group  "Occupation Category"
label var provfirm_cc2 "Workplace Location"

replace dummyT = dummyT*100

preserve
drop if sector==.
gcollapse (mean) dummyT , by(sector year)
gcollapse (mean) dummyT (min) min = dummyT (max) max = dummyT, by(sector)
graph tw (bar dummyT sector, lcolor("64 105 166") bcolor("64 105 166 %50") ) (scatter min sector, lcolor("255 86 29") mcolor("255 86 29 %50") msymbol(O) ) (scatter max sector, lcolor("255 86 29") mcolor("255 86 29 %50")  msymbol(O)  ), ylabel(0(10)80) xlabel(1(1)10) legend(off) ytitle("Fixed-Term Contract Rate (%)")
qui graph export "${path}/figures/FTCrate_sector.png", as(png) replace
restore	

* FIGURE A.4 - Fixed-Term Contract Rate across Occupations

preserve
drop if provfirm_cc2>50
gcollapse (mean) dummyT , by( provfirm_cc2 year)
gcollapse (mean) dummyT (min) min = dummyT (max) max = dummyT, by( provfirm_cc2)
graph tw (bar dummyT  provfirm_cc2, lcolor("64 105 166") bcolor("64 105 166 %50") ) (scatter min  provfirm_cc2, lcolor("255 86 29") mcolor("255 86 29 %50") msymbol(O) ) (scatter max  provfirm_cc2, lcolor("255 86 29") mcolor("255 86 29 %50")  msymbol(O)  ), ylabel(0(10)80) xlabel(1(1)50, alternate) legend(off) ytitle("Fixed-Term Contract Rate (%)") 
qui graph export "${path}/figures/FTCrate_ provfirm_cc2.png", as(png) replace
restore	

* FIGURE A.5 - Fixed-Term Contract Rate across Locations

preserve
drop if group==.
gcollapse (mean) dummyT , by(group year)
gcollapse (mean) dummyT (min) min = dummyT (max) max = dummyT, by(group)
graph tw (bar dummyT group, lcolor("64 105 166") bcolor("64 105 166 %50") ) (scatter min group, lcolor("255 86 29") mcolor("255 86 29 %50") msymbol(O) ) (scatter max group, lcolor("255 86 29") mcolor("255 86 29 %50")  msymbol(O)  ), ylabel(0(10)80) xlabel(1(1)11) legend(off) ytitle("Fixed-Term Contract Rate (%)")
qui graph export "${path}/figures/FTCrate_group.png", as(png) replace
restore	






