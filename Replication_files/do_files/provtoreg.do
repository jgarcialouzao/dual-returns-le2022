gen region=.
label variable region "Region (CC.AA)"
replace region=1  if province==4 | province==11 | province==14 | province==18 | province==21 | province==23 | province==29 | province==41
replace region=2  if province==22 | province==44 | province==50
replace region=3  if province==39
replace region=4  if province==5 | province==9 | province==24 | province==34 | province==37 | province==40 | province==42 | province==47 | province==49
replace region=5  if province==2 | province==13 | province==16 | province==19 | province==45
replace region=6  if province==8 | province==17 | province==25 | province==43
replace region=7  if province==28
replace region=8  if province==3 | province==12 | province==46
replace region=9  if province==6 | province==10
replace region=10 if province==15 | province==27 | province==32 | province==36 
replace region=11 if province==7
replace region=12 if province==35 | province==38
replace region=13 if province==26
replace region=14 if province==31
replace region=15 if province==1 | province==20 | province==48
replace region=16 if province==33
replace region=17 if province==30
replace region=18 if province==51 | province==52
label define regionlb 1 "Andalusia"  2 "Aragon"  3 "Cantabria"  4 "Castile and Leon"  5 "Castile La-Mancha" 6 "Catalonia" 7 "Madrid"  8 "Valencia" 9 "Extremadura"  ///
						   10 "Galicia"  11 "Balearic Islands" 12 "Canary Islands" 13 "La Rioja" 14 "Navarre"  15 "Basque Country"  16 "Asturias" 17 "Murcia" 18 "Ceuta y Melilla", modify
label values region regionlb
