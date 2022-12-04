
version 14

clear all

capture log close

set more off

timer clear 5
timer on 5

foreach j of numlist 2013/$v {

*****************************************************************************
*****************************************************************************
*********** STEP 2.A: MERGE Individuals with Bases  *************************
*****************************************************************************
*****************************************************************************


/* ==========================================================================
1) Employees contributions (Cotización por cta ajena) + Individuals
=============================================================================*/
use "{path}\cohorts_2018\IndividualsWO.dta", clear
keep if MCVL_WO==`j' /*Solo para individuos que aparezcan por última vez en esta ola*/
merge 1:m pid using "{path}\cohorts_2018\MCVL`j'COTIZA.dta", generate(_mergeBases) keep(match)

label var _mergeBases "Rtdo. de merge Individuals`j' using Bases`j'"
*keep if _mergeBases==3 
qui compress
save "{path}\cohorts_2018\IndividualsBases`j'.dta", replace


/* ==========================================================================
2) Self-employed contributions (Cotización por cta propia) + Individuals 
=============================================================================*/
use "{path}\cohorts_2018\IndividualsWO.dta", clear
keep if MCVL_WO==`j'
merge 1:m pid using "{path}\cohorts_2018\MCVL`j'COTIZA_13.dta", generate(_mergeBases13) keep(match)
label var _mergeBases13 "Rtdo. de merge Individuals`j' using Bases`j'13"
*keep if _mergeBases13==3
qui compress
save "{path}\cohorts_2018\IndividualsBases`j'13.dta", replace


/* ==========================================================================
3) We join both datasets:
=============================================================================*/
use "{path}\cohorts_2018\IndividualsBases`j'.dta", clear
append using "{path}\cohorts_2018\IndividualsBases`j'13.dta"
drop _mergeBases _mergeBases13  
sort pid firm_cc2 year


/* ==========================================================================
4) We put this file in a separate folder, that we create:
=============================================================================*/   
qui compress
save "{path}\cohorts_2018\IndividualsBases`j'All.dta", replace


/* ==========================================================================
5) Eliminate intermediate files:
=============================================================================*/  
erase "{path}\cohorts_2018\IndividualsBases`j'.dta" 
erase "{path}\cohorts_2018\IndividualsBases`j'13.dta"


**************************************************************************
**************************************************************************
********* STEP 2.B: MERGE Individuals with Affiliated  *******************
**************************************************************************
************************************************************************** 

/* ==========================================================================
1) Affiliation episodes + Individuals
=============================================================================*/

use "{path}\cohorts_2018\IndividualsWO.dta", clear
keep if MCVL_WO==`j' /*Solo para individuos que aparezcan por última vez en esta ola*/
merge 1:m pid using "{path}\cohorts_2018\MCVL`j'AFILIAD.dta", generate(_mergeAff) keep(match)
label var _mergeAff "Rtdo. de merge Individuals`j' using Afiliad"
*keep if _mergeAff==3 


/* ==========================================================================
2) Eliminate duplicates
=============================================================================*/
bys pid altadate bajadate firm_cc2: gen duplicados = _n
tab duplicados
drop if duplicados>1
drop duplicados



/* ==========================================================================
3) Entry YEAR and Exit YEAR
=============================================================================*/
gen altayear=int(altadate/10000)
gen bajayear=int(bajadate/10000)


/* ==========================================================================
4) ALTA Y BAJA, en formato fecha 
=========================================================================== */
tostring altadate, replace
gen alta=date(altadate,"YMD")
tostring bajadate, replace
gen baja=date(bajadate,"YMD")
format alta baja %tdDD.Mon.CCYY
label var alta "FECHA REAL DE ALTA EN LA AFILIACION"
label var baja "FECHA REAL DE BAJA EN LA AFILIACION"

order alta baja, after(bajadate)
drop altadate bajadate 
capture drop efecaltadate efecbajadate
drop if alta>baja /*Eliminamos episodios de duracion "negativa"*/


/* ==========================================================================
5) Save in separate folder: 
=============================================================================*/
sort pid firm_cc2 altayear bajayear alta baja
order pid firm_cc2 altayear bajayear alta baja , first

qui compress
save "{path}\cohorts_2018\IndividualsAffiliated`j'All.dta", replace


**************************************************************************
**************************************************************************
****** STEP 2.C: MERGE IndividualsAffiliated with IndividualsBases *******
**************************************************************************
************************************************************************** 

/* ==========================================================================
1) LOOP by cohort: Slice up the file "IndividualsAffiliated####All" into smaller 
files.
=============================================================================*/
local end   = `j'-16
local start = `j'-99
foreach i of numlist `start'/`end' {
use "{path}\cohorts_2018\IndividualsAffiliated`j'All.dta" if yearbirth==`i', clear

/* ==========================================================================
2) We change the "IndividualsAffiliated" file's SHAPE s.t. it fits with the one
of "IndividualsBases". In particular, we will have as many (repeated) observations 
of each affiliation episode as years between the entry and the exit date.
=============================================================================*/
gen expan_num = (bajayear - altayear)+1
expand expan_num, gen(duplicate)
sort pid alta baja firm_cc2
drop expan_num duplicate

/* ==========================================================================
3) To be able to do the merge with the contributions file ("IndividualsBases"), 
we create the variable contributionyear: 
=============================================================================*/
bys pid alta baja firm_cc2: gen year = cond(_n==1, altayear, altayear[1]+_n-1)
label variable year "AÑO DE COTIZACION"
save "{path}\cohorts_2018\IndividualsAffiliated`j'_`i'.dta", replace


/* ==========================================================================
4) LOOP by cohort: Slice up the file "IndividualsBases" into smaller files
=============================================================================*/
use "{path}\cohorts_2018\IndividualsBases`j'All.dta" if yearbirth==`i', clear 
save "{path}\cohorts_2018\IndividualsBases`j'_`i'.dta", replace

 
/* ==========================================================================
5) LOOP by cohort: Merge modified "IndividualsAffiliated" + "IndividualsBases"
=============================================================================*/
use "{path}\cohorts_2018\IndividualsAffiliated`j'_`i'.dta", clear 
merge m:1 pid firm_cc2 year using "{path}\cohorts_2018\IndividualsBases`j'_`i'.dta""{path}\cohorts_2018\, generate(_mergeBasesM)


/*NOTE: _mergeBasesM deserves some attention. We should not erase the observations that correspond with 
 affiliation episodes without associated contribution bases, especially if these episodes took place, totally or
 in part, before June 1980. We should keep this info (see 4_ReshapeData20##.do) before deleting any observation. */
 
/*OJO con _mergeBasesM, no debemos borrar las observaciones de episodios de afiliación que no
tienen bases de cotización asociadas (_merge==1), especialmente si se corresponden con periodos de
afiliación comprendidos, en total o en parte, antes de junio de 1980.
Debemos guardar esa info (ver 4.ReshapeData) antes de eliminar las observaciones: */
 
tab _mergeBasesM, m 
label var _mergeBasesM "MERGE IndividualsAffiliated using IndividualsBases"
drop if _mergeBasesM==2 /*See note above*/
gen dummy = (year<altayear | year>bajayear)
tab dummy /*There should be no 1s*/
drop dummy totalcontribution contributiontot 


/* NOTA: para una misma combinación de [pid]+[año de contribución]+[CCC2], la base de cotización será la misma
INCLUSO AUNQUE haya varios episodios de afiliación (distintas fechas de alta/baja) para esa misma 
combinación de [pid]+[año de contribución]+[CCC2] */

/* CAVEAT: for the same combination of pid+contributionyear+firm_cc2, the contribution base will be the same
EVEN IF there are several affiliation episodes (different entry/exit date) for that same combination of 
pid+contributionyear+firm_cc2 */
order pid firm_cc2 year alta baja, first
sort pid year alta baja firm_cc2
drop altayear bajayear
qui compress 

save "{path}\cohorts_2018\IndividualsBasesM`j'_`i'.dta", replace
}
*

}
*

timer off 5
timer list 5

 
