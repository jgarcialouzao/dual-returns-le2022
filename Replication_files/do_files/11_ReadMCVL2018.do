
version 14

timer clear 2
timer on 2

clear all

capture log close

set more off

*** Set year of last version of MCVL_CDF:
global v_old 2018

  
*******************************************
*******************************************
******************* 2018 ******************
*******************************************
*******************************************

*************************
***** WITH TAX DATA *****
*************************

*** IMPORTANTH: Original data files should be storage in ${path}\cohorts_2018\ folder. This is the working folder to set-up the files in Stata format to proceed after with data cleaning and final results

*** PERSONAL 2018 ***
unzipfile "{path}\cohorts_2018\MCVL${v_old}CDF.zip", replace

*Import PERSONAL data:
clear all
import delimited "{path}\cohorts_2018\MCVL${v_old}PERSONAL_CDF.TXT", delimiter(";") varnames(nonames) 
capture drop v11
save "{path}\cohorts_2018\MCVL${v_old}PERSONAL.dta", replace

rename v1 pid
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 birth
label variable birth "FECHA DE NACIMIENTO: AÑO + MES"
rename v3 sex
label variable sex "SEXO: 1-HOMBRE 2-MUJER"
rename v4 nationality
label variable nationality "NACIONALIDAD DE LA PERSONA"
rename v5 province
label variable province "PROVINCIA DE NACIMIENTO"
rename v6 provinceaf
label variable provinceaf "PROVINCIA DE PRIMERA AFILIACION"
rename v7 address
label variable address "DOMICILIO HABITUAL DE LA PERSONA FISICA"
rename v8 death
label variable death "FECHA DE FALLECIMIENTO: AÑO + MES"
rename v9 country
label variable country "PAIS DE NACIMIENTO DE LA PERSONA"
rename v10 education
label variable education "NIVEL EDUCATIVO"
sort pid

*There should be only one record per id:
egen tagpid=tag(pid) /*If tagpid takes value 0 means there's more than one record for the same id*/
by pid: egen mintagpid=min(tagpid) /*Identify those id with more than one record and drop them*/
drop if mintagpid==0
drop mintagpid tagpid

**OLA MCVL
gen MCVL_WO=${v_old}
label variable MCVL_WO "MUESTRA DE ORIGEN"

save "{path}\cohorts_2018\MCVL${v_old}PERSONAL.dta", replace


*** CONVIVIENTES ***

clear all
import delimited "{path}\cohorts_2018\MCVL${v_old}CONVIVIR_CDF.TXT", delimiter(";") varnames(nonames) 
save "{path}\cohorts_2018\MCVL${v_old}CONVIVIR.dta", replace 

rename v1 pid
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 birth
label variable birth "FECHA DE NACIMIENTO: AÑO + MES"
rename v3 sex
label variable sex "SEXO: 1-HOMBRE 2-MUJER"
rename v4 birth2
rename v5 sex2
rename v6 birth3
rename v7 sex3
rename v8 birth4
rename v9 sex4
rename v10 birth5
rename v11 sex5
rename v12 birth6
rename v13 sex6
rename v14 birth7
rename v15 sex7
rename v16 birth8
rename v17 sex8
rename v18 birth9
rename v19 sex9
rename v20 birth10
rename v21 sex10
label variable birth2 "FECHA DE NACIMIENTO DE LA 2ª PERSONA CONVIVIENDO"
label variable sex2 "SEXO DE LA 2ª PERSONA CONVIVIENDO"
label variable birth3 "FECHA DE NACIMIENTO DE LA 3ª PERSONA CONVIVIENDO"
label variable sex3 "SEXO DE LA 3ª PERSONA CONVIVIENDO"
label variable birth4 "FECHA DE NACIMIENTO DE LA 4ª PERSONA CONVIVIENDO"
label variable sex4 "SEXO DE LA 4ª PERSONA CONVIVIENDO"
label variable birth5 "FECHA DE NACIMIENTO DE LA 5ª PERSONA CONVIVIENDO"
label variable sex5 "SEXO DE LA 5ª PERSONA CONVIVIENDO"
label variable birth6 "FECHA DE NACIMIENTO DE LA 6ª PERSONA CONVIVIENDO"
label variable sex6 "SEXO DE LA 6ª PERSONA CONVIVIENDO"
label variable birth7 "FECHA DE NACIMIENTO DE LA 7ª PERSONA CONVIVIENDO"
label variable sex7 "SEXO DE LA 7ª PERSONA CONVIVIENDO"
label variable birth8 "FECHA DE NACIMIENTO DE LA 8ª PERSONA CONVIVIENDO"
label variable sex8 "SEXO DE LA 8ª PERSONA CONVIVIENDO"
label variable birth9 "FECHA DE NACIMIENTO DE LA 9ª PERSONA CONVIVIENDO"
label variable sex9 "SEXO DE LA 9ª PERSONA CONVIVIENDO"
label variable birth10 "FECHA DE NACIMIENTO DE LA 10ª PERSONA CONVIVIENDO"
label variable sex10 "SEXO DE LA 10ª PERSONA CONVIVIENDO"


