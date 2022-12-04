
version 14

clear all

capture log close

set more off

timer clear 3
timer on 3


********************************************************************************
********************************************************************************
*******************     INDIVIDUOS - CARACTERÍSTICAS     ***********************
********************************************************************************
********************************************************************************

/* ==========================================================================
1) Creamos un fichero por cada MCVL, con la info de los individuos para ese año:
=========================================================================== */
foreach j of num 2005/$v {
use "{path}\cohorts_2018\MCVL`j'PERSONAL.dta", clear


/* ==========================================================================
2) MERGE Personal + Convivir. Matching in terms of pid 
=============================================================================*/
merge 1:1 pid using "{path}\cohorts_2018\MCVL`j'CONVIVIR.dta"

tab _merge, m
drop if _merge==2
drop _merge


/* ==========================================================================
3) SEX
=============================================================================*/
qui destring sex*, replace
label define sex 1"Hombre" 2"Mujer"
label values sex sex



/* ==========================================================================
4) NACIONALITY
=============================================================================*/
destring nationality, replace ignore("N")
replace nationality=. if nationality==99
label variable nationality "NACIONALIDAD DE LA PERSONA"

destring country, replace ignore("N")
qui replace country=. if country==99
label variable country "PAIS DE NACIMIENTO DE LA PERSONA"
replace country=nationality if country==.
qui compress
label define country 0"España" 1"Alemania" 3"Argentina" 4"Bulgaria" 5"China" /// 
6"Colombia" 7"Cuba" 8"Rep.Dominicana" 9"Ecuador" 10"Francia" 11"Italia" ///
12"Marruecos" 13"Perú" 14"Polonia" 15"Portugal" 16"Reino Unido" 17"Rumania" ///
18"Ucrania" 19"Resto UE15" 20"Resto UE25" 21"Otros Europa" 22"Otros Sud y Centroamerica" ///
23"Otros África" 24"Otros Asia y Pacífico" 25"Norteamérica" 26"Bolivia" 27"Brasil"

label values country country
label values nationality country


/* ==========================================================================
5) EDUCATION LEVEL
=============================================================================*/
tab education
gen educa = education
destring educa, replace force

qui replace educa=10 if (education=="10"|education=="11")
qui replace educa=20 if (education=="20"|education=="21"|education=="22")
qui replace educa=30 if (education=="30"|education=="31"|education=="32")
qui replace educa=40 if (education=="40"|education=="41"|education=="42")
qui replace educa=50 if (education=="43"|education=="44"|education=="45")
qui replace educa=60 if (education=="46"|education=="47")
qui replace educa=70 if (education=="48")
replace educa=. if education=="00"
replace educa=. if education=="99"
replace educa=. if ( educa!=10 & educa!=20 & educa!=30 & educa!=40 & educa!=50 & educa!=60 & educa!=70 )

drop education
rename educa education
label variable education "NIVEL EDUCATIVO"
label define education 10"No sabe leer ni escribir" 20"Titulación inferior a graduado escolar" ///
30"Graduado escolar o equivalente" 40"Bachiller o Formación Profesional 2ºgrado" ///
50"Diplomado, Técnico u otra titulación media" 60"Licenciado o Graduado Universitario" ///
70"Máster, Doctorado o estudios de postgrado"
label values education education


/* ==========================================================================
6) Creamos la variable "year" y nos quedamos con una observacion por individuo
(es solo un check, porque en realidad, deberíamos tener solo una obs por individuo)
=========================================================================== */
gen year = `j'
label variable year "AÑO DE COTIZACION"
sort pid birth sex nationality province
egen tagid=tag(pid)
keep if tagid==1 /*Eliminamos duplicados de individuos*/
drop tagid
qui compress 

save "{path}\cohorts_2018\MCVL`j'PERSONALfull.dta", replace
}
*


********************************************************************************
********************************************************************************
*********************     INDIVIDUOS - formato PANEL     ***********************
********************************************************************************
********************************************************************************

