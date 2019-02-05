* add korea and mexico production dummies

/*
Sources:
https://en.wikipedia.org/wiki/List_of_Kia_design_and_manufacturing_facilities#Kia_Motors_Manufacturing_Georgia_(KMMG)
https://en.wikipedia.org/wiki/Hyundai_Motor_Manufacturing_Alabama

*/

gen production_korea=0
gen production_mexico=0

replace production_korea=1 if inlist(make,"KIA","HYUNDAI","DAEWOO (GM)")
replace production_korea=0 if model=="SORENTO" & year>=2010
replace production_korea=0 if model=="SORENTO" & year>=2011
replace production_korea=0 if model=="SONATA" & year>=2005
replace production_korea=0 if model=="ELANTRA" & year>=2005
replace production_korea=0 if model=="SANTA FE" & year>=2007 // Kia Georgia produced 2010-2016

replace production==