*There should be only one record per id:
egen tagpid=tag(pid) /*If tagpid takes value 0 means there's more than one record for the same id*/
bys pid: egen mintagpid=min(tagpid) /*Identify those id with more than one record and drop them*/
drop if mintagpid==0
drop mintagpid tagpid

sort pid birth sex
tostring birth, replace
compress
save "{path}\cohorts_2018\MCVL${v_old}CONVIVIR.dta", replace 



*** DIVISION ***
clear all
import delimited "{path}\cohorts_2018\MCVL${v_old}DIVISION_CDF.TXT", delimiter(" ") varnames(nonames) 
save "{path}\cohorts_2018\MCVL${v_old}DIVISION.dta", replace 

rename v1 pid
rename v2 relacionesfile
rename v3 basesfile
replace basesfile=1 if basesfile==11
replace basesfile=2 if basesfile==12
replace basesfile=3 if basesfile==13
replace basesfile=4 if basesfile==21
replace basesfile=5 if basesfile==22
replace basesfile=6 if basesfile==23
replace basesfile=7 if basesfile==31
replace basesfile=8 if basesfile==32
replace basesfile=9 if basesfile==33
replace basesfile=10 if basesfile==41
replace basesfile=11 if basesfile==42
replace basesfile=12 if basesfile==43
label variable relacionesfile "FICHEROS DE RELACIONES LABORALES"
label variable basesfile "FICHERO DE BASES DE COTIZACION"

*There should be only one record per id:
egen tagpid=tag(pid) /*If tagpid takes value 0 means there's more than one record for the same id*/
bys pid: egen mintagpid=min(tagpid) /*Identify those id with more than one record and drop them*/
drop if mintagpid==0
drop mintagpid tagpid

save "{path}\cohorts_2018\MCVL${v_old}DIVISION.dta", replace 




*** COTIZACION ***

clear all

*Import each file and put it in Stata format:
foreach i of numlist 1/12 {
*Directory where the .txt files are:
import delimited "{path}\cohorts_2018\MCVL${v_old}COTIZA`i'_CDF.TXT", delimiter(";") varnames(nonames) clear
qui compress
save "{path}\cohorts_2018\MCVL${v_old}COTIZA_`i'", replace
}
*

*Merge the 12 files:
use "{path}\cohorts_2018\MCVL${v_old}COTIZA_1.dta", clear

foreach i of numlist 2/12 {
append using "{path}\cohorts_2018\MCVL${v_old}COTIZA_`i'.dta"
}
*

rename v1 pid        
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 firm_cc2                  
label variable firm_cc2 "CODIGO DE CUENTA DE COTIZACION SECUNDARIO"
rename v3 year
label variable year "AÑO DE COTIZACION"
rename v4 inc1
rename v5 inc2
rename v6 inc3
rename v7 inc4
rename v8 inc5
rename v9 inc6
rename v10 inc7
rename v11 inc8
rename v12 inc9
rename v13 inc10
rename v14 inc11
rename v15 inc12
rename v16 totalcontribution
label variable inc1 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE ENERO"
label variable inc2 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE FEBRERO"
label variable inc3 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE MARZO"
label variable inc4 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE ABRIL"
label variable inc5 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE MAYO"
label variable inc6 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE JUNIO"
label variable inc7 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE JULIO"
label variable inc8 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE AGOSTO"
label variable inc9 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE SEPTIEMBRE"
label variable inc10 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE OCTUBRE"
label variable inc11 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE NOVIEMBRE"
label variable inc12 "BASE DE COTIZACION POR CONTINGENCIAS COMUNES DE DICIEMBRE"
label variable totalcontribution "SUMA DE BASE DE COTIZACION POR CONTINGENCIAS COMUNES DEL AÑO"