/* ==========================================================================
7) Unimos todos los años para tener un panel pid-año:
=========================================================================== */
use "{path}\cohorts_2018\MCVL${v}PERSONALfull.dta", clear

local z = $v - 1
foreach j of num 2005/`z' {
append using "{path}\cohorts_2018\MCVL`j'PERSONALfull.dta"
}
*
tab year MCVL_WO
drop MCVL_WO /*Debería coincidir con year, pero ya no tiene el significado 
que queremos. Volvemos a crearla*/

bys pid: egen MCVL_WO = max(year) /*Última MCVL en la que aparece el individuo*/
bys pid: egen MCVL_entry = min(year) /*Primer MCVL en la que aparece el individuo*/

tab MCVL_WO if year==MCVL_WO /*Nº de individuos segun la ultima ola en la que aparecen*/

/*Guardamos aquí toda la INFORMACION ORIGINAL, sin limpiezas ni rellenar missings:*/
save "{path}\cohorts_2018\IndividualsFULL_original.dta", replace



/* ==========================================================================
8) Depuración individuos (según fechas de nacimiento)
=========================================================================== */

/* 8.1) Tiramos a individuos que cambien de fecha de nacimiento a lo largo de
las distintas ediciones de la MCVL */
gen birthdate = date(birth,"YM")
format birthdate %tdMon.CCYY
label variable birthdate "FECHA DE NACIMIENTO: AÑO + MES"
drop birth

bys pid: gen tag = _n
bys pid: egen sd_birth = sd(birthdate)
count if tag==1
count if sd_birth!=0 & sd_birth!=. & tag==1 /*Para saber el nº de individuos que vamos a tirar*/
drop if sd_birth!=0 & sd_birth!=. /*sd_birth es constante por individuo, luego tiramos todas las obs. del individuo*/
drop sd_birth

/* 8.2) Tiramos a individuos cuya fecha de nacimiento no esté disponible en ninguna
de las ediciones de la MCVL: */

*Primero nos aseguramos de que rellenamos los missings con datos posteriores:
bys pid (birthdate): replace birthdate = birthdate[1] /* Este sorting va a dejar abajo 
las observaciones del individuo con missing en la variable birthdate. */

*Cuando aun habiendo hecho lo anterior, la variable sigue siendo missing, lo tiramos:
count if tag==1
count if birthdate==. & tag==1 /*Para saber el nº de individuos que vamos a tirar*/
drop if birthdate==.
drop tag 

sort pid year
tab MCVL_WO if year==MCVL_WO /*Nº individuos por ola (la última en la que aparecen)*/


/* ==========================================================================
9) Rectangularizamos el panel, y si hay huecos rellenamos con la información 
disponible e inmediatamente anterior.
=========================================================================== */
fillin pid year
rename MCVL_WO MCVL_tmp
bys pid (year): egen MCVL_WO = max(MCVL_tmp) /*Para rellenar missings en la MCVL_WO
creados por fillin. Ahora MCVL_WO es constante por individuo */
label variable MCVL_WO "MUESTRA DE ORIGEN"
drop MCVL_tmp

rename MCVL_entry MCVL_tmp
bys pid (year): egen MCVL_entry = max(MCVL_tmp) /*Para rellenar missings en la MCVL_entry
creados por fillin. Ahora MCVL_entry es constante por individuo */
label variable MCVL_entry "Primera MCVL en la que le observo"
drop MCVL_tmp

/*Nos quedamos solo con los años entre la primera vez que le observo (MCVL_entry) 
y la última (MCVL_WO). Los otros años han sido creados artificialmente por "fillin"*/
drop if year > MCVL_WO 
drop if year < MCVL_entry


/*Rellenamos los huecos creados por fillin entre ambos años (gente que sale y entra 
de la muestra) con la info del año inmediatamente anterior.*/

ds pid year MCVL_WO MCVL_entry _fillin, not
foreach var of varlist `r(varlist)' { 
bys pid (year): replace `var' = `var'[_n-1] if _fillin == 1 
}
*

