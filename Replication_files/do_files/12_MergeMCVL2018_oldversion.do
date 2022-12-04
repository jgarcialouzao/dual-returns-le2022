
version 14

clear all

capture log close

set more off

timer clear 4
timer on 4

foreach j of numlist 2005/2012{

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
merge 1:m pid using "{path}\cohorts_2018\MCVL`j'COTIZA_13.dta""{path}\cohorts_2018\, generate(_mergeBases13) keep(match)
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





/*




*** From here on the dofile is different for the 2005-2012 versions of the MCVL 
and for the 2013-onwards versions ***





*/



/* ==========================================================================
5) We change the file "IndividualsBases####All" in order to avoid duplicities. The monthly bases
are the same for each combination of pid-contributionyear-CC2, regardless of the number of affiliation
episodes linked to that combination of pid-contributionyear-CC2 in the same month.

Damos al fichero de bases una forma tal que evitemos duplicidades. Las bases mensuales 
de cotización son iguales por combinación de pid-contributionyear-CCC2, independientemente
de los episodios de afiliación que haya. 
=============================================================================*/  

/* 5.1) This is a way of making the variable incMONTH constant for each combination of
pid-year-cc2, even for missing values*/
foreach m of numlist 1/12{
bys pid firm_cc2 year: egen inc`m'_ = max(inc`m') 
bys pid firm_cc2 year: egen incaut`m'_ = max(incaut`m')
drop inc`m' incaut`m'
rename inc`m'_ inc`m'
rename incaut`m'_ incaut`m'
label var inc`m' "BASE DE COTIZACION POR CONTINGENCIAS COMUNES MES `m'"
label var incaut`m' "BASE DE COTIZACION CUENTA PROPIA Y OTROS MES `m'"
}
*

/* 5.2) Delete redundant variables, that appear already in the Affiliation files 
(since 2013 onwards, they don't appear any more in the Bases files)

Eliminamos variables redundantes, que ya están en el fichero de Afiliados 
(a partir de 2013 ya no están): */  
drop efecbajadate efecaltadate contracttype group bajadate altadate
bys pid firm_cc2 year: drop if _n>1


/* 5.3) Este fichero equivale al "IndividualsBases20XXAll" 
a partir de 2013, porque es en 2013 cuando cambia el fichero de bases de cotización y ya no es
necesario hacer este paso intermedio.

This file is equivalent to "IndividualsBases20XXAll" since 2013, year in which the contribution 
bases files change and is no longer necessary to execute this intermediate step*/
save "{path}\cohorts_2018\IndividualsBases`j'OK.dta", replace 


/* ==========================================================================
6) Eliminate intermediate files:
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
2) Eliminate duplicates and episodes with code 81 (see note below)
=============================================================================*/
/*
NOTE: Version 2005 of the MCVL registered, in the affiliation table, a considerable amount
of entry episodes in unconventional accounts that do not correspond to situations of
entry in the labor market, nor to assistential benefits, nor to any other entry sitiuations
that provoke the inclusion in the reference population of the MCVL. The code 81 is 
frequently used in data cleansing. In later versions of the MCVL, there are 100.000 relations, 
corresponding to 19.000 individuals that were in versions 2004 and 2005 with this exit code key,
which exclusively referred to health benefits. We thus proceed to eliminate these episodes:

NOTA: Las ediciones 2004 y 2005 registraron, en la tabla de afiliación, un número
considerable de episodios de alta en cuentas convencionales que no corresponden a
situaciones de alta laboral, ni de percepción de subsidio por desempleo, ni a otras
situaciones de alta que den lugar a la inclusión en la población de referencia de la
MCVL. La clave 81 se utiliza con frecuencia en depuraciones de datos. En las MCVLs
posteriores a 2005, no se incluyen 100.000 relaciones, correspondientes a
19.000 personas, que figuraban en las ediciones de 2004 y 2005 con esta causa de baja, 
que se referían exclusivamente a prestaciones sanitarias.
*/
drop if MCVL_WO==2005 & bajadate==19980531 & bajareason==81

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
order pid firm_cc2 altayear bajayear alta baja, first

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
save IndividualsAffiliated`j'_`i', replace



/* ==========================================================================
5) LOOP by cohort: Slice up the file "IndividualsBases" into smaller files 
=============================================================================*/
use "{path}\cohorts_2018\IndividualsBases`j'OK.dta" if yearbirth==`i', clear 
save "{path}\cohorts_2018\IndividualsBases`j'_`i'.dta", replace

 
/* ==========================================================================
6) LOOP by cohort: Merge modified "IndividualsAffiliated" 
+ modified "IndividualsBases"
=============================================================================*/
use "{path}\cohorts_2018\IndividualsAffiliated`j'_`i'.dta", clear 
merge m:1 pid firm_cc2 year using "{path}\cohorts_2018\IndividualsBases`j'_`i'.dta", generate(_mergeBasesM)
  
  
  /*OJO con _mergeBasesM, no debemos borrar las observaciones de episodios de afiliación que no
tienen bases de cotización asociadas (_merge==1), especialmente si se corresponden con periodos de
afiliación comprendidos, en total o en parte, antes de junio de 1980.
Debemos guardar esa info (ver 4.ReshapeData) antes de eliminar las observaciones: */

/*NOTE: _mergeBasesM deserves some attention. We should not erase the observations that correspond with 
 affiliation episodes without associated contribution bases, especially if these episodes took place, totally or
 in part, before June 1980. We should keep this info (see 4_ReshapeData20##.do) before deleting any observation. */

tab _mergeBasesM, m 
label var _mergeBasesM "MERGE IndividualsAffiliated using IndividualsBases"
drop if _mergeBasesM==2 
gen dummy = (year<altayear | year>bajayear)
tab dummy /*There should be no 1s*/
drop dummy totalcontribution 
capture drop contributiontot


/* NOTA: para una misma combinación de [pid]+[año de contribución]+[CCC2], la base de cotización será la misma
INCLUSO AUNQUE haya varios episodios de afiliación (distintas fechas de alta/baja) para esa misma 
combinación de [pid]+[año de contribución]+[CCC2] */

/* CAVEAT: for the same combination of pid+contributionyear+firm_cc2, the contribution base will be the same
EVEN IF there are several affiliation episodes (different entry/exit date) for that same combination of 
pid+contributionyear+firm_cc2 */

order pid firm_cc2 year alta baja , first
sort pid year alta baja firm_cc2
drop altayear bajayear

qui compress 

save "{path}\cohorts_2018\IndividualsBasesM`j'_`i'.dta", replace

}
*
}
*

timer off 4
timer list 4

 
