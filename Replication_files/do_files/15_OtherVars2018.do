
version 14

clear all

capture log close

set more off

timer clear 8
timer on 8

cd "${path}\MCVL${v}CDF"

log using "${path}\MCVL${v}CDF\Logs ${v}\5.OtherVariables.smcl", replace



foreach j of numlist 2005/$v { /*LOOP por versión de la MCVL*/

local end   = `j'-16
local start = `j'-99

foreach i of num `start'/`end' { /*LOOP por cohorte*/

cd "${path}\MCVL`j'CDF\Cohortes"
use BasesYearMonth`j'_`i', clear


*****************************************************************************
*****************************************************************************
*********** STEP 5.1: Añadir datos INDIVIDUO + CONVIVIENTES *****************
*****************************************************************************
*****************************************************************************

/* ==========================================================================
1) Incorporamos la información sobre DATOS PERSONALES + CONVIVIENTES
============================================================================*/
merge m:1 pid year using "$path\Common files\IndividualsFULL.dta", update replace ///
keep(match master match_update match_conflict)
*drop if _merge==2
drop _merge expan_num* duplicate* _fillin MCVL_entry															


/* ==========================================================================
2) EDAD (en años no enteros) y edad de entrada al mercado laboral
=============================================================================*/
gen age = (time - ym(yearbirth, month(birthdate)))/12 
label var age "EDAD individuo EN AÑOS no enteros"

bys pid (time): egen entryage_tmp = min(age) if alta!=. & baja!=. 
/* Ponemos esa if-condition para obviar los meses-año sin episodios asociados, que
fueron creados antes (-4 años antes de observar el primer episodio). Lo malo es que
nos quedan "huecos" en aquellas observaciones mes-año sin episodio de afiliación asociado, 
precisamente por esa if-condition. Rellenamos esos missings a continuación (entryage será
por tanto, una constante a lo largo de todas las observaciones de un mismo individuo): */
bys pid (time): egen entryage = max(entryage_tmp)
drop entryage_tmp
label variable entryage "EDAD A LA ENTRADA"
order entryage, after(age)


/* ==========================================================================
3) Edad de los convivientes del individuo
=============================================================================*/
foreach x of numlist 2/10 {
gen birthdate`x' = date(birth`x',"YM")
format birthdate`x' %tdMon.CCYY
label variable birthdate`x' "FECHA DE NACIMIENTO: AÑO + MES, conviviente `x'"
gen yearbirth`x' = year(birthdate`x')
gen age`x' = (time - ym(yearbirth`x', month(birthdate`x')))/12
label var age`x' "EDAD EN AÑOS no enteros, conviviente `x'"
}
*
drop birth? birth10 birthdate? birthdate10 yearbirth? yearbirth10 


/* ==========================================================================
4) Se crean edades negativas (años que quedaban para que naciesen). Sustituimos 
por missing las observaciones para los year-month anteriores a que naciesen:
=============================================================================*/
foreach x of numlist 2/10 {
replace age`x'=. if age`x'<0
}
*


/* ==========================================================================
4A) FAMILY SIZE, basado en la edad de los convivientes
=============================================================================*/

/* 4.1) Cálculo del tamaño total del hogar (changes over time) */
egen tamanno = rownonmiss(age*)
label variable tamanno "Nº real personas conviviendo"
/* 4.2) Edad de los convivientes en números enteros (changes over time) */
foreach x of numlist 2/10 {
gen age`x'_b = round(age`x',1)
}
*

/* 4.3) Cálculo del tamaño entre 0 y 6 años (changes over time) */
gen tamanno_06 = inrange(age2_b,0,6) + inrange(age3_b,0,6) + inrange(age4_b,0,6) ///
 + inrange(age5_b,0,6) + inrange(age6_b,0,6) + inrange(age7_b,0,6) ///
 + inrange(age8_b,0,6) + inrange(age9_b,0,6) + inrange(age10_b,0,6)
*Alternativamente (pero tarda mucho más): egen tamanno_06 = anycount(age?_b age10_b), values(0/6)
label variable tamanno_06 "Nº personas conviviendo entre 0 y 6 años"

/* 4.4) Cálculo del tamaño entre 7 y 15 años (changes over time) */
gen tamanno_715 = inrange(age2_b,7,15) + inrange(age3_b,7,15) + inrange(age4_b,7,15) ///
 + inrange(age5_b,7,15) + inrange(age6_b,7,15) + inrange(age7_b,7,15) ///
 + inrange(age8_b,7,15) + inrange(age9_b,7,15) + inrange(age10_b,7,15)