/*IMPORTANTE: es posible que veamos missings en las anteriores variables si es así 
como venian en el dato original. Únicamente rellenamos missings de los años creados
"artificialmente" para rellenar huecos en el panel. E incluso, se puede dar la 
posibilidad de haber rellenado con missings esos años creados artificialmente si
el último dato de la MCVL inmediantamente anterior tambien fuese missing originalmente. */



/* ==========================================================================
10) Nos aseguramos de que los datos del individuo que deberían de ser invariables
en el tiempo, sean constantes a lo largo de toda la historia del individuo, y 
aprovechamos para rellenar posibles missings en esas variables.
DEJAMOS EL DATO DE LA MCVL MÁS RECIENTE EN LA QUE EL DATO ESTÉ DISPONIBLE 
=========================================================================== */

/* 10.1) Para las siguientes variables el cero es equiparable a un missing*/
foreach var of varlist sex province provinceaf {
gen negyear = -year
replace negyear = . if `var'==. | `var'==0
bys pid (negyear): replace `var' = `var'[1] /* Dejamos el dato más reciente disponible. 
Con este sorting tendremos en la primera observacion de cada individuo el dato del 
año más reciente siempre que la variable esté disponible*/
drop negyear
}
*

/* 10.2) Para las variables country y death, el cero tiene un valor, no es un missing*/
foreach var of varlist country death {
gen negyear = -year
replace negyear = . if `var'==. 
bys pid (negyear): replace `var' = `var'[1] /* Dejamos el dato más reciente disponible. 
Con este sorting tendremos en la primera observacion de cada individuo en dato del 
año más reciente siempre que la variable esté disponible*/
drop negyear
}
*


/* ==========================================================================
11 Creamos tantas filas como años haya desde que el individuo tiene 16 años 
hasta que le observo por primera vez:
=============================================================================*/
sort pid year

gen yearbirth = year(birthdate)
label var yearbirth "COHORTE"
order yearbirth birthdate, after(pid)

gen d16 = yearbirth + 16 /*Año en que cumple los 16*/
*browse if d16>2005 /*Gente que cumple los 16 después de 2005*/

gen expan_numA = MCVL_entry - d16 + 1 if year==MCVL_entry & year!=MCVL_WO /* Los datos del individuo
se va a remontar como mucho hasta la edad en que cumple 16 años. Si se trata de un
chaval que cumplirá los 16 en año posterior a su MCVL_entry, expan_num será negativo
y el comando expan lo ignorará (no creará observaciones duplicadas). */

gen expan_numB = min($v - MCVL_WO + 1, 4 + 1) if year==MCVL_WO & year!=MCVL_entry/*En los siguientes do-files vamos a crear
+ 4 años de observaciones para el individuo desde la ultima vez que le observo, 
con el limite del año al que se refiere la última edición de la MCVL ($v). 
Duplicaremos las observaciones con la info personal de la última edicion de la MCVL
en la que aparezca el individuo. */

gen expan_numC = MCVL_entry - d16 + min($v - MCVL_WO + 1, 4 + 1) if year==MCVL_entry & year==MCVL_WO

expand expan_numA, gen(duplicateA)
expand expan_numB, gen(duplicateB)
expand expan_numC, gen(duplicateC)


/* ==========================================================================
12) Creamos la variable "año" (ahora mismo, todas las observaciones duplicadas
tienen el mismo dato en year: 
=============================================================================*/
replace duplicateA = - duplicateA /*Que me ponga primero las duplicadas, y la última la original*/
sort pid year duplicateA /*!!Importante el sorting que hacemos!!*/
by pid: replace year = cond(_n==1, min(d16,MCVL_entry), min(d16,MCVL_entry)+_n-1)  if duplicateA==-1

sort pid year duplicateB /*!!Importante el sorting que hacemos!!*/ /*Que me ponga primero la original*/
by pid: replace year = year[_n-1] + 1  if duplicateB==1

replace duplicateC = - duplicateC /*Que me ponga primero las duplicadas, y la última la original*/
sort pid year duplicateC /*!!Importante el sorting que hacemos!!*/
by pid: replace year = cond(_n==1, min(d16,MCVL_entry), min(d16,MCVL_entry)+_n-1)
drop d16


