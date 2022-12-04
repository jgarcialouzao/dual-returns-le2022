clear all
capture log close
set more 1

foreach c of numlist 1950/2002 {

	use "${path}\cohorts_2018\MCVL2018_YearMonth_`c'\MCVL2018_YearMonth_`c'.dta", clear
	* Hombres
	qui keep if sex==1
	qui compress
	* Elimino observaciones anteriores a la primera entrada en el mercado
	qui drop if time<start
	qui compress
	* Elimino observaciones siguientes a dos años despues de la ultima relacion laboral (para mantener un criterio homogeneo)
	qui gen d=(time>end)
		bys pid (year month): gen sumd=sum(d)
	bys pid (year month): gen sumd=sum(d)
	qui drop if sumd>=24
	qui drop d sumd
	* Elimino observaciones posteriores a los 65 años y con edad missing
	qui drop if age>65
	qui compress
	* Elimino individuos con altas ficticias (cuando alta > baja)
	qui gen d=(alta > baja)
	qui bys pid: egen maxd=max(d)
	qui drop if maxd==1
	qui drop d maxd _mergeAff  _mergeBasesM MCVL_WO
	qui compress
	sort pid  time  alta  baja  firm_cc2
	* Elimino individuos con spells de autonomo u otros regímenes especiales
	gen d=(regime!=.&regime>499)
	bys pid:egen maxd=max(d)
	drop if maxd==1
	drop d maxd
	* Genero variable para marcar relaciones laborales y pongo en blanco toda la información de otro tipo de relaciones (prestaciones desempleo etc)
	gen employed = (inlist(TRL,0,87,500,901,902,910,930,932,951,999)) if alta !=.
	order employed, after (baja)
	replace days=. if employed==0 & alta !=.
	replace inc=. if employed==0  & alta !=.
	replace incaut=. if employed==0 & alta !=.
	replace alta=. if employed==0  & alta !=.
	replace baja=. if employed==0 
	replace firm_cc2=" " if employed==0
	*Nacidos en España
	keep if country==0
	qui compress
	** Todo a partir de aquí hasta la fila de asteriscos abajo es para conseguir la variable de días trabajados al mes totales teniendo en cuenta simultaneidad	
		
	/*Mes trabajado por completo*/
	gen alta_b = mdy(month,1,year) if days==30 
	gen baja_b = dofm(time+1)-1 if days==30 
	order alta_b baja_b, after(days)
	format alta_b baja_b %tdDD.Mon.CCYY

	/*Meses de alta, no enteros*/
	replace alta_b = alta if month(alta)==month & year(alta)==year  
	replace baja_b = dofm(time+1)-1 if baja >= dofm(time+1)-1 & month(alta)==month & year(alta)==year   
	/*Ese mes trabajó hasta fin de mes, si la fecha de baja es posterior al fin del mes en curso, por ello
	baja_b toma como valor el última día del mes en curso*/

	/*Meses de baja, no enteros*/
	replace alta_b = mdy(month,1,year) if alta < mdy(month,1,year) & month(baja)==month & year(baja)==year 
	/*Ese mes trabajó desde el principio del mes, si la fecha de alta es anterior al inicio del mes en curso,  
	por eso alta_b toma como valor el primer día del mes en curso */ 
	replace baja_b = baja if month(baja)==month & year(baja)==year  

	/*El episodio de afiliación empieza y acaba en el mismo mes*/
	replace alta_b = alta if month(alta)==month & year(alta)==year & month(baja)==month & year(baja)==year  
	replace baja_b = baja if month(alta)==month & year(alta)==year & month(baja)==month & year(baja)==year  

	label var alta_b "Beginning of active episode in month"
	label var baja_b "End of active episode in month"

	*creamos una variable que indica el NÚMERO de ALTAS LABORALES (CONTRATOS) el mismo mes
	bys pid time employed: gen episodesmonth = _N
	replace episodesmonth=. if employed==0 | missing(employed)
	sort pid  time  alta  baja  firm_cc2
	
	*Creamos una dummy que indica si en el día X del mes el individuo ha cotizado a desempleo según el episodio de afliación correspondiente:
	qui foreach i of numlist 1/31{
	gen byte w`i' = 0
	replace w`i' = 1 if inrange(mdy(month(alta_b),`i',year(alta_b)),alta_b, baja_b)
	}
	
	*Cogemos el máximo de cada wX por pid-time, ya que aunque haya dos o más episodios de afiliacion activos en un mismo día, solo computan como UN día trabajado
	*OJO, para evitar egen max, podemos usar el siguiente código, pero sólo si la variable de la que queremos el máximo no contiene missings:

	*calculamos el total de dias trabajados por dia, para ver si ha habido varias relaciones simultáneas:
	qui foreach i of numlist 1/31{
	sort pid time w`i'
	by pid time: gen byte W`i' = w`i'[_N]
	by pid time: egen byte sim`i' = total(w`i')
	replace sim`i'=0 if sim`i'==1
	replace sim`i'=1 if sim`i'>1 & !missing(sim`i')
	drop w`i'
	}

	*Sumamos los días trabajados en el mes y simultaneos:
	egen daysworked = rowtotal(W*) 
	label var daysworked "(total) Days worked, monthly"
	label var days "Days worked, monthly (main employer)"
	egen simultaneous = rowtotal(sim? sim??) 
	label var simultaneous "Simultaneous days, monthly"
	
	/*Para meses en los que se esté trabajando todo el mes de Febrero (del 01.Feb al 28.Feb/29.Feb), 
	se les habrá puesto 28/29 días trabajados, pero lo correcto sería que fuesen 30:*/
	gen bisiesto = (doy(mdy(12,31,year))==366)
	replace daysworked =30 if month==2 & daysworked == 28 & bisiesto == 0
	replace daysworked =30 if month==2 & daysworked == 29 & bisiesto == 1
	
	replace simultaneous = 30 if month==2 &  simultaneous == 28 & bisiesto == 0
	replace simultaneous = 30 if month==2 &  simultaneous == 29 & bisiesto == 1
	drop bisiesto
	
	*Ajuste mensual a 30 días:
	replace daysworked = 30 if daysworked==31
	replace simultaneous = 30 if simultaneous==31
	drop sim? sim?? W*
	qui compress
	
	*señalar solo una observación por cada periodo, preferiblemente en la que haya estado empleado
	gen negemployed=-employed
	sort pid time year month negemployed alta baja
	egen tag = tag(pid time)

	*eliminar los meses duplicados en los que una de las observaciones está vacía
	drop if tag == 0 & missing(alta)
	
	* me quedo con una observacion al mes si es en la misma empresa
	* recuerda: cuando mas de un empleo en el mismo mes con la misma empresa, base de cotizacion se refiere a todos los pagos!
	bys pid year month firm_cc2: egen tmp = total(days)
	bys pid year month firm_cc2: gen N = _N
	replace days = tmp if N>1
	replace days = 30 if days>30 & N>1
	bys pid year month firm_cc2 (tenure): keep if _n == _N
	drop tmp N
	

	*Some observations have income negative, 0 or missing values even if days are positive
	g missingw = (inc<=0 | inc==.) & (days>0 & days!=.) & year>=1980
	rename inc inc_orig
	g inc = inc_orig
	*Adjust missing income (negative, zeroes, or missing even if postive days) to include in wage regression - shift the distribution by 1 euro
	replace inc = . if missingw==1
	*If missing wage but observtion is between two consecutive observations with same employer take the average
	bys pid firm_cc2 (time): replace inc = 0.5*(inc[_n-1] + inc[_n+1]) if missingw==1 & inc==. & inc[_n-1]!=. & inc[_n+1]!=.
	bys pid firm_cc2 (time): replace topados = 0.5*(topados[_n-1] + topados[_n+1]) if missingw==1 & inc[_n-1]!=. & inc[_n+1]!=.
	qui replace topados = 0 if topados<1
	*If previous or next observation same days worked, assign previous obs
	bys pid firm_cc2 (time): replace inc = inc[_n-1]    if days==days[_n-1] & parttime==parttime[_n-1] & missingw==1 & inc==. & inc[_n-1]!=. 
	gen negtime = -time
	bys pid firm_cc2 (negtime): replace inc = inc[_n-1] if days==days[_n-1] & parttime==parttime[_n-1] & missingw==1 & inc==. & inc[_n-1]!=. 
	drop negtime
	replace inc = 0   if missingw==1 & inc==.
	bys pid firm_cc2 (time): replace topados = topados[_n-1]    if inc==inc[_n-1] & topados[_n-1]==1 & missingw==1
	gen negtime = -time
	bys pid firm_cc2 (negtime): replace topados = topados[_n-1] if inc==inc[_n-1] & topados[_n-1]==1 & missingw==1
	drop negtime
	qui replace topados = 0 if topados==.
	
	qui replace inc_orig = . if year<1980
	qui replace inc = . if year<1980
	
	*Total income in the month if multiple employers
	bys pid year month: egen total_inc_orig=sum(inc_orig)
	bys pid year month: egen total_inc=sum(inc)

	bys pid year month: egen total_wage=sum(wage)
	qui replace total_inc  = . if (daysworked==0) 
	qui replace total_wage = . if (daysworked==0) 
	
	* EMPLEO PRINCIPAL AL MES 
	bys pid year month (tenure): gen n=_n
	bys pid year month (tenure): gen N=_N
	*If one monthly salary is missing, remove it: This typically corresponds to the last observation with an employer
	drop if inc == 0 & total_inc > 0 & total_inc!=. & N>1
	*Keep main job in the job based on tenure
	keep if n == N
	drop n N 
	label variable inc "Labor income (main employer) "
	label variable wage "Income from tax records ((main employer))"
	label variable total_inc "(total) Labor income"
	label variable total_wage "(total) Income from tax records"

	drop negemployed alta_b baja_b tag
	qui compress
	sort pid  time  alta  baja  firm_cc2
	
	* Redefino variable de años desde entrada al mercado teniendo en cuenta la posibilidad de varias relaciones laborales en un mismo mes
	bys pid (year month): gen sumdays=sum(daysworked)
	drop if sumdays==0
	drop sumdays
	qui compress

	qui gen counter=1
	bys pid (year month): gen d=((pid[_n]==pid[_n-1])&(year[_n]==year[_n-1])&(month[_n]==month[_n-1]))
	qui replace counter=0 if d==1
	qui drop d
	qui bys pid (year month): gen monthsinceentry=sum(counter)
	drop counter 
	qui compress
	label variable daysworked "DIAS DE TRABAJO EN EL MES"
	label variable simultaneous  "DIAS DE TRABAJO SIMULTÁNEOS EN EL MES"
	label variable employed "INDICADOR DE EMPLEO"
	label variable monthsinceentry "MESES DESDE LA ENTRADA AL MERCADO"
	sort pid  time  alta  baja  firm_cc2
	
	* Porcentaje trabajado
	gen dayssinceentry=monthsinceentry *30
	bys pid (year month): gen sumdays=sum(daysworked)
	gen percentage=(sumdays/dayssinceentry)*100
	drop dayssinceentry sumdays multiple  simultaneous sex
	label variable episodesmonth "TRABAJOS EN EL MES"
	label variable percentage "TIEMPO TRABAJADO DESDE LA ENTRADA AL MERCADO"
	keep if percentage>0
	drop monthsinceentry
	qui compress
	sort pid  time  alta  baja  firm_cc2

	qui compress

	*REDEFINIR TIPO DE CONTRATO
	drop contractb

	gen contractb=1 if contracttype==1|contracttype==3|contracttype==65|contracttype==100|contracttype==139|contracttype==189|contracttype==200|contracttype==239|contracttype==289
	replace contractb=2 if contracttype==8|contracttype==9|contracttype==11|contracttype==12|contracttype==13|contracttype==20|contracttype==23|contracttype==28|contracttype==29|contracttype==30|contracttype==31|contracttype==32|contracttype==33|contracttype==35|contracttype==38|contracttype==40|contracttype==41|contracttype==42|contracttype==43|contracttype==44|contracttype==45|contracttype==46|contracttype==47|contracttype==48|contracttype==49|contracttype==50|contracttype==51|contracttype==52|contracttype==59|contracttype==60|contracttype==61|contracttype==62|contracttype==63|contracttype==69|contracttype==70|contracttype==71|contracttype==80|contracttype==81|contracttype==86|contracttype==88|contracttype==89|contracttype==90|contracttype==91|contracttype==98|contracttype==101|contracttype==102|contracttype==109|contracttype==130|contracttype==131|contracttype==141|contracttype==150|contracttype==151|contracttype==152|contracttype==153|contracttype==154|contracttype==155|contracttype==156|contracttype==157|contracttype==186|contracttype==209|contracttype==230|contracttype==231|contracttype==241|contracttype==250|contracttype==251|contracttype==252|contracttype==253|contracttype==254|contracttype==255|contracttype==256|contracttype==257
	replace contractb=3 if contracttype==18|contracttype==181|contracttype==182|contracttype==183|contracttype==184|contracttype==185|contracttype==300|contracttype==309|contracttype==330|contracttype==331|contracttype==339|contracttype==350|contracttype==351|contracttype==352|contracttype==353|contracttype==354|contracttype==355|contracttype==356|contracttype==357|contracttype==389
	replace contractb=4 if contracttype==0&(TRL==901|TRL==910)
	replace contractb=4 if contracttype==0&(TRL==902)
	
	replace contractb=5 if contracttype==2|contracttype==4|contracttype==5|contracttype==16|contracttype==17|contracttype==22|contracttype==24|contracttype==64|contracttype==72|contracttype==73|contracttype==74|contracttype==75|contracttype==76|contracttype==82|contracttype==83|contracttype==84|contracttype==92|contracttype==93|contracttype==94|contracttype==95|contracttype==408|contracttype==410|contracttype==418|contracttype==500|contracttype==508|contracttype==510|contracttype==518
	replace contractb=6 if contracttype==14|contracttype==401|contracttype==501
	replace contractb=7 if contracttype==15|contracttype==402|contracttype==502
	replace contractb=8 if contracttype==6|contracttype==7|contracttype==26|contracttype==27|contracttype==36|contracttype==37|contracttype==39|contracttype==53|contracttype==54|contracttype==55|contracttype==56|contracttype==57|contracttype==58|contracttype==66|contracttype==67|contracttype==68|contracttype==77|contracttype==78|contracttype==79|contracttype==85|contracttype==87|contracttype==96|contracttype==97|contracttype==420|contracttype==421|contracttype==430|contracttype==431|contracttype==403|contracttype==452|contracttype==503|contracttype==520|contracttype==530|contracttype==531
	replace contractb=8 if contracttype==0&(TRL==87)
	replace contractb=9 if contracttype==10|contracttype==25|contracttype==34|contracttype==441|contracttype==540|contracttype==541
	replace contractb=10 if contracttype==450|contracttype==451|contracttype==457|contracttype==550|contracttype==551|contracttype==552|contracttype==557|contracttype==990
	replace contractb=10 if contracttype==0&(TRL==932)
	replace contractb=. if daysworked==0|daysworked==.
	
	label define contractlabel 1"indefinido ordinario" 2"fomento empleo" 3"fijo discontinuo" 4"funcionarios (incluye interinos)" /*
	*/ 5"duracion determinada" 6"obra o servicio" 7"circunstancia de produccion" 8"formacion" 9"relevo" 10"otros temporales"
	label values contractb contractlabel
	
	gen dummyT=(contractb==5|contractb==6|contractb==7|contractb==8|contractb==9|contractb==10)
	replace dummyT=. if contractb==.
	label variable contractb "TIPO DE CONTRATO DE TRABAJO (AGREGADO)"
	label variable dummyT "DUMMY DE CONTRATO TEMPORAL"
	
	*DIAS TRABAJADOS EN EL AÑO POR TIPO DE CONTRATO
	gen daysworked_oec = daysworked if dummyT == 0
	gen daysworked_ftc = daysworked if dummyT == 1
	
	label variable daysworked_oec "DIAS DE TRABAJO EN EL MES (Open-Ended Contract)"
	label variable daysworked_ftc "DIAS DE TRABAJO EN EL MES (Fixed-Term Contract)"
	
			
	*REDEFINIR SECTORES DE ACTIVIDAD
	gen sector  = .
	destring factivity93, replace
	destring factivity09, replace
	replace sector = 1 if inrange(factivity09,01,99)
	replace sector = 2 if inrange(factivity09,100,349)
	replace sector = 3 if inrange(factivity09,350,399)
	replace sector = 4 if inrange(factivity09,410,439)
	replace sector = 5 if inrange(factivity09,450,539)
	replace sector = 6 if inrange(factivity09,550,569)
	replace sector = 7 if inrange(factivity09,580,829)
	replace sector = 8 if inrange(factivity09,840,849)
	replace sector = 9 if inrange(factivity09,850,889)
	replace sector = 10 if inrange(factivity09,900,999)
	* Añadir al sector público aquellos que tengan firmtype = P, Q, S
	replace sector = 8 if inlist(firmtype,"P","Q","S")

	* Completar con factivity93
	replace sector = 1 if sector == .&inrange(factivity93,01,145)
	replace sector = 2 if sector == .&inrange(factivity93,150,366)
	replace sector = 3 if sector == .&inrange(factivity93,370,410)
	replace sector = 4 if sector == .&inrange(factivity93,450,455)
	replace sector = 5 if sector == .&inrange(factivity93,500,527)
	replace sector = 6 if sector == .&inrange(factivity93,550,555)
	replace sector = 5 if sector == .&inrange(factivity93,600,634)
	replace sector = 7 if sector == .&inrange(factivity93,640,748)
	replace sector = 8 if sector == .&inrange(factivity93,750,753)
	replace sector = 9 if sector == .&inrange(factivity93,800,853)
	replace sector = 10 if sector == .&inrange(factivity93,900,999)
	* Añadir al sector público aquellos que tengan firmtype = P, Q, S
	replace sector = 8 if inlist(firmtype,"P","Q","S")
	replace sector = . if daysworked==0|daysworked==.
	
	label define sectorscnae 1"Primary Sector" 2"Manufacturing" 3"Utilities" 4"Construction" ///
	5"Trade & Transport" 6"Hotel Industry" 7"Business Services" 8"Public Sector" ///
	9"(Private) Health & Education" 10"Other services", replace
	label values sector sectorscnae
	
	drop factivity*
	qui compress	
	sort pid time year month alta baja  firm_cc2
	save  "${path}\dta_files\males_2018_`c'", replace
	erase "${path}\cohorts_2018\MCVL2018_YearMonth_`c'\MCVL2018_YearMonth_`c'.dta"

}



set more off
*** Create Worker-Month files by cohort: 

use ${path}\dta_files\males_2018_1950, clear
set more off
foreach c of numlist 1951/1964{
qui	append using ${path}\dta\_filesmales_2018_`c'
}	
*drop if year<1980
qui compress
sort pid month
save ${path}\dta_files\m2018_bboomers_males.dta, replace

use ${path}\dta\males_2018_1965, clear
set more off
foreach c of numlist 1966/1980{
qui	append using ${path}\dta_files\males_2018_`c'
}	
*drop if year<1980
qui compress
sort pid month
save ${path}\dta_files\m2018_genx_males.dta, replace

use ${path}\dt_files\males_2018_1981, clear
set more off
foreach c of numlist 1997/2002{
qui	append using ${path}\dta_files\males_2018_`c'
}	
*drop if year<1980
qui compress
sort pid month
save ${path}\dta_files\m2018_millennials_males.dta, replace

forvalues c=1950/2002 {
erase ${path}\dta_files\males_2018_`c'.dta
}



