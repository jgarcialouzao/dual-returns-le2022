
version 14

clear all

capture log close

set more off

timer clear 9
timer on 9

*****************************************************************************
*****************************************************************************
********************** STEP 6: Añadir datos fiscales ************************
*****************************************************************************
*****************************************************************************

/* ==========================================================================
1) De toda la tabla de datos fiscales, sólo nos quedamos con las variables
de salario, y con las que usaremos para hacer el merge (pid-empresa-year).
Esto lo hacemos para cada una de las versiones de la MCVL, de manera que tendremos
datos fiscales únicamente desde 2005:
=============================================================================*/
foreach j of numlist 2005/2015 {
use "{path}\cohorts_2018\MCVL`j'FISCAL.dta", clear
keep pid empresa wage especie year
collapse (sum) wage especie (mean) year, by (pid empresa)
sort pid empresa

save "{path}\cohorts_2018\Fiscal`j'.dta", replace
}
***
foreach j of numlist 2016/2016 {
use "{path}\cohorts_2018\MCVL`j'FISCAL.dta", clear
replace wage = wage + amount_il
/* A partir de 2016 dan desglosadas las percepciones derivadas y no derivadas
de IL. 
Las no derivadas de IL también se desglosan en dinerarias (wage) y especie,  
pero las derivadas de IL no se desglosa, es la suma de las dos (amount_il).
Para intentar hacerlo comparable con 2005-2015 sumamos wage + amount_il
*/
keep pid empresa wage especie year
collapse (sum) wage especie (mean) year, by (pid empresa)
sort pid empresa

save "{path}\cohorts_2018\Fiscal`j'.dta", replace
}
***
foreach j of numlist 2017/$v {
use "{path}\cohorts_2018\MCVL`j'FISCAL.dta", clear
replace wage = wage + wage_il
replace especie= especie + especie_il
/*A partir de 2017, la percepción derivada de IL si se divide en dineraria (wage_il)
y especie (especie_il), así que sumamos cada una con lo que corresponde
*/
keep pid empresa wage especie year
collapse (sum) wage especie (mean) year, by (pid empresa)
sort pid empresa

save "{path}\cohorts_2018\Fiscal`j'.dta", replace
}
*

/* ==========================================================================
2) Cargamos los datos fiscales de la última MCVL ("Fiscal${v}"), y 
le appendamos los años anteriores:
=============================================================================*/
use "{path}\cohorts_2018\Fiscal${v}.dta", clear
local last = ${v} - 1 /*Penúltima versión de la MCVL*/
foreach j of num 2005/`last'{
append using "{path}\cohorts_2018\Fiscal`j'.dta"
}
*
save "{path}\cohorts_2018\Fiscal${v}full.dta", replace


/* ==========================================================================
3) Merge datos fiscales con el resto de la MCVL en base a la combinación de pid-
empresa-year. Esta parte sólo afecta a archivos de la última versión de la MCVL
=============================================================================*/
local end   = ${v}-16
local start = ${v}-99
foreach i of num `start'/`end' {
use MCVL${v}_YearMonth_`i', clear
merge m:1 pid empresa year using "{path}\cohorts_2018\Fiscal${v}full.dta", keep(match master)
*drop if _merge==2
drop _merge


/* ==========================================================================
4) Calculamos los dias trabajados al año por pid-empresa, y nos aseguramos de que 
hacemos ese cálculo sólo para aquellas observaciones "matched" con datos fiscales:
=============================================================================*/
bys pid empresa year: egen days_fiscal = total(days) if wage!=. & especie!=.
*Recuerda que "wage" y "especie" están en términos anuales y en céntimos de euro:
gen wage_month = ((wage/100)/days_fiscal)*days
drop wage
rename wage_month wage
label var wage "Percepción integra en euros/mes"
*
gen especie_month = ((especie/100)/days_fiscal)*days
drop especie
rename especie_month especie
label var especie "Percepciones en especie en euros/mes"
*
drop days_fiscal
sort pid time alta baja firm_cc2
save "{path}\cohorts_2018\MCVL${v}_YearMonth_`i'.dta", replace
}
*

timer off 9
timer list 9


