clear all
capture log close
capture program drop _all
macro drop _all
set more 1
set seed 13

foreach g in males females {
foreach c in bboomers genx millennials {

use ${path}\dta_files\m2018_`c'_`g'.dta, clear

qui drop if yofd(dofm(end))<1980 // exclude workers who exit before start observation period

*No needed variables
qui drop employed tenure regime birthdate disability alta_firm TRL ETT employertype firmtype empresa newcontractdate1 newcontractdate2 newcontributiongroupdate SETA TRaut contracttype permanent start end entryage percentage especie death address incaut

tab educ,  m
*Use longidutinal observations to recover missing values of education - look at the latests waves, more reliable info
*Impute backwards missing education using most recent data - set age 25 as threshold for tertiary education (OECD data of the most common college graduation age in Spain)
qui replace age = int(age)
qui g negtime = -time
qui bys pid (negtime):  replace education=education[_n-1] if education[_n-1]!=. & (education[_n-1]>=education | education==.) & age>=25
qui bys pid (negtime):  replace education=education[_n-1] if education[_n-1]!=. & education==. & education[_n-1]<50 &  age<25
qui bys pid (time):     replace education=education[_n-1] if education==. & education[_n-1]!=.
*Correct some typos: individuals with lower educational attainment as they become older
qui bys pid (time): replace education=education[_n-1] if education[_n-1]!=. & education[_n-1]>education & age[_n-1]<age
*Fill missing info
foreach var in education {
qui bys pid (negtime): replace `var'=`var'[_n-1] if `var'==.
}
qui drop negtime
*Declare LM entry based on predicted graduation year: Similar to Arellano-Bover 2020
*Max level of education 
qui bys pid: egen max=max(education)
qui replace education = max // highest education attainment
qui drop max

*Education categories
qui g educ=.
qui replace educ=1 if education<30
qui replace educ=2 if education>=30 & education<=40 
qui replace educ=3 if education>=50 & education!=.
qui label var educ "Education (max. attainment)"
qui label define educlb 1 "HS drop-outs" 2 "HS" 3 "College", modify
qui label values educ educlb
qui drop education

*Predicted graduation year
qui gen pygrad = .
qui replace pygrad  = yearbirth + 16 if educ==1
qui replace pygrad  = yearbirth + 18 if educ==2
qui replace pygrad  = yearbirth + 23 if educ==3
qui label var pygrad "Graduation year"

*Keep only observations after graduation
qui drop if yofd(dofm(time))<=pygrad
*Drop job spells if started long before graduation and finish after -- assume is a training period, no direct LM experience
qui gen dur = mdy(1,1,pygrad+1) -  alta  + 1
qui drop if yofd(alta)<pygrad & dur>=540 // drop also spells that started long before graduation and on-going after for short time 
qui drop dur 


*Employment definition:  worked at least a full week or earnings at least one-eight of monthly MW, income equivalent of a week of full-time work at half the minimum wage
qui gen NMW = min_base if group==10
qui bys year (NMW): replace NMW = NMW[1] if NMW==.
qui g E       = (total_inc>NMW/8 & total_inc<.) & year>=1980
qui replace E = 1 if daysworked > 7 & year<1980
qui replace E = 0 if daysworked <= 7 & year<1980
*Drop individuals who have the first employment observation more than 5 years after graduation
qui bys pid E (time): gen nobs = _n
qui gen dateE1 = time if nobs == 1
qui format dateE1 %tm
qui replace dateE1 = . if E==0
qui bys pid (dateE1): replace dateE1 = dateE1[1] if dateE1==.
qui drop nobs
qui label var dateE1 "1st Emp observation"

*Adjust censored observations, the incidence of the corrections below are higher (i) in the 1980s, (ii) early career, and (iii) low skill occ categories
*On average around 1% of the wage observations are above the maximum but are not labeled as top-coded , re-define top-coding variable
qui replace topados = 1 if topados==0 & inc>=max_base & inc!=. 
*On average around 1/3 percent of the top-coded observations are above the legal maximum (almost 0 after 2000s, around 80 percent in the 80s)
*Median difference between observed income and legal maximum when income above the the maximum is around 20 euros
*Set monthly labor income at the maximum when above the maximum 
qui replace total_inc = total_inc - inc + max_base if topados==1 & max_base!=.
qui replace inc       = max_base  if topados==1 & max_base!=.

*Income and other monetary variables in real terms using CPI2018 
qui merge m:1 month year using ${path}\dta\cpi2018m.dta, keep(1 3) keepusing(cpi2018)
qui replace inc = inc/(cpi2018/100)
qui replace total_inc = total_inc/(cpi2018/100)
qui replace max_base = max_base/(cpi2018/100)
qui replace min_base = min_base/(cpi2018/100)
qui replace NMW = NMW/(cpi2018/100)
qui drop _m cpi*  *_orig
qui label var NMW "National minimum wage"

*Daily wages
qui g dailyw = inc/days

label var dailyw     "Daily wage (main employer)"
label var total_inc  "Monthly earnings (total)"

qui compress

*Recover occupation group missing category using longitudinal information on the job relation
tab group if E==1, m 
qui replace group = . if group<1 | group>12
qui replace group = 11 if group!=. & group>10
tab group if E==1, m
qui g negtime = -time
qui bys pid firm_cc2 (time):    replace group=group[_n-1] if group==. & group[_n-1]!=. & E==1 & E==E[_n-1]
qui bys pid firm_cc2 (negtime): replace group=group[_n-1] if group==. & group[_n-1]!=. & E==1 & E==E[_n-1]
tab group if E==1, m
*If still some missing values, assign previous-job skill - if after this skill is still missing, remove the individual
qui bys pid E (time):    replace group=group[_n-1] if group==. & group[_n-1]!=. & E==1 & E==E[_n-1]
tab group if E==1, m
qui g flag1 = 1 if group==. & E==1
qui bys pid (flag1): replace flag1=flag1[1] if flag1==.
*Create 3 skill categories
qui gen skill = .
qui replace skill = 1 if  group >= 8 & group <= 11 & E==1
qui replace skill = 2 if (group == 4 | group == 5 | group == 6 | group ==7) & E==1
qui replace skill = 3 if (group == 1 | group == 2 | group == 3) & E==1
qui label var skill "Skill level"
qui label define skilllb 1 "Low-skill" 2 "Mid-skill" 3 "High-skill", modify
qui label values skill skilllb
tab skill if E==1, m

*Sector of activity: time invariant and recover missing values
tab sector if E==1, m
qui bys firm_cc2: egen mode=mode(sector) if E==1, max
qui replace sector=mode if E==1
tab sector if E==1, m
*For baby-boomers there are 25% of obs with at least one observation with missing sector that cannot be recovered 
*assign the closest sector in time to recover as much information as possible - if after this sector still missing missing, remove the individual
qui bys pid E (time):    replace sector = sector[_n-1] if sector==. & sector[_n-1]!=. & E==1 & E==E[_n-1]
qui bys pid E (negtime): replace sector = sector[_n-1] if sector==. & sector[_n-1]!=. & E==1 & E==E[_n-1]
tab sector if E==1, m
qui g flag2 = 1 if sector==. & E==1
qui bys pid (flag2): replace flag2=flag2[1] if flag2==.
qui drop negtime mode
qui label var sector "Sector of activity"

*Employer creation and age categories
qui replace firm_age = int(firm_age)
qui g fage = 1 if firm_age<=3 & E==1
qui replace fage = 2 if (firm_age>3 & firm_age<10) & E==1
qui replace fage = 3 if firm_age>=10 & E==1
qui label var fage "Firm age"
qui label define fagelb 1 "Firm age<=3" 2 "Firm age (3-10)" 3 "Firm age>=10", modify
qui label values fage fagelb

*Employer location
qui g provfirm_cc2=real(substr(firm_cc2,5,2))
*Label provinces
quietly {
label define provincelb 1 `"ARABA/ALAVA"', modify
label define provincelb 2 `"ALBACETE"', modify
label define provincelb 3 `"ALACANT"', modify
label define provincelb 4 `"ALMERIA"', modify
label define provincelb 5 `"AVILA"', modify
label define provincelb 6 `"BADAJOZ"', modify
label define provincelb 7 `"BALEARES"', modify
label define provincelb 8 `"BARCELONA"', modify
label define provincelb 9 `"BURGOS"', modify
label define provincelb 10 `"CACERES"', modify
label define provincelb 11 `"CADIZ"', modify
label define provincelb 12 `"CASTELLO"', modify
label define provincelb 13 `"CIUDAD REAL"', modify
label define provincelb 14 `"CORDOBA"', modify
label define provincelb 15 `"CORUÑA"', modify
label define provincelb 16 `"CUENCA"', modify
label define provincelb 17 `"GIRONA"', modify
label define provincelb 18 `"GRANADA"', modify
label define provincelb 19 `"GUADALAJARA"', modify
label define provincelb 20 `"GIPUZCOA"', modify
label define provincelb 21 `"HUELVA"', modify
label define provincelb 22 `"HUESCA"', modify
label define provincelb 23 `"JAEN"', modify
label define provincelb 24 `"LEON"', modify
label define provincelb 25 `"LLEIDA"', modify
label define provincelb 26 `"RIOJA"', modify
label define provincelb 27 `"LUGO"', modify
label define provincelb 28 `"MADRID"', modify
label define provincelb 29 `"MALAGA"', modify
label define provincelb 30 `"MURCIA"', modify
label define provincelb 31 `"NAVARRA"', modify
label define provincelb 32 `"OURENSE"', modify
label define provincelb 33 `"ASTURIAS"', modify
label define provincelb 34 `"PALENCIA"', modify
label define provincelb 35 `"LAS PALMAS"', modify
label define provincelb 36 `"PONTEVEDRA"', modify
label define provincelb 37 `"SALAMANCA"', modify
label define provincelb 38 `"TENERIFE"', modify
label define provincelb 39 `"CANTABRIA"', modify
label define provincelb 40 `"SEGOVIA"', modify
label define provincelb 41 `"SEVILLA"', modify
label define provincelb 42 `"SORIA"', modify
label define provincelb 43 `"TARRAGONA"', modify
label define provincelb 44 `"TERUEL"', modify
label define provincelb 45 `"TOLEDO"', modify
label define provincelb 46 `"VALENCIA"', modify
label define provincelb 47 `"VALLADOLID"', modify
label define provincelb 48 `"BIZCAIA"', modify
label define provincelb 49 `"ZAMORA"', modify
label define provincelb 50 `"ZARAGOZA"', modify
label define provincelb 51 `"CEUTA"', modify
label define provincelb 52 `"MELILLA"', modify
}
qui label var provfirm_cc2  "Plant location (province)"
label values province provincelb
qui label values provfirm_cc2 provincelb

*Create observations between graduation year and first employment if there is non-employment time
tempfile tempdta
preserve
qui keep pid time dateE1 pygrad 
qui bys pid (time): gen first= _n == 1
qui keep if first==1
qui drop if time==mofd(mdy(1,1,pygrad+1))
gen nobs= (dateE1 - mofd(mdy(1,1,pygrad+1))) 
expand nobs

gen mobs=mofd(mdy(1,1,pygrad+1))
qui bys pid (time): replace mobs = mobs + _n - 1
qui drop if mobs >= time
qui replace time = mobs if mobs!=.
qui drop first dateE1 pygrad nobs
save `tempdta', replace
restore

append using `tempdta'
qui drop mobs

*Fill within panel gaps: creates unemployment observations
xtset pid time
tsfill

*Fill in and adjust info in created obs
qui replace month = month(dofm(time)) if month==.
qui replace year  = yofd(dofm(time))  if year==.
qui replace days = 0 if days==.
qui replace daysworked = 0 if daysworked==.
qui replace E = 0 if daysworked==0
qui gen negtime = -time
quietly {
replace province = . if province<1 | province>52 // not valid province
foreach v in dateE1 pygrad educ province yearbirth province tamanno tamanno_06 tamanno_715 tamanno_m65 n_male n_female {
bys pid (negtime): replace `v' = `v'[_n-1] if `v' == .
bys pid (time): replace `v' = `v'[_n-1] if `v' == .
}
drop negtime
}

gen ageb=year-yearbirth
replace age=ageb if age==.
drop ageb

qui replace skill = 1 if  group >= 8 & group <= 11 & E==1
qui replace skill = 2 if (group == 4 | group == 5 | group == 6 | group ==7) & E==1
qui replace skill = 3 if (group == 1 | group == 2 | group == 3) & E==1

*Sample restrictions - missing info key variables
*Restrictions drop workers' history
gunique pid
drop if province == .
gunique pid
drop if educ == .
gunique pid
qui label var flag1 "Skill corrected"
drop if flag1==1
gunique pid
qui label var flag2 "Sector corrected"
drop if flag2==1
gunique pid

qui compress

save ${path}\dta_files\asample_`c'_`g'.dta, replace
}
}