sort pid firm_cc2 year

qui compress 
save "{path}\cohorts_2018\MCVL${v_old}COTIZA.dta", replace

foreach i of numlist 1/12 {
erase "{path}\cohorts_2018\MCVL${v_old}COTIZA_`i'.dta"
}
*


** COTIZACION AUTONOMOS  ***
import delimited "{path}\cohorts_2018\MCVL${v_old}COTIZA13_CDF.TXT", delimiter(";") varnames(nonames) clear
rename v1 pid        
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 firm_cc2                  
label variable firm_cc2 "CODIGO DE CUENTA DE COTIZACION SECUNDARIO"
rename v3 year
label variable year "AÑO DE COTIZACION"
rename v4 incaut1
rename v5 incaut2
rename v6 incaut3
rename v7 incaut4
rename v8 incaut5
rename v9 incaut6
rename v10 incaut7
rename v11 incaut8
rename v12 incaut9
rename v13 incaut10
rename v14 incaut11
rename v15 incaut12
rename v16 contributiontot  
label variable incaut1 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE ENERO"
label variable incaut2 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE FEBRERO"
label variable incaut3 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE MARZO"
label variable incaut4 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE ABRIL"
label variable incaut5 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE MAYO"
label variable incaut6 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE JUNIO"
label variable incaut7 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE JULIO"
label variable incaut8 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE AGOSTO"
label variable incaut9 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE SEPTIEMBRE"
label variable incaut10 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE OCTUBRE"
label variable incaut11 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE NOVIEMBRE"
label variable incaut12 "BASE DE COTIZACION CUENTA PROPIA Y OTROS DE DICIEMBRE"
label variable contributiontot "TOTAL BASE DE COTIZACION CUENTA PROPIA DEL AÑO"

sort pid firm_cc2 year

qui compress 
save "{path}\cohorts_2018\MCVL${v_old}COTIZA_13.dta", replace 


*** Afiliados ***
clear all

*Import each file and put it in Stata format:
foreach i of numlist 1/4 {
*Directory where the .txt files are:
import delimited "{path}\cohorts_2018\MCVL${v_old}AFILIAD`i'_CDF.TXT", delimiter(";") varnames(nonames) stringcols(12 30) clear
qui compress
save "{path}\cohorts_2018\MCVL${v_old}AFILIAD_`i'", replace
}
*

*Merge the 12 files:
use "{path}\cohorts_2018\MCVL${v_old}AFILIAD_1.dta", clear

foreach i of numlist 2/4 {
append using "{path}\cohorts_2018\MCVL${v_old}AFILIAD_`i'.dta"
}
*


rename v1 pid        
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 regime
rename v3 group                  
rename v4 contracttype
rename v5 parttimecoef                  
rename v6 altadate                 
rename v7 bajadate               
rename v8 bajareason                 
rename v9 disability                  
rename v10 firm_cc2                  
rename v11 faddress2                 
rename v12 factivity09                  
rename v13 fsize
rename v14 altadate1staffiliated                 
rename v15 TRL                  
rename v16 ETT                  
rename v17 employertype         
rename v18 firmtype   
rename v19 empresa    
rename v20 firm_cc1                 
rename v21 faddress             
rename v22 newcontractdate1                 
rename v23 prevcontracttype1                  
rename v24 prevparttimecoef1                
rename v25 newcontractdate2
rename v26 prevcontracttype2
rename v27 prevparttimecoef2                         
rename v28 newcontributiongroupdate 
rename v29 prevcontributiongroup  
rename v30 factivity93     
rename v31 SETA
rename v32 TRaut
rename v33 efecaltadate                 
label variable efecaltadate "FECHA EFECTO DE ALTA EN LA AFILIACION"
rename v34 efecbajadate               
label variable efecbajadate "FECHA EFECTO DE BAJA EN LA AFILIACION"

