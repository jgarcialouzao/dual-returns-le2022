
version 14

clear all

capture log close

set more off

timer clear 7
timer on 7


*****************************************************************************
*****************************************************************************
********************** STEP 4: RESHAPE monthly data  ************************
*****************************************************************************
*****************************************************************************


foreach j of numlist 2005/$v { /*LOOP por versión de la MCVL*/

local end   = `j'-16
local start = `j'-99

foreach i of num `start'/`end' { /*LOOP por cohorte, si fuese necesario*/
use "{path}\cohorts_2018\IndividualsDaysM`j'_`i'.dta", clear


/* ==========================================================================
1) Creamos una especie de "id" que identifique a cada observación unívocamente 
para el reshape.
=============================================================================*/
sort pid year firm_cc2 alta baja
gen count = _n

reshape long days inc incaut, i(count)

rename _j month
label var month "MES"
label var days "DIAS COTIZADOS (TRABAJO O PRESTACION)"
replace inc = inc/100
label var inc "BASE DE COTIZACION POR CONTINGENCIAS COMUNES en EUROS"
replace incaut = incaut/100
label var incaut "BASE DE COTIZACION AUTONOMOS Y OTROS en EUROS"

order pid year month alta baja firm_cc2, first
sort pid year month alta baja firm_cc2
drop if days==.
drop count


/* ==========================================================================
2) Rectangularizamos la base
=============================================================================*/
gen time =  ym(year, month)
label var time "AÑO-MES DE COTIZACIÓN"
order time, after(month)
format time %tmMon.CCYY

/* 2.1) Guardamos en una variable las fechas en las que observamos por primera 
y última vez a cada individuo, y aquella en la que cumple 16 años: */
bys pid (time alta baja firm_cc2): egen start = min(time) /* Primer Mes-Año en el que el individuo tiene un episodio de afiliación activo */
label var start "AÑO-MES DE ENTRADA al MERCADO"
bys pid (time alta baja firm_cc2): egen end = max(time) /* Último Mes-Año en el que el individuo tiene un episodio de afiliación activo */
label var end "AÑO-MES DE SALIDA del MERCADO"
format start end %tmMon.CCYY /* Formato fecha mensual */
by pid: gen d16 = ym(yearbirth, month(birthdate)) + 16*12 /*Mes-Año desde el que está en edad de trabajar (16 años)*/


/* 2.2) Rectangulariza la base de datos añadiendo todas las combinaciones posibles de pid-time, 
lo que implica que va a haber muchos missings (filas con dato solo en pid y time).*/

/* Esta parte sólo va a ser necesaria para los individuos que aparecen por última vez en olas anteriores.
El problema viene porque para los individuos rescatados de, por ejemplo, la MCVL de 2010, el máximo de la
variable time será Dec.2010/Dec.2011(*), y por tanto, como fillin crea observaciones 
por combinacion de [todos los posibles valores de pid] y [todos los posibles valores de time], 
no se crearán esos 4 años hacia delante como queríamos, si no que se quedaría en la frontera de
Dec.2011. Vamos a solucionar eso, creando más valores de la variable time, para así tener más combinaciones.

(*) Se trataría de contratos vigentes en la fecha de extracción de la MCVL de 2010 y tendrán 
esa fecha de baja, aunque teoricamente esto no debería ocurrir, ya que se supone que 
entonces el individuo debería aparecer en la siguiente ola...Esto afecta en su mayoría a 
extranjeros que cambian de identificador y dejan de pertenecer a la Muestra por culpa de eso. */


foreach AAAA of numlist 2006/$v {
foreach MM of numlist 1/12{
qui set obs `=_N+1' /*Primero se crea una fila más vacía al final*/
qui replace time = ym(`AAAA', `MM') in `=_N' /*Todo será missing, a excepción de la variable time*/
}
}
*

/* Creamos toda posible combinación de pid-time */
fillin pid time 
drop _fillin
drop if pid == . /*Por las obs. creadas antes con dato solo en time*/

/* ==========================================================================
3) Nos vamos a quedar solo con +(-) 4 años hacia delante y hacia atrás después(antes) 
de observar al individuo en afiliación. Para ello usaremos el dato de la fecha en la 
que le observamos por primera vez ("start") y por última ("end"). Debemos llevar 
ese dato a lo largo de todas las observaciones disponibles de pid (recuerda que 
habrá muchos missings porque acabamos de rectangularizar la base de datos.
=============================================================================*/
*****METHOD #1*****
bys pid (time): carryforward start end d16, replace /*Hacia delante, primero*/
gen negtime = -time /*Lo usamos para rellenar missings HACIA ATRÁS cambiando el sorting de la variable tiempo*/
bys pid (negtime): carryforward start end d16, replace /*Hacia atrás, segundo*/
drop negtime
*Eliminamos observaciones creadas 4 años antes del periodo de observación de cada individuo:
by pid: gen d1 = (time < (max((start - 4*12), d16))) /*Identificamos observaciones en las que 
el mes-año es anterior a los 4 años anteriores a que le observemos por primera vez, o a que tenga 16 años si esta 
fuese una fecha posterior. Como vamos a eliminar los d1==1, en el d1==0 nos deberían quedar observaciones correspondientes
a mes-año (time) de los 4 años anteriores al primer episodio de afiliación de esa persona, siempre que la persona tenga 16 o más años*/
drop if d1==1

*Eliminamos observaciones creadas 4 años después del periodo de observación de cada individuo:
by pid: gen d2 = (time > min((end + 4*12), ym(${v},12))) /*Identificamos observaciones en las que 
el mes-año es posterior a los 4 años siguientes a que le observemos por última vez, o a 31/12/AÑOMCVL si esta 
fuese una fecha anterior. Como vamos a eliminar los d1==1, en el d1==0 nos deberían quedar observaciones correspondientes
a mes-año (time) de los 4 años posteriores al último episodio de afiliación de esa persona, pero usando el 31/12 del año de 
la MCVL como tope*/
drop if d2==1
drop d16 d1 d2
*****METHOD #1*****


*****METHOD #2*****
/* Otra forma de hacerlo (pero mucho menos eficiente y time-consuming):
by pid: egen start2 = min(start) /*Es lo mismo que start solo que rellena los missings creados por fillin*/
by pid: egen end2 = min(end) /*Es lo mismo que end solo que rellena los missings creados por fillin*/
by pid: egen d16_b = min(d16) /*Es lo mismo que d16 solo que rellena los missings creados por fillin*/
by pid: gen d1 = (time < (max((start2 - 4*12), d16_b)))
by pid: gen d2 = (time > min((end2 + 4*12), ym(${v},12)))
drop if d1==1
drop if d2==1 

drop start end d16 d16_b _fillin d1 d2
rename start2 start
label var start "AÑO-MES DE ENTRADA al MERCADO"
rename end2 end
label var end "AÑO-MES DE SALIDA del MERCADO"
format start end %tmMon.CCYY */
*****METHOD #2*****


/* =============================================================================
4) Sustituimos missings creados en year y month en los "huecos" del panel que
hemos rellenado.
============================================================================= */
replace year = year(dofm(time)) if year==.
replace month = month(dofm(time)) if month==.
sort pid time alta baja firm_cc2


/* ==========================================================================
5) MODIFICACIONES DE CONTRATO
=============================================================================*/
gen newcdate1=mofd(date(newcontractdate1,"YMD")+2) /*Añadimos 2 días, por si
la fecha de cambio del contrato fue a finales de mes, para que salga el cambio 
en el inicio del mes siguiente. Recuerda que newcontractdate1 está en días (fecha exacta)
pero que nosotros trabajamos con time (en meses).*/
gen newcdate2=mofd(date(newcontractdate2,"YMD")+2)
gen newgdate=mofd(date(newcontributiongroupdate,"YMD")+2)
format newcdate1 newcdate2 newgdate %tmMon.CCYY
*Tipo de contrato
destring prevcontracttype1 prevcontracttype2, replace
replace contracttype = prevcontracttype1 if time<=newcdate1 & prevcontracttype1!=.
replace contracttype = prevcontracttype2 if time>newcdate1 & time<=newcdate2 & prevcontracttype2!=.
drop prevcontracttype1 prevcontracttype2 
*Coeficiente de parcialidad
destring prevparttimecoef1 prevparttimecoef2, replace
replace parttimecoef = prevparttimecoef1 if time<=newcdate1 & prevparttimecoef1!=.
replace parttimecoef = prevparttimecoef2 if time>newcdate1 & time<=newcdate2 & prevparttimecoef2!=.
drop prevparttimecoef1 prevparttimecoef2 newcdate1 newcdate2
*Grupo de cotización:
destring prevcontributiongroup, replace
replace group = prevcontributiongroup if time<=newgdate & prevcontributiongroup!=.
drop prevcontributiongroup newgdate


order pid time year month alta baja firm_cc2, first
sort pid time alta baja

save "{path}\cohorts_2018\BasesYearMonth`j'_`i'", replace
}
*
}
*

timer off 7
timer list 7



