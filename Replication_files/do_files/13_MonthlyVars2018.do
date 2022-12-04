
version 14

clear all

capture log close

set more off

timer clear 6
timer on 6


**************************************************************************
**************************************************************************
****** STEP 3: Monthly Information (Detalle por CCC2)  *******************
**************************************************************************
************************************************************************** 

foreach j of numlist 2005/$v {   /*LOOP por versión de la MCVL*/

local end   = `j'-16
local start = `j'-99

foreach i of num `start'/`end' { /*LOOP por cohorte, si fuese necesario*/

use "{path}\cohorts_2018\IndividualsBasesM`j'_`i'.dta", clear


sort pid year firm_cc2 alta baja

/* RECUERDA: para una misma combinación de [pid]+[año de contribución]+[CCC2], 
la base de cotización será la misma INCLUSO AUNQUE haya varios episodios 
de afiliación (distintas fechas de alta/baja) para esa misma combinación 
de [pid]+[año de contribución]+[CCC2] */


/* ==========================================================================
* DIAS TRABAJADOS POR MES/AÑO
=========================================================================== */
sort pid year alta baja firm_cc2
foreach x of numlist 1/12 {

/* Meses trabajados por entero */
gen days`x'=30 if ( (year>year(alta) & year<year(baja)) | /// 
(year==year(alta) & year==year(baja) & `x'<month(baja) & `x'>month(alta)) | ///
(year==year(alta) & year!=year(baja) & `x'>month(alta)) | ///
(year==year(baja) & year!=year(alta) & `x'<month(baja)) ) 


/* Meses de alta, no enteros */

/* [mdy(month(alta)+1,1,year(alta))-1] se refiere al último día del mes en el que se produjo el alta, 
es decir, es como si calculásemos [1/11/2000 - 1día] para referirnos al 31/10/2000. Añadimos +1 porque
el día de alta también cuenta como trabajado. Así se calculan correctamente los días trabajados en el primer mes. 
Por ejemplo, si empezó el 14 de febrero de 1995, los días trabajados en feb1995 serían 28-14+1=15.
Si empezó el 28 de febrero de 1995, los días trabajados en feb1995 serían 28-28+1=1
STATA también tiene en cuenta si el año era bisiesto. Por ejemplo, si el alta se produjo 
el 14 de febrero de 1996, los días trabajados en feb1996 serían 29-14+1=16. 
Igualmente STATA tiene en cuenta si el mes tiene 30 o 31 días. */
replace days`x'= cond(month(alta)!=12, mdy(month(alta)+1,1,year(alta))-1-alta+1, mdy(month(alta)-11,1,year(alta)+1)-1-alta+1)  if year==year(alta) & month(alta)==`x'
*
/*Meses de baja, no enteros*/
replace days`x'= day(baja) if year==year(baja) & month(baja)==`x'

/*El episodio de afiliación empieza y acaba en el mismo mes*/
replace days`x'= day(baja) - day(alta)+1 if year==year(baja) & month(baja)==`x' & year==year(alta) & month(alta)==`x'

/*Ajuste mensual a 30 días*/
replace days`x'= 30 if days`x'==31 

/*Fecha de alta = fecha de baja ==> 1 día cotizado*/
replace days`x'= 1 if baja==alta & month(baja)==`x' & month(alta)==`x'
label var days`x' "DÍAS TRABAJADOS MES `x'"			
}
*
/*Para contratos que empiecen el 01.Feb y acaben en otro mes, se les habrá puesto 28/29 días trabajados, 
pero lo correcto sería que fuesen 30:*/
replace days2 = 30 if alta==mdy(2,1,year) & (year!=year(baja) | month(baja)!=2) 
/*Para contratos que acaben el 28.Feb/29.Feb y hayan empezado en otro mes, se les habrá puesto 28/29 días trabajados, 
pero lo correcto sería que fuesen 30:*/
replace days2 = 30 if baja==mdy(2,28,year) & (year!=year(alta) | month(alta)!=2)
replace days2 = 30 if baja==mdy(2,29,year) & (year!=year(alta) | month(alta)!=2)
/*Para contratos que empiecen el 01.Feb y acaben el 28.Feb/29.Feb del mismo mes, se les habrá puesto 28/29 días trabajados, 
pero lo correcto sería que fuesen 30:*/
replace days2 = 30 if alta==mdy(2,1,year) & baja==mdy(2,28,year)
replace days2 = 30 if alta==mdy(2,1,year) & baja==mdy(2,29,year)
order days* inc? inc?? incaut? incaut?? , after(baja)

save "{path}\cohorts_2018\IndividualsDaysM`j'_`i'.dta", replace
}
*

}
*

timer off 6
timer list 6