label variable regime "REGIMEN DE COTIZACION"
label variable group "GRUPO DE COTIZACION"
label variable contracttype "TIPO DE CONTRATO DE TRABAJO"
label variable parttimecoef "COEFICIENTE DE TIEMPO PARCIAL"
label variable altadate "FECHA REAL DE ALTA EN LA AFILIACION"
label variable bajadate "FECHA REAL DE BAJA EN LA AFILIACION"
label variable bajareason "CAUSA DE BAJA Y ALTA EN LA AFILIACION"
label variable disability "MINUSVALIA SEGUN ALTA DE AFILIACION"
label variable firm_cc2 "CODIGO DE CUENTA DE COTIZACION SECUNDARIO"
label variable faddress2 "DOMICILIO DE ACTIVIDAD DEL CCC SECUNDARIO"
label variable factivity09 "ACTIVIDAD ECONOMICA DEL CCC (CNAE-09)"
label variable factivity93 "ACTIVIDAD ECONOMICA DEL CCC (CNAE-93)"
label variable fsize "NUMERO DE TRABAJADORES EN LA CCC"
label variable altadate1staffiliated "FECHA REAL DEL ALTA DEL PRIMER TRABAJADOR DE UN CCC"
label variable TRL "TIPO DE RELACION LABORAL"
label variable ETT "INDICATIVO DE EMPRESA DE TRABAJO TEMPORAL"
label variable employertype "TIPO DE EMPLEADOR"
label variable firmtype "TIPO DE EMPRESA JURIDICA"
label variable empresa "EMPRESA DATOS FISCALES"
label variable firm_cc1 "CODIGO DE CUENTA DE COTIZACION PRINCIPAL"
label variable faddress "DOMICILIO SOCIAL DEL CCC PRINCIPAL"
label variable newcontractdate1 "FECHA DE 1ª MODIFICACION DEL CONTRATO"
label variable prevcontracttype1 "TIPO DE CONTRATO HASTA LA 1ª MODIFICACION"
label variable prevparttimecoef1 "COEF. DE TIEMPO PARCIAL HASTA LA 1ª MODIFICACION"
label variable newcontractdate2 "FECHA DE 2ª MODIFICACION DEL CONTRATO"
label variable prevcontracttype2 "TIPO DE CONTRATO HASTA LA 2ª MODIFICACION"
label variable prevparttimecoef2 "COEF. DE TIEMPO PARCIAL HASTA LA 2ª MODIFICACION"
label variable newcontributiongroupdate "FECHA DE MODIFICACION DEL GRUPO DE COTIZACION"
label variable prevcontributiongroup "GRUPO DE COTIZACION HASTA LA MODIFICACION"
label variable SETA "Indicador de Sistema Especial Trabajadores Agrarios"
label variable TRaut "Identificación de autónomos con otros empleadores (TRADE)"

sort pid altadate bajadate firm_cc2
qui compress 

save "{path}\cohorts_2018\MCVL${v_old}AFILIAD.dta", replace

foreach i of numlist 1/4 {
erase "{path}\cohorts_2018\MCVL${v_old}AFILIAD_`i'.dta"
}
*


*** RETIREMENT BENEFITS ***

import delimited "{path}\cohorts_2018\MCVL${v_old}PRESTAC_CDF.TXT", delimiter(";") varnames(nonames) clear
save "{path}\cohorts_2018\MCVL${v_old}PRESTAC.dta", replace