*Alternativamente (pero tarda mucho más): egen tamanno_715 = anycount(age?_b age10_b), values(7/15)
label variable tamanno_715 "Nº personas conviviendo entre 7 y 15 años"

/* 4.5) Cálculo del tamaño mayor de 65 años (changes over time) */
gen tamanno_m65 = inrange(age2_b,65,105) + inrange(age3_b,65,105) + inrange(age4_b,65,105) ///
 + inrange(age5_b,65,105) + inrange(age6_b,65,105) + inrange(age7_b,65,105) ///
 + inrange(age8_b,65,105) + inrange(age9_b,65,105) + inrange(age10_b,65,105)
*Alternativamente (pero tarda mucho más): egen tamanno_m65 = anycount(age?_b age10_b), values(65/105)
label variable tamanno_m65 "Nº personas conviviendo mayores de 65 años"


/* ==========================================================================
4B)  FAMILY SIZE según sexo de los convivientes. Creamos missings si aún no
ha nacido o si no hay registro de él:
=============================================================================*/
foreach x of numlist 2/10 {
replace sex`x'=. if age`x'==.
}
*
/* 4.6) Cálculo del nº de varones en el hogar*/
egen n_male = anycount(sex sex? sex10), values(1)
label variable n_male "Nº de varones conviviendo"

/* 4.7) Cálculo del nº de mujeres en el hogar*/
egen n_female = anycount(sex sex? sex10), values(2)
label variable n_female "Nº de mujeres conviviendo"

drop age*b age? age10 sex? sex10


*****************************************************************************
*****************************************************************************
********************** STEP 5.2: OTHER VARIABLES   **************************
*****************************************************************************
*****************************************************************************

/* ==========================================================================
1) MÁS DE UN EPISODIO DE AFILIACIÓN POR MES/AÑO ---> "multiple"
=============================================================================*/
bys pid time: gen multiple = (_N>1)
label var multiple "MÁS DE UN EPISODIO DE AFILIACIÓN POR MES/AÑO"
order multiple, after(month)


/* ==========================================================================
2) Tipo de contrato (coherente --> En diciembre de 2000 hubo agrupación de 
claves de contrato (ver Documentación 2014))
=============================================================================*/
gen contractb = contracttype
replace contractb = 100 if inlist(contracttype,1,17,22,49,69,70,71,32,33)
replace contractb = 109 if inlist(contracttype,11,35,101,109)
replace contractb = 130 if inlist(contracttype,9,29,59)
replace contractb = 150 if inlist(contracttype,8,20,28,40,41,42,43,44,45,46,47,48,50,60,61,62,80,86,88,91,150,151,152,153,154,155,156,157)
replace contractb = 200 if inlist(contracttype,3)
replace contractb = 209 if inlist(contracttype,38,102,209)
*replace contractb = 230 if inlist(contracttype,9,29,59)
replace contractb = 250 if inlist(contracttype,63,81,89,98,250,251,252,253,254,255,256,257)
replace contractb = 300 if inlist(contracttype,18)
replace contractb = 309 if inlist(contracttype,185,186,309)
replace contractb = 350 if inlist(contracttype,181,182,183,184,350,351,352,353,354,355,356,357)
replace contractb = 401 if inlist(contracttype,14)
replace contractb = 402 if inlist(contracttype,15)
replace contractb = 410 if inlist(contracttype,16,72,82,92,75)
replace contractb = 420 if inlist(contracttype,58,96)
replace contractb = 421 if inlist(contracttype,85,87,97)
replace contractb = 430 if inlist(contracttype,30,31)
replace contractb = 441 if inlist(contracttype,5)
replace contractb = 450 if inlist(contracttype,457)
replace contractb = 500 if inlist(contracttype,4)
*replace contractb = 501 if inlist(contracttype,14)
*replace contractb = 502 if inlist(contracttype,15)
replace contractb = 510 if inlist(contracttype,73,83,93,76)
replace contractb = 520 if inlist(contracttype,6)
replace contractb = 540 if inlist(contracttype,34)
*replace contractb = 541 if inlist(contracttype,5)
replace contractb = 550 if inlist(contracttype,557)
label var contractb "TIPO DE CONTRATO DE TRABAJO (COHERENTE)"
label values contractb contracttype