/* ==========================================================================
13) Guardamos una copia del file en la carpeta de arhivos comunes a todas las olas:
=========================================================================== */
sort pid year
order pid year yearbirth MCVL_WO MCVL_entry _fillin, first
save "{path}\cohorts_2018\IndividualsFULL.dta", replace



********************************************************************************
********************************************************************************
*******************     INDIVIDUOS - Wave Origin (WO)     **********************
********************************************************************************
********************************************************************************

/* ==========================================================================
14) Creamos otro archivo que contenga solo a los individuos y a la ola a la
que pertencen, tras hacer LIMPIEZA:
=========================================================================== */
keep if year==MCVL_WO
keep pid MCVL_WO yearbirth birthdate
tab MCVL_WO
save "{path}\cohorts_2018\IndividualsWO.dta", replace

/*Éste será el file que usaremos para hacer toda la lectura por edición de MCVL
pero sólo para los individuos que aparecen por última vez en esa edición.*/


/*NOTA IMPORTANTE: en los siguientes do-files, también estaremos eliminando
indirectamente a gente que tenga menos de 16 años o más de 99 años en el año
de referencia de la MCVL de la que vendrán sus datos. Esto ocurre porque
en el loop por cohortes vamos a llamar a esa banda de cohortes (nacidos 
desde -99 y hasta -16 años antes del año de referencia de la ola de la MCVL
con la que estemos trabajando. 

foreach j of numlist 2005/$v {
local end   = `j'-16
local start = `j'-99
count if (yearbirth<`start' | yearbirth>`end') & MCVL_WO==`j'
}
*

*/








********************************************************************************
********************************************************************************
****************************     EMPRESAS    ***********************************
********************************************************************************
********************************************************************************

/* ==========================================================================
1) Creamos un fichero por cada MCVL, con la info de las empresas para ese año:
=========================================================================== */
foreach i of num 2005/$v {
use "{path}\cohorts_2018\MCVL`i'AFILIAD.dta", clear

drop pid regime group contracttype parttimecoef altadate ///
bajadate bajareason disability TRL empresa firm_cc1 newcontractdate1 ///
prevcontracttype1 prevparttimecoef1 newcontractdate2 prevcontracttype2 prevparttimecoef2 ///
newcontributiongroupdate prevcontributiongroup
capture drop SETA TRaut efecaltadate efecbajadate /*En algunas versiones aparecen y
en otras no, por eso usamos 'capture'*/


/* ==========================================================================
2) Limpiamos la variable "employertype" y "firm_type":
=========================================================================== */
destring employertype, replace force
replace employertype=0 if employertype==.
replace firmtype="" if firmtype!="A" & firmtype!="B" & firmtype!="C" & firmtype!="D" & firmtype!="E" & firmtype!="F" & firmtype!="G" & firmtype!="H" & firmtype!="J" & firmtype!="N" & firmtype!="P" & firmtype!="Q" & firmtype!="R" & firmtype!="S" & firmtype!="U" & firmtype!="V" & firmtype!="W"
/*firmtype solo tiene sentido cuando employertype==9*/


/* ==========================================================================
3) Creamos la variable "year" y nos quedamos con una observacion por empresa
=========================================================================== */
gen year = `i'
gen altayear=floor(altadate/10000)
gsort firm_cc2 -altayear /*Forzamos un sorting más concreto, de forma que para el caso de que haya
muchas observaciones por empresa, nos quedamos con "la más reciente". Se supone que la info de empresa
debe ser la misma para una misma edición de la MCVL (toda la info viene referida a la fecha de extracción
de la misma), pero hay casos en los que esto no pasa. Nuestra regla será elegir el dato que se corresponda 
con el episodio de alta más reciente. */
egen tagid=tag(firm_cc2)
keep if tagid==1 
drop tagid
qui compress 

save "{path}\cohorts_2018\MCVL`i'AFILIADfirm.dta", replace

}
*