rename v1 pid
label variable pid "IDENTIFICADOR DE LA PERSONA FISICA"
rename v2 year
label variable year "YEAR"
rename v3 idpen
label variable idpen "IDENTIFICADOR DE LA PRESTACIÓN"
rename v4 clase
label variable clase "CLASE DE LA PRESTACIÓN"
rename v5 situacion
label variable situacion "SITUACIÓN DEL SUJETO CAUSANTE"
rename v6 gincapacidad
label variable gincapacidad "GRADO DE INCAPACIDAD"
rename v7 fechainca
label variable fechainca "FECHA INCAPACIDAD"
rename v8 sovi
label variable sovi "NORMA SOVI"
rename v9 minimo
label variable minimo "CLASE MINIMO"
rename v10 regimen
label variable regimen "REGIMEN"
rename v11 fecha
label variable fecha "FECHA DE LA PENSION"
rename v12 base
label variable base "BASE REGULADORA"
rename v13 porcentaje
label variable porcentaje "PORCENTAJE"
rename v14 bonificados
label variable bonificados "AÑOS BONIFICADOS"
rename v15 cotizados
label variable cotizados "AÑOS COTIZADOS"
rename v16 importe
label variable importe "IMPORTE MENSUAL PENSION"
rename v17 revalorizacion
label variable revalorizacion "IMPORTE MENSUAL REVALORIZACION"
rename v18 complementos
label variable complementos "IMPORTE MENSUAL COMPLEMENTOS"
rename v19 otroscomple
label variable otroscomple "IMPORTE MENSUAL OTROS COMPLEMENTOS"
rename v20 importetot
label variable importetot "IMPORTE MENSUAL TOTAL"
rename v21 baja
label variable baja "SITUACION (causa baja)"
rename v22 fechasitu
label variable fechasitu "FECHA SITUACION PENSION"
rename v23 provinpension
label variable provinpension "PROVINCIA PRENSION"
rename v24 prorrata
label variable prorrata "PRORRATA"
rename v25 prorratadiv
label variable cotizados "PRORRATA DIVORCIO"
rename v26 reductor
label variable reductor "COEFICIENTE REDUCTOR"
rename v27 tipo
label variable tipo "TIPO SITUACION JUBILACION"
rename v28 parcialidad
label variable parcialidad "COEFICIENTE PARCIALIDAD"
rename v29 orfandad
label variable orfandad "PRESTACION VITALICIA (orfandad)"
rename v30 concurrencia
label variable concurrencia "CONCURRENCIA PRESTACION AJENA"
rename v31 nacicausante
label variable nacicausante "AÑO NACIMIENTO CAUSANTE"
rename v32 limitada
label variable limitada "PENSION LIMITADA"
rename v33 coef_reductor
label variable coef_reductor "COEFICIENTE REDUCTOR DEL LIMITE MAXIMO"
rename v34 compat_trab
label variable compat_trab "COMPATIBILIDAD CON TRABAJO"
rename v35 fecha_jub_ord
label variable fecha_jub_ord "FECHA ORDINARIA JUBILACION"
rename v36 peri_cotiz_ord
label variable peri_cotiz_ord "PERIODO COTIZADO EN EDAD ORDINARIA DE JUBILACION"
rename v37 peri_cotiz
label variable peri_cotiz "PERIODO DE COTIZACION"
rename v38 porcent_añoscotiz
label variable porcent_añoscotiz "PORCENTAJE POR AÑOS COTIZADOS"
rename v39 comp_matern
label variable porcent_añoscotiz "IMPORTE TOTAL COMPLEMENTO MATERNIDAD en céntimos de e"
rename v40 porcent_matern
label variable porcent_añoscotiz "PORCENTAJE COMPLEMENTO MATERNIDAD"
rename v41 parcialidad_global
label variable parcialidad_global "COEFICIENTE GLOBAL DE PARCIALIDAD"

sort pid
compress

save "{path}\cohorts_2018\MCVL${v_old}PRESTAC.dta", replace 

****** DATOS FISCALES ******

import delimited "{path}\cohorts_2018\MCVL${v_old}FISCAL_CDF.TXT", delimiter(";") clear 