*Posibles datos incongruentes: 
/*Actualizar la siguiente lista con cada MCVL; mirar tabla de claves de contrato vigentes en guía
gen no_extinguidos = 1 if inlist(contractb,0,100,109,130,139,150,189,200,209,230, ///
239,250,289,300,309,330,339,350,389,401,402,403,408,410,418,420,421,430,441,450, ///
501,502,503,508,510,518,520,530,540,541,550,552,990)==0
label var no_extinguidos "=1 si clave de contrato está vigente actualmente"
*/

/* ==========================================================================
3) PERMANENT vs TEMPORARY contracts
=============================================================================*/
*Contratos indefinidos (según su descripción/label):
gen permanent = 1 if inlist(contractb,23,65,100,109,130,131,139,141,150,189,200, ///
209,230,231,239,250,289,300,309,330,331,339,350,389)
*Contratos temporales (según su descripción/label):
replace permanent = 0 if inlist(contractb,7,10,12,13,24,26,27,36,37,53,54,55,56, ///
57,64,66,67,68,74,77,78,79,84,94,401,402,403,408,410,418,420,421,430,431,441,450, ///
451,452,500,501,502,503,508,510,518,520,530,531,541,550,551,552)
*Contratos en los que no queda claro si son indefinidos o temporales:
replace permanent = . if inlist(contractb,25,19,39,51,52,90,95,540,990)
label var permanent "=1 si contrato indefinido"


/* ==========================================================================
4) PART-TIME vs FULL-TIME contracts
=============================================================================*/
*Contratos a tiempo parcial (según su descripción/label):
gen parttime = 1 if inlist(contractb,23,24,25,26,27,64,65,84,95,200,209,230,231, ///
239,241,250,289,500,501,502,503,508,510,518,520,530,531,540,541,550,551,552)
replace parttime = 0 if parttimecoef==0
replace parttime = 1 if parttimecoef!=0 & parttimecoef!=.
label var parttime "=1 si contrato a tiempo parcial"


/* ==========================================================================
5) Identificar a los topados (base de cotización por encima del máximo legal).
=============================================================================*/
merge m:1 group year month using "$path\Common files\bounds.dta", generate(_mergebounds) keep(match master)
*drop if _mergebounds==2
drop _mergebounds
label var min_base "Base mín. de cotización según grupo y año"
label var max_base "Base máx. de cotización según grupo y año"

/*NOTA: los topes tendrán missings en aquellas observaciones en las que:
1) La variable "group" (grupo de cotización) sea missing o cero ("No consta")
2) Combinación de mes-año distinta a 01/1980 - 12/2015*/

gen topados = (inc>=0.995*max_base) if inc!=. & max_base!=.  /*Stata treats missings as suuuperbig numbers*/
label var topados "Base cotización > max. legal"
/*NOTA: ahora en el 0 tenemos a observaciones con inc == ., pero esas no las queremos en el cómputo
de "no topados":

Razones por las que inc==. :
1) No hay datos de afiliación disponibles (no hay fecha de alta o baja, por ejemplo)
2) Hay datos de afiliación, pero cotiza en el régimen de autónomos.
3) No hay base de cotización asociada para esa combinación de mes-año-cc2-pid (es decir, _mergeBases!=3)
3) No hay bases de cotización antes de 1980. */
replace topados = . if inc==.

*** Excluidos del cómputo (tanto en "topados" como en "no topados"):
*Personas que no estén trabajando (i.e., cobrando prestación o subsidio por desempleo):
replace topados = . if TRL==751 | TRL==752 | TRL==753 | TRL==755 | TRL==756
*Trabajadores a tiempo parcial:
replace topados = . if parttimecoef!=0 & parttimecoef!=.
*Trabajadores que no trabajen el mes al completo (30 días):
replace topados = . if days!=30
*Bases de cotización por debajo del mínimo (a pesar de lo anterior, y que por tanto, son errores):
replace topados = . if inc<=0.995*min_base & min_base!=. /*Stata treats missings as suuuperbig numbers*/

/* ==========================================================================
6) Antigüedad de un individuo en una empresa, para cada contrato.
=============================================================================*/
bys pid firm_cc2 alta baja (time): gen tenure = sum(days) if days!=.
label var tenure "ANTIGÜEDAD en DÍAS de un individuo en una empresa, por contrato"
order tenure, after(days)