/* ==========================================================================
4) Unimos todos los años para tener un panel empresa-año:
=========================================================================== */
use "{path}\cohorts_2018\MCVL${v}AFILIADfirm.dta", clear

local z = $v - 1
foreach i of num 2005/`z'{
append using "{path}\cohorts_2018\MCVL`i'AFILIADfirm.dta"
}
*
save "{path}\cohorts_2018\FirmsFULL_original.dta", replace



/* ==========================================================================
5) Subsanamos ciertos casos de missings en algunas de las variables:
=========================================================================== */

/* 5.1) El dato indicativo de empresa temporal u otros tipos, sólo disponible a 
partir de 2006. Por eso, copiamos el dato (posterior, no necesariamente será
el de 2006, porque puede haber huecos en el panel) más cercano disponible. */
gen negyear = -year
sort firm_cc2 negyear /* ! Importante el sorting que hacemos*/
bys firm_cc2 (negyear): replace ETT = ETT[_n-1] if year==2005 & _n>1


/* 5.2) El dato de primera afiliacion puede estar missing en algunos años (i.e., = 0) y disponible
en los siguientes. Los rellenamos con el dato más cercano en el tiempo. Pero en general
si está missing en un año, suele estar missing en todos. */
*sort firm_cc2 negyear /*Rellenamos missings hacia atrás*/
replace altadate1staffiliated = . if altadate1staffiliated==0 /*Podríamos dejarlo con el cero, para hacer la línea
de debajo, pero necesitamos que sea missing para cuando creamos expan_num*/
by firm_cc2: replace altadate1staffiliated = altadate1staffiliated[_n-1] if altadate1staffiliated==. & altadate1staffiliated[_n-1]!=.


/* 5.3) El dato de CNAE-09 sólo está disponible a partir de 2009. Lo rellenamos con 
el dato posterior más cercano en el tiempo. */
*sort firm_cc2 negyear /*Rellenamos missings hacia atrás*/
by firm_cc2: replace factivity09 = factivity09[_n-1] if factivity09=="" & factivity09[_n-1]!=""


/* 5.4) El dato de CNAE-93 no está disponible para la MCVL2009 (year==2009). Lo 
rellenamos con el dato posterior más cercano en el tiempo (resultados similares 
si cogiesemos el dato anterior más cercano en el tiempo, pero lo hacemos asi 
para aprovechar la forma en la que están ordenados los datos. */
*sort firm_cc2 negyear /*Rellenamos missings hacia atrás*/
by firm_cc2: replace factivity93 = factivity93[_n-1] if year==2009 /* Especialmente
útil coger el dato posterior si se trata de una empresa que empezamos a observar 
desde la MCVL2009 */
drop negyear

sort firm_cc2 year /* ! Importante el sorting que hacemos*/
by firm_cc2: replace factivity93 = factivity93[_n-1] if year==2009 & missing(factivity93) /*Por si 
se trata de empresas que hayamos dejado de observar justo en 2009, le cogemos el anterior */
/*NOTA: factivity93 seguirá siendo missing en aquellas poquitas empresas que solo observemos exclu-
sivamente en la MCVL2009*/




/* ==========================================================================
6) Rectangularizamos el panel, y si hay huecos rellenamos con la información 
disponible e inmediatamente anterior.
=========================================================================== */

/* 6.1) Creamos una variable que nos diga la primera MCVL en la que tenemos info
de una determinada empresa. Esa fila será la que arrastraremos a pasado.*/
by firm_cc2: egen ini_year = min(year)

/* 6.2) Creamos una variable que nos diga la última MCVL en la que tenemos info
de una determinada empresa. */
by firm_cc2: egen end_year = max(year)


/* 6.3) Hasta ahora los datos pueden contener "huecos" no visibles, es decir, puede
haber empresas que apareciesen en la MCVL2005 y no en la de 2006 (y por tanto, 
year pasase de 2005 a 2007). Vamos a crear esa observacion (con todo en missing) de 2006: */
qui fillin firm_cc2 year
sort firm_cc2 year