gen year=${v_old}
rename v1 pid
label variable pid "Identificador del perceptor"
rename v2 letra
label variable letra "Letra NIF de la entidad pagadora"
rename v3 empresa
label variable empresa "Identificador del pagador"
rename v4 prov
label variable prov "provincia"
rename v5 clave
label variable clave "Clave de percepcion: A empleados por cuenta ajena; B:pensionistas; C:subsidios de desempleo"
rename v6 subclave
label variable subclave "subclave. Dependiendo de la letra tiene diferentes categorías numericas 01/02 "
rename v7 wage
label variable wage "Percepción integra dineraria no derivada de IL en céntimos de e"
rename v8 wage_il 
label variable wage_il "Percepción integra dineraria derivada de IL en céntimos de e"
rename v9 reten
label variable reten "Retenciones practicadas sobre p.diner no deriv. IL en céntimos de e"
rename v10 reten_il
label variable reten_il "Retenciones practicadas sobre p.diner deriv. IL en céntimos de e"
rename v11 especie		
label variable especie "Percepciones en especie no deriv. IL en céntimos de e"
rename v12 especie_il		
label variable especie_il "Percepciones en especie deriv. IL en céntimos de e"
rename v13 iac
label variable iac "Ingreso a cta efectuados por especie no IL en centimos de euro"
rename v14 iac_il
label variable iac "Ingreso a cta efectuados por especie por IL en centimos de euro"
rename v15 iar
label variable iar "Ingreso a cta repercutido por especie no IL en centimos"
rename v16 iar_il
label variable iar_il "Ingreso a cta repercutido por especie deriv. IL en centimos"
***
rename v17 com
label variable com "Ceuta o melilla =1"
rename v18 cohorte
label variable cohorte "año de nacimiento del perceptor. Solo para claves A, B.01, B.02, C, D Y M"
rename v19 sitfam
label variable sitfam "Situación familiar. Solo para claves A, B.01, B.02, C, D Y M"
rename v20 discap
label variable discap "Discapacidad igual o superio al 33. Solo para claves A, B.01, B.02, C, D Y M"
*tostring discap, replace
rename v21 contra
*tostring contra, replace
label variable contra "Tipo de contrato. Solo para A Y M. Si es cta ajena en activo mirar tabla"
rename v22 movilidad
label variable movilidad "movilidad geográfica. Sólo para A Y M"
rename v23 reduc
label variable reduc "Reducciones. Solo para claves A, B.01, B.02, C, D Y M"
rename v24 gdeb
label variable gdeb "Gastos deducibles. Solo para claves A, B.01, B.02, C, D Y M"
rename v25 pcom
label variable pcom "Pensión compensatoria. Solo para claves A, B.01, B.02, C, D Y M"
rename v26 apa
label variable apa "anualidad por alimentos"
rename v27 descmenor3
label variable descmenor3 "descendientes menores de 3 años.  Solo para claves A, B.01, B.02, C, D Y M"
rename v28 descmenor3e
label variable descmenor3 "descendientes menores de 3 años por entero.  Solo para claves A, B.01, B.02, C, D Y M"
rename v29 restod
label variable restod "Resto de descendientes"
rename v30 restode
label variable restode "Resto de descendientes por entero"
rename v31 desdis3365
label variable desdis3365 "Descendientes con minusvalía del 33 al 65"       
rename v32 desdis3365e
label variable desdis3365e"Descendientes con minusvalía del 33 al 65 por entero"
rename v33 desdis3365mr
label variable desdis3365mr "Descendientes con minusvalía del 33 al 65 con movilidad reducida"
rename v34 desdis3365mre
label variable desdis3365mre "Descendientes con minusvalía del 33 al 65 con movilidad reducida por entero"
rename v35 desdismay65
label variable desdismay65 "Descendientes con minusvalía mayor 65"
rename v36 desdismay65e
label variable desdismay65e "Descendientes con minusvalía mayor 65 por entero"
rename v37 totaldes
label variable totaldes "Numero total de descendientes"
rename v38 ascemen75
label variable ascemen75 "Ascendientes menores de 75"
rename v39 ascemen75e
label variable ascemen75e "Ascendientes menores de 75 por entero"
rename v40 ascemayoeq75
label variable ascemayoeq75 "Ascendientes mayores o igual a 75"
rename v41 ascemayoeq75e
label variable ascemayoeq75e "Ascendientes mayores o igual a 75 por entero"
rename v42 ascedis3365
label variable ascedis3365 "Ascendientes discapacitaos de 33 a 65"
rename v43 ascedis3365e 
label variable ascedis3365e "Ascendientes discapacitaos de 33 a 65 por entero"
rename v44 ascedis3365mr
label variable ascedis3365mr "Ascendientes discapacitaos de 33 a 65 con movilidad reducida" 
rename v45 ascedis3365mre
label variable ascedis3365mre "Ascendientes discapacitaos de 33 a 65 con movilidad reducida por entero" 
rename v46 ascedismay65
label variable ascedismay65 "Ascendientes discapacitaos mayores 65"
rename v47 ascedismay65e
label variable ascedismay65e "Ascendientes discapacitaos mayores 65 por entero"
rename v48 totalasce
label variable totalasce "Número total de ascendientes"

sort pid empresa
compress
save "{path}\cohorts_2018\MCVL${v_old}FISCAL.dta", replace 				

*Eliminamos los .txt extraidos de la carpeta zip:
!erase *.txt

timer off 2
timer list 2

*** Create two .dta files: 

 a) A panel of firms and their characteristics over time (only from 2005-20##)
 b) A panel of individuals (their id) and a reference to the latest version of the MCVL in which they appear */

do "{path}\do_files\PastInfo2018.do"
 