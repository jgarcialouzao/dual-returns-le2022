
version 14

clear all

capture log close

set more off

timer clear 10
timer on 10

*****************************************************************************
*****************************************************************************
****** STEP 7: Comprimimos los archivos intermedios que hemos creado  *******
*****************************************************************************
*****************************************************************************

/* Vamos a llevar todos los archivos a carpetas que queramos comprimir 
(subdirectorios), y en el directorio principal en el que estén esas carpetas, 
ejecutaremos el archivo "foldertomultiple7z.bat". Una copia de este archivo 
estará siempre dentro de cada carpeta principal MCVL####CDF.

Si no encontrásemos el archivo "foldertomultiple7z.bat", simplemente hay que 
crear un .txt con la siguiente linea de código:

	for /d %%X in (*) do "c:\Program Files\7-Zip\7z.exe" a "%%X.zip" "%%X\"
	
Lo guardamos con el nombre "foldertomultiple7z.bat".*/


/* ==========================================================================
1) Primero creamos una carpeta para cada "tipo" de archivo (generados en las 
distintas etapas de la lectura)
=============================================================================*/
local last   = ${v} - 1 
foreach i of numlist 2005/`last' {
!rmdir "{path}\cohorts_2018\6_MCVL`i'_YearMonth" /s /q 
}

foreach i of numlist 2005/$v {
mkdir "{path}\cohorts_2018\1_IndividualsAffiliated`i'"
mkdir "{path}\cohorts_2018\2_IndividualsBases`i'"
mkdir "{path}\cohorts_2018\3_IndividualsBasesM`i'"
mkdir "{path}\cohorts_2018\4_IndividualsDaysM`i'"
mkdir "{path}\cohorts_2018\5_BasesYearMonth`i'"
mkdir "{path}\cohorts_2018\6_MCVL`i'_YearMonth"
}
*

/* ==========================================================================
2) Pasamos cada archivo a su correspondiente carpeta (cut and paste).
=============================================================================*/
foreach i of numlist 2005/$v {
!move "{path}\cohorts_2018\IndividualsAffiliated*.dta" "{path}\cohorts_2018\1_IndividualsAffiliated`i'"
!move "{path}\cohorts_2018\IndividualsBases*.dta" "{path}\cohorts_2018\2_IndividualsBases`i'"
!move "{path}\cohorts_2018\IndividualsBasesM*.dta" "{path}\cohorts_2018\3_IndividualsBasesM`i'"
!move "{path}\cohorts_2018\IndividualsDaysM*.dta" "{path}\cohorts_2018\4_IndividualsDaysM`i'"
!move "{path}\cohorts_2018\BasesYearMonth*.dta" "{path}\cohorts_2018\5_BasesYearMonth`i'"
!move "{path}\cohorts_2018\MCVL`i'_YearMonth*.dta" "{path}\cohorts_2018\6_MCVL`i'_YearMonth"
}
*

/* ==========================================================================
3) Copiamos el archivo "foldertomultiple7z.bat" en el directorio principal 
donde hayamos creado las carpetas que queremos comprimir. En nuestro caso, 
ese directorio sería el de MCVL####CDF\Cohortes. Después, lo ejecutamos:
=============================================================================*/
 foreach i of numlist 2005/$v {
!copy "{path}\cohorts_2018\foldertomultiple7z.bat" "{path}\cohorts_2018\"
}
*
local last   = ${v} - 1 
foreach i of numlist 2005/`last' {
!erase "{path}\cohorts_2018\1_IndividualsAffiliated`i'.zip" /s /q
!erase "{path}\cohorts_2018\3_IndividualsBasesM`i'.zip" /s /q
!erase "{path}\cohorts_2018\2_IndividualsBases`i'.zip" /s /q
!erase "{path}\cohorts_2018\4_IndividualsDaysM`i'.zip" /s /q 
!erase "{path}\cohorts_2018\5_BasesYearMonth`i'.zip" /s /q 
!erase "{path}\cohorts_2018\6_MCVL`i'_YearMonth.zip" /s /q 
}
*
 foreach i of numlist 2005/$v {
cd "{path}\cohorts_2018\"
!foldertomultiple7z.bat
}
*

/* ==========================================================================
4) Eliminamos las carpetas creadas para quedarnos sólo con su versión comprimida,
salvo para los archivos finales que dejamos una copia descomprimida:
=============================================================================*/

foreach i of numlist 2005/$v {
!rmdir "{path}\cohorts_2018\1_IndividualsAffiliated`i'" /s /q
!rmdir "{path}\cohorts_2018\2_IndividualsBases`i'" /s /q
!rmdir "{path}\cohorts_2018\3_IndividualsBasesM`i'" /s /q
!rmdir "{path}\cohorts_2018\4_IndividualsDaysM`i'" /s /q 
!rmdir "{path}\cohorts_2018\5_BasesYearMonth`i'" /s /q 
}
*

timer off 10
timer list 10