/* 6.4) Nos quedamos solo con los años posteriores a la primera vez que la observo 
(ini_year), y anteriores a la última vez que la observo . Los otros años (o huecos 
entre ambos límites) han sido creados artificialmente por "fillin" */
rename ini_year ini_year_tmp
by firm_cc2: egen ini_year = max(ini_year_tmp) /*Para rellenar missings en la ini_year
creados por fillin. Ahora ini_year es constante por individuo */
label variable ini_year "Primera MCVL en la que observo al CC2"
drop ini_year_tmp

rename end_year end_year_tmp
by firm_cc2: egen end_year = max(end_year_tmp) /*Para rellenar missings en la end_year
creados por fillin. Ahora end_year es constante por individuo */
label variable end_year "Última MCVL en la que observo al CC2"
drop end_year_tmp

drop if year < ini_year 
drop if year > end_year


/* 6.5) Rellenamos los huecos creados por fillin entre ambos años (empresas que salen
y entran de la muestra) con la info del año inmediatamente anterior.*/

sort firm_cc2 year /* ! Importante el sorting que hacemos*/
foreach var of varlist factivity09 firmtype factivity93 fsize ///
altadate1staffiliated ETT employertype faddress { 
by firm_cc2: replace `var' = `var'[_n-1] if _fillin == 1 
}
*

/* ==========================================================================
7) Expandimos el panel para que cubra desde la fecha de la primera edicion de 
la MCVL en la que la observo hasta el año de la primera afiliación de un 
trabajador en la CC2.
=========================================================================== */

/* 7.1) Hay un 0.3% de casos en los que la fecha de alta cambia dentro del mismo CC, 
por eso, vamos a coger el más antiguo como límite inferior a la hora de crear el panel */
sort firm_cc2 altadate1staffiliated
by firm_cc2: egen altayear_cc2 = min(int(altadate1staffiliated/10000)) 
/*NOTA: hay unos muy pocos casos en los que la empresa aparece en ediciones de la MCVL en
las que teoricamente la empresa no estaba aún dada de alta. Es decir, la fecha de primer
alta de un trabajador es posterior a la fecha en que la empresa aparece por primera 
vez en la MCVL. Le damos prioridad a ini_year (en vez de a altayear_cc2). */

/* 7.2) El pasado de las Cuentas de Cotización (CC) se va a remontar como mucho hasta 1940 (porque así lo hemos decidido), 
con el límite del año en que se crea dicha CC2 si es que se trata de una fecha posterior. 
La if condition la ponemos ya que solo vamos a duplicar la observación más antigua. 
Nótese que si altayear_cc2 es missing (.) se van a crear observaciones para dicha empresa hasta 1940. 
Es necesario poner "cond(missing(altayear_cc2),1940,max(1940,altayear_cc2))" debido a que, por un lado, 
si altayear es missing, por precaucion vamos a extender el panel para ese cc2 como si hubiese
estado activo desde 1940, y por otro lado, porque para los poquitos casos en los que altayear_cc2
sea posterior a ini_year, el resultado final será un número negativo para expan_num, y los
numeros negativos serán obviados por el comando expand (es decir, no se harán duplicados de esas
observaciones).  */
sort firm_cc2 year
gen expan_num = ini_year - cond(altayear_cc2==.,1940,max(1940,altayear_cc2)) + 1 if year==ini_year 
expand expan_num, gen(duplicate)


/* ==========================================================================
8) Creamos la variable año que va desde el año de creacion de la CC hasta el último
año en que aparezca: 
=============================================================================*/
replace duplicate = - duplicate /*Que me ponga primero las duplicadas, y la última la original*/
bys firm_cc2 (year duplicate): replace year = cond(_n==1, max(1940,altayear_cc2), max(1940,altayear_cc2)+_n-1)  if duplicate==-1


/* ==========================================================================
9) Guardamos una copia del file en la carpeta de arhivos comunes a todas las olas:
=========================================================================== */
sort firm_cc2 year
save "{path}\cohorts_2018\FirmsFULL", replace
*

timer off 3
timer list 3



