*****************************************************************************
*****************************************************************************
****************** STEP 5.3: Actualizar datos firm_cc2  *********************
*****************************************************************************
*****************************************************************************

/* ==========================================================================
1) FIRM-LEVEL variables
=============================================================================*/
* 1.1) Limpiamos employertype:
qui destring employertype, replace force
qui replace employertype=0 if employertype==.

* 1.2) Limpiamos firmtype:
qui replace firmtype="" if firmtype!="A" & firmtype!="B" & firmtype!="C" & ///
firmtype!="D" & firmtype!="E" & firmtype!="F" & firmtype!="G" & firmtype!="H" & ///
firmtype!="J" & firmtype!="N" & firmtype!="P" & firmtype!="Q" & firmtype!="R" & ///
firmtype!="S" & firmtype!="U" & firmtype!="V" & firmtype!="W"
/*firmtype solo tiene sentido cuando employertype==9*/

* 1.3) Update info de olas pasadas:
cd "${path}\MCVL${v}CDF"
merge m:1 firm_cc2 year using "$path\Common files\FirmsFULL.dta", update replace keep(match master match_update match_conflict) ///
keepusing(faddress2 factivity09 fsize altadate1staffiliated ETT employertype firmtype faddress factivity93) 
*drop if _merge==2
drop _merge

* 1.4) FIRM TENURE (CCC)
tostring altadate1staffiliated, replace
gen alta_firm = date(altadate1staffiliated, "YMD")
format alta_firm %tdDD.Mon.CCYY
label var alta_firm "FECHA REAL DEL ALTA DEL PRIMER TRABAJADOR DE UN CCC"
order alta_firm, after(altadate1staffiliated)
drop altadate1staffiliated

gen firm_age = (time - ym(year(alta_firm),month(alta_firm)))/12
replace firm_age = . if firm_age <0
label variable firm_age "ANTIGÜEDAD EMPRESA (EN AÑOS)"
order firm_age, after(alta_firm)



*****************************************************************************
*****************************************************************************
****************** STEP 5.4: Individuos de olas pasadas  ********************
*****************************************************************************
*****************************************************************************

/* ==========================================================================
1) Cohorte a cohorte, añadimos a individuos observados por última vez en versiones 
anteriores de la MCVL. Esta parte sólo afecta a los archivos "MCVL${v}_YearMonth_####"
de la última versión de la MCVL:
=============================================================================*/
local last = $v - 1 /*Penúltima versión de la MCVL*/
if `j'==$v {
foreach t of num 2005/`last'{
cd "${path}\MCVL`t'CDF\Cohortes"
capture append using MCVL`t'_YearMonth_`i'
}
*
}
*
*************************
*************************
cd "${path}\MCVL`j'CDF\Cohortes"
sort pid time
save MCVL`j'_YearMonth_`i', replace
}
*
}
*

/* ==========================================================================
2) Añadiremos al archivo de la primera cohorte de la última versión de la MCVL
("MCVL${v}_YearMonth_`start'") la info de individuos que se observaron por última
vez en versiones anteriores de la MCVL pero que pertecenen a cohortes de nacimiento
anteriores a la primera de referencia de la última versión de la MCVL.
=============================================================================*/
cd "${path}\MCVL${v}CDF\Cohortes"
local z = $v - 99 /*Con esto nos referimos a la primera cohorte de la MCVL más reciente*/
use MCVL${v}_YearMonth_`z', clear

*Ejemplo: para la MCVL2014, las cohortes <1915 no entrarán en el loop.Entonces
*añadimos en un loop aparte a los individuos de 1906(start_b)-1914(end_b):
local last = $v - 1 /* Con esto nos referimos a la penúltima versión de la MCVL*/
local end_b   = $v - 99 - 1 /* =1914 */
local start_b = 2005 - 99 /* =1906, Primera cohorte que tenemos desde la MCVL2005*/
foreach t of num 2005/`last'{
foreach s of num `start_b'/`end_b' { 
cd "${path}\MCVL`t'CDF\Cohortes"
capture append using MCVL`t'_YearMonth_`s'
}
}
*
cd "${path}\MCVL${v}CDF\Cohortes"
save MCVL${v}_YearMonth_`z', replace


timer off 8
timer list 8

cd "${path}\MCVL${v}CDF\Logs ${v}"
log close
