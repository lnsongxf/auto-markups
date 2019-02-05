*--------------------------------------------------
* Clean characteristics data (from upwork)
* clean-chars.do
* 12/15/2018
* Charlie Murry (BC) | Paul Grieco (PSU) | Ali Yurukoglu (Stanford)
*
*--------------------------------------------------

*--------------------------------------------------
* Program Setup
*--------------------------------------------------
version 15              // Set Version number for backward compatibility
set more off            // Disable partitioned output
set autotabgraphs on    // Graphs appear in a single window
clear all               // Start with a clean slate
set linesize 80         // Line size limit to make output more readable
macro drop _all         // clear all macros
capture log close       // Close existing log files
log using clean-chars.log, text replace      // Open log file
* --------------------------------------------------
/*
## Description

This script cleans the Ward's specs data and finds the base model.
We will use 2 defns of "base model."
1) The base model listed in Ward's
2) The first/base 4-door (sedan) model listed in Ward's
*/


*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

/*
Run once to save to dta -- quicker load fr code testing
import excel ${RAW}Cars_Characteristics.xlsx, sheet("Summary") firstrow case(lower)
save ${DER}Cars_Characteristics.dta, replace
*/
use ${DER}Cars_Characteristics.dta

drop if line_type=="HEADER"   // used to mark makes for inital clean
drop word*                    // used to mark makes for inital clean

rename final_series model

* Fix model names that are not correct from upwork
do fix-model-names.do

* How things are originally ordered from Ward's (to find "base" model)
gen master_roworder = _n

** create variable which is the number of trims per make/model
bysort make model year: egen trims_num = count(model)
sort master_roworder

** fix bodystyles
replace bodystyle="" if bodystyle=="x"
replace bodystyle="" if bodystyle=="`"
replace bodystyle="" if bodystyle=="-"
replace bodystyle="" if bodystyle=="--"
replace bodystyle="" if bodystyle=="_"
replace bodystyle="" if bodystyle=="0"
replace bodystyle="" if bodystyle=="O"

** extract number of doors
gen doors = .
replace doors=2 if regexm(makeseries,"2-dr") == 1
replace doors=3 if regexm(makeseries,"3-dr") == 1
replace doors=4 if regexm(makeseries,"4-dr") == 1
replace doors=5 if regexm(makeseries,"5-dr") == 1

replace doors=2 if regexm(makeseries,"2-door") == 1 & doors==.
replace doors=3 if regexm(makeseries,"3-door") == 1 & doors==.
replace doors=4 if regexm(makeseries,"4-door") == 1 & doors==.
replace doors=5 if regexm(makeseries,"5-door") == 1 & doors==.

replace doors=2 if regexm(bodystyle,"2-dr") == 1 & doors==.
replace doors=2 if regexm(bodystyle,"3-dr") == 1 & doors==.
replace doors=4 if regexm(bodystyle,"4-dr") == 1 & doors==.
replace doors=5 if regexm(bodystyle,"5-dr") == 1 & doors==.

replace doors=2 if regexm(bodystyle,"2-door") == 1 & doors==.
replace doors=2 if regexm(bodystyle,"3-door") == 1 & doors==.
replace doors=4 if regexm(bodystyle,"4-door") == 1 & doors==.
replace doors=5 if regexm(bodystyle,"5-door") == 1 & doors==.

replace doors=2 if regexm(makeseries,"coupe") == 1 & doors==.
replace doors=4 if regexm(makeseries,"sedan") == 1 & doors==.
replace doors=4 if regexm(makeseries,"wagon") == 1 & doors==.


** Extract bodystyle from Ward's series names

* first get rid of "doors" in current bodystyle variable
local BSLIST=". -dr -door 2 3 4 5"
foreach ix in `BSLIST' {
  replace bodystyle = subinstr(bodystyle,"`ix'","",5)
}
replace bodystyle = subinstr(bodystyle," ","",5)
replace bodystyle = trim(lower(bodystyle))

* extract bodystyle from Ward's series
replace bodystyle="sedan" if bodystyle=="" & regexm(id," SED") == 1
replace bodystyle="pu" if bodystyle=="" & regexm(id,"P.U.") == 1
replace bodystyle="pu" if bodystyle=="" & regexm(id," PICKUP") == 1
replace bodystyle="suv" if bodystyle=="" & regexm(id," SUV") == 1
replace bodystyle="suv" if bodystyle=="" & regexm(id," SSUV") == 1
replace bodystyle="hatchback" if bodystyle=="" & regexm(id," HATCH") == 1
replace bodystyle="conv" if bodystyle=="" & regexm(id," CONV") == 1
replace bodystyle="wagon" if bodystyle=="" & regexm(id," WAG") == 1
replace bodystyle="wagon" if bodystyle=="" & regexm(id," VAN") == 1

* fix issues
replace bodystyle = "conv" if bodystyle=="convertible"
replace bodystyle = "conv" if bodystyle=="converticle"
replace bodystyle = "conv" if bodystyle=="cabriolet"
replace bodystyle = "conv" if bodystyle=="hardtop"
replace bodystyle = "coupe" if bodystyle=="conv"
replace bodystyle = "pu" if bodystyle=="pv"
replace bodystyle = "hatchback" if bodystyle=="natchback"

** Export list of unknown bodystyles to hand collect data
* We use an edmunds api query of squish vins from Charlie's middleman paper to help
tab bodystyle, m

/* preserve
  keep if bodystyle==""
  keep make model
  duplicates drop make model, force
  save ${DER}fill-bodystyle.dta, replace
restore */

preserve
  import excel using ${DER}fill-bodystyle.xlsx, clear firstrow
  sort make model
  save ${DER}fill-bodystyle-wards-done.dta, replace
restore
merge m:1 make model using ${DER}fill-bodystyle-wards-done.dta, update replace
drop if _merge==2
drop _merge

replace bodystyle = "conv" if bodystyle=="convertible"
replace bodystyle = "hatchback" if bodystyle=="hatcbak"
replace bodystyle = "wagon" if bodystyle=="wagin"
replace bodystyle = "sedan" if bodystyle=="wagin"
replace bodystyle = "truck" if bodystyle=="pu"
replace bodystyle = "suv" if bodystyle=="cuv"
replace bodystyle = "coupe" if bodystyle=="sportscar"
replace bodystyle = "truck" if bodystyle=="pickup truck"
replace bodystyle = "wagon" if bodystyle=="station wagon"
replace bodystyle = "truck" if bodystyle=="cabchassis"
replace bodystyle = "sedan" if bodystyle=="sedan "

tab bodystyle, m

replace bodystyle = "sedan" if model=="SATURN S"
replace bodystyle = "truck" if model=="T10/T15"
replace bodystyle = "van" if model=="VOYAGER"


** Extract base transmission
gen trans_type = substr(standardenginetrans,1,1)  // "C" is CVT which is continuous variable trans.
replace trans_type = "M" if trans_type == "("
replace trans_type = "M" if trans_type == "5"
replace trans_type = "" if ~inlist(trans_type,"A","M","C")

** Clean up prices and destring mpg hp -- I should export a list of non-msrps to see if we can hand collect them
destring pricemsrp, force replace ignore(",")
replace pricemsrp = . if pricemsrp<3000   // just a few odd prices

keep year make model bodystyle-electricfederaltaxcredit doors trans_type makeseries master_roworder trims_num

* ******************************************************************************
** define characteristics we will use
* ******************************************************************************
/*
From BLP:
number of cylinders, number of doors, weight, engine displacement, horsepower,
length, width, wheelbase, EPA miles per gallon rating (MPG), and dummy variables
for whether the car has front wheel drive, automatic transmission, power steering,
and air conditioning as standard equipment.
*/

rename standardenginesizeliter engine_liter
rename standardenginenethprpmnet engine_horsepower
rename overallsizeinslengthstd size_length
rename overallsizeinswidthins size_width
rename weightlbscurbstd size_weight
rename trans_type engine_trans
rename standardenginetractioncontro traction_control
rename standardengineabs abs
rename standardengineestmpghwy mpg
rename standardenginestabilitycontr stability
rename wheelbasewheelbaseinsstd size_wheelbase

gen electric=1 if electricelectricmotortype!=""
replace electric=0 if electric!=1

destring size_width, force replace
destring size_wheelbase, force replace
destring size_weight, force replace
destring mpg, force replace
destring engine_horsepower, force replace
destring size_length, force replace
destring engine_liter, force replace

foreach ix in engine_horsepower size_width size_length size_wheelbase size_weight mpg engine_liter {
  replace `ix'=. if `ix'==0
}

* ******************************************************************************
* Define base trim
*   We use the first trim listed in the Ward's database.
*   Ex. BMW 328i
*   This trim typically has the smallest engine, weighs the least, and has
*     2 doors in some cases.
* ******************************************************************************

replace doors=4 if bodystyle=="sedan"
replace doors=2 if bodystyle=="coupe"
replace doors=4 if bodystyle=="suv"
replace doors=4 if bodystyle=="wagon"

** Fill in missig specs (before getting base model)
* the key is that we do this by makeseries, which is essentially the trim.
* Do this before we select base trim because we want the sub-trim level to match
replace pricemsrp = (pricemsrp[_n-1]+pricemsrp[_n+1])/2 if pricemsrp==. ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1 ///
  & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1 & year>1989

sort make makeseries year
replace pricemsrp = pricemsrp[_n-1] if pricemsrp==. ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1
replace pricemsrp = pricemsrp[_n+1] if pricemsrp==. ///
    & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1

* replace doors
replace doors = doors[_n-1] if doors==. ///
    & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1
replace doors = doors[_n+1] if doors==. ///
    & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1

local REPLACE "size_width size_wheelbase size_length engine_horsepower engine_liter size_weight mpg"
des `REPLACE'

foreach ix in `REPLACE' {
replace `ix' = `ix'[_n-1] if `ix'==. ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1
replace `ix' = `ix'[_n+1] if `ix'==. ///
  & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1
}

local REPLACE_STR "engine_trans traction_control abs stability"
foreach ix in `REPLACE_STR' {
replace `ix' = `ix'[_n-1] if `ix'=="" ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1
replace `ix' = `ix'[_n+1] if `ix'=="" ///
  & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1
tab `ix'
}

sum `REPLACE'

* *************************************************************************
* Specification 1: TAKE FIRST ENTRY ACCORDING TO ORIGINAL WARDS ORDERING
* *************************************************************************
/* preserve */
sort year make model master_roworder
by year make model: keep if _n==1


** Some more baindaids
** Hard-coded fixes
replace pricemsrp = 42630 if make=="ACRUA" & model=="ACURA RL" & year==2000 // change, this was just wrong
replace pricemsrp=30170  if make=="CHEVROLET" & model=="CAPRICE" & year==2011
replace pricemsrp=30920  if make=="CHEVROLET" & model=="CAPRICE" & year==2012
replace pricemsrp=31420  if make=="CHEVROLET" & model=="CAPRICE" & year==2013
replace pricemsrp=32475  if make=="CHEVROLET" & model=="CAPRICE" & year==2014
replace pricemsrp=32675  if make=="CHEVROLET" & model=="CAPRICE" & year==2015
replace pricemsrp=23435  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2012
replace pricemsrp=24225  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2013
replace pricemsrp=24360  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2014
replace pricemsrp=24370  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2015
replace pricemsrp=14355  if make=="FORD" & model=="PROBE" & year==1997
replace pricemsrp=12475  if make=="VOLKSWAGEN" & model=="GOLF" & year==1993
replace pricemsrp=20400  if make=="MINI" & model=="MINI COOPER" & year==2013
replace pricemsrp=16150  if make=="SCION" & model=="SCION IQ" & year==2013
replace pricemsrp=66000  if make=="DODGE" & model=="VIPER" & year==1997
replace pricemsrp=23515  if make=="TOYOTA" & model=="HIGHLANDER" & year==2001
replace pricemsrp=19159  if make=="NISSAN" & model=="NISSAN 240SX" & year==1997
replace pricemsrp=38200  if make=="TOYOTA" & model=="SUPRA" & year==1997
replace pricemsrp=33900  if make=="TOYOTA" & model=="SUPRA" & year==1993
replace pricemsrp=20195  if make=="MAZDA" & model=="MX-6" & year==1997
replace pricemsrp=19125  if make=="MAZDA" & model=="MX-5 MIATA" & year==1997
replace pricemsrp=29905  if make=="FORD" & model=="CROWN VICTORIA" & year==2011
replace pricemsrp=29905  if make=="FORD" & model=="CROWN VICTORIA" & year==2010
replace pricemsrp=112949  if make=="HUMMER" & model=="HUMMER H1" & year==2002
replace pricemsrp=13470  if make=="JEEP" & model=="WRANGLER" & year==1996
replace pricemsrp=21275  if make=="PONTIAC" & model=="G6" & year==2010

** adjusted price (by taxes/subsidies) to merge with BLP data
destring guzzlertax, force replace ignore(",")
replace guzzlertax=0 if guzzlertax==.
destring electricfederaltaxcredit, force replace ignore(",")
replace electricfederaltaxcredit=0 if electricfederaltaxcredit==.

gen prices = (pricemsrp + guzzlertax - electricfederaltaxcredit)/1000

sort year make model pricemsrp

* This collapse is redundnat because we already have unique values -- but but in cleans up the data.
/* collapse (firstnm) engine_liter engine_horsepower size_length size_weight size_width size_wheelbase engine_trans ///
  traction_control abs mpg electric doors bodystyle drivetype stability prices, by(year make model) */

keep engine_liter engine_horsepower size_length size_weight size_width size_wheelbase engine_trans ///
  traction_control abs mpg electric doors bodystyle drivetype stability prices year make model

order year make model prices

sort year
merge m:1 year using ${DER}cpi.dta, assert(2 3) keep(3)
drop _merge
merge m:1 year using ${DER}gas-price.dta, assert(2 3) keep(3)
drop _merge

replace gas = gas/cpi
replace prices = prices/cpi

* miles per $
gen mpd = mpg/gas/10

* BLP's acceleration
gen hpwt = 10*engine_horsepower / size_weight

* BLP's size
gen space = size_length * size_width/10000

sort make model year
save "${DER}wards-chars.dta", replace
restore

* *************************************************************************
* Specification 2: TAKE FIRST ENTRY with 4-doors (IF IT EXISTS)
* *************************************************************************


** TAKE THE FIRST SEDAN / 4-DR ACCORDING TO WARDS ORDERING

* save a dataset of just the year seriesnames master_roworder make model year
* merge back by year make modle and for those that merge drop the 2-dr models



/*
Things to do after the merge with BLP:
1) create a design year
2) check to make sure scale of variables is correct
3) double check extreme values for specs.
*/






/*
OLS CODE
%%%%%%%%%%%%%%%%%%%%%%%%


sort make model year
* drop if pricemsrp==.  // 390/30,036 dropped

* keep the lowest msrp 4 door version in the case when there are 2-drs and 4-drs.
bysort year make model: egen maxdoors=max(doors)
bysort make model: egen maxdoors_plus=max(doors)
replace maxdoors = maxdoors_plus if maxdoors==.
bysort year make model: egen mindoors=min(doors)
bysort make model: egen mindoors_plus=min(doors)
replace mindoors = mindoors_plus if mindoors==.
drop if maxdoors==4 & doors==2 & bodystyle !="pu"
drop if maxdoors==4 & doors==3 & bodystyle !="pu"
drop if doors>2 & mindoors==2 & bodystyle == "pu"


* If auto trans available, take the auto trans version
// sort make model year trans_type
// bysort make model year: egen auto_trans_available = first(trans_type)
// replace auto_trans_available = "no" if auto_trans_available!="A"
// replace auto_trans_available = "yes" if auto_trans_available=="A"
//
// drop if trans_type !="A" & auto_trans_available=="yes"



* NOW TAKE FIRST ENTRY ACCORDING TO ORIGINAL WARDS ORDERING
/*
Note on trims: see 1991 Acura Integra. The three trims are identical according to the data.
However, the pricemsrp differs. So it must be non-structural things about the car, like
leather, sound system, etc. (actually, the more expensive one is 50lbs heavier, so it might have
a spoiler?).
You could think of the the higher trims representing the demand for leather interiors, not
a fundementally different car.
*/
sort year make model master_roworder
by year make model: keep if _n==1



** Some more baindaids
** Hard-coded fixes
order year make model pricemsrp doors bodystyle overallsizeinslengthstd
replace pricemsrp = 42630 if make=="ACRUA" & model=="ACURA RL" & year==2000 // change, this was just wrong
replace pricemsrp=30170  if make=="CHEVROLET" & model=="CAPRICE" & year==2011
replace pricemsrp=30920  if make=="CHEVROLET" & model=="CAPRICE" & year==2012
replace pricemsrp=31420  if make=="CHEVROLET" & model=="CAPRICE" & year==2013
replace pricemsrp=32475  if make=="CHEVROLET" & model=="CAPRICE" & year==2014
replace pricemsrp=32675  if make=="CHEVROLET" & model=="CAPRICE" & year==2015
replace pricemsrp=23435  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2012
replace pricemsrp=24225  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2013
replace pricemsrp=24360  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2014
replace pricemsrp=24370  if make=="CHEVROLET" & model=="CAPTIVA SPORT" & year==2015
replace pricemsrp=14355  if make=="FORD" & model=="PROBE" & year==1997
replace pricemsrp=12475  if make=="VOLKSWAGEN" & model=="GOLF" & year==1993
replace pricemsrp=20400  if make=="MINI" & model=="MINI COOPER" & year==2013
replace pricemsrp=16150  if make=="SCION" & model=="SCION IQ" & year==2013
replace pricemsrp=66000  if make=="DODGE" & model=="VIPER" & year==1997
replace pricemsrp=23515  if make=="TOYOTA" & model=="HIGHLANDER" & year==2001
replace pricemsrp=19159  if make=="NISSAN" & model=="NISSAN 240SX" & year==1997
replace pricemsrp=38200  if make=="TOYOTA" & model=="SUPRA" & year==1997
replace pricemsrp=33900  if make=="TOYOTA" & model=="SUPRA" & year==1993
replace pricemsrp=20195  if make=="MAZDA" & model=="MX-6" & year==1997
replace pricemsrp=19125  if make=="MAZDA" & model=="MX-5 MIATA" & year==1997
replace pricemsrp=29905  if make=="FORD" & model=="CROWN VICTORIA" & year==2011
replace pricemsrp=29905  if make=="FORD" & model=="CROWN VICTORIA" & year==2010
replace pricemsrp=112949  if make=="HUMMER" & model=="HUMMER H1" & year==2002
replace pricemsrp=13470  if make=="JEEP" & model=="WRANGLER" & year==1996
replace pricemsrp=21275  if make=="PONTIAC" & model=="G6" & year==2010


/* drop if pricemsrp==. */


* ******************************************************************************
** define characteristics we will use
* ******************************************************************************
/*
From BLP:
number of cylinders, number of doors, weight, engine displacement, horsepower,
length, width, wheelbase, EPA miles per gallon rating (MPG), and dummy variables
for whether the car has front wheel drive, automatic transmission, power steering,
and air conditioning as standard equipment.
*/

rename standardenginesizeliter engine_liter
rename standardenginenethprpmnet engine_horsepower
rename overallsizeinslengthstd size_length
rename overallsizeinswidthins size_width
rename weightlbscurbstd size_weight
rename trans_type engine_trans
rename standardenginetractioncontro traction_control
rename standardengineabs abs
rename standardengineestmpghwy mpg
rename standardenginestabilitycontr stability
rename wheelbasewheelbaseinsstd size_wheelbase

gen electric=1 if electricelectricmotortype!=""
replace electric=0 if electric!=1

destring size_width, force replace
destring size_wheelbase, force replace
destring size_weight, force replace
destring standardengineestmpghwy, force replace
destring standardenginenethprpmnet, force replace

** adjusted price (by taxes/subsidies) to merge with BLP data
destring guzzlertax, force replace ignore(",")
replace guzzlertax=0 if guzzlertax==.
destring electricfederaltaxcredit, force replace ignore(",")
replace electricfederaltaxcredit=0 if electricfederaltaxcredit==.

gen prices = (pricemsrp + guzzlertax - electricfederaltaxcredit)/1000


/*
Note on trims: see 1991 Acura Integra. The three trims are identical according to the data.
However, the pricemsrp differs. So it must be non-structural things about the car, like
leather, sound system, etc. (actually, the more expensive one is 50lbs heavier, so it might have
a spoiler?).
You could think of the the higher trims representing the demand for leather interiors, not
a fundementally different car.
*/

sort year make model pricemsrp

* This collapse is redundnat because we already have unique values -- but but in cleans up the data.
collapse (firstnm) engine_liter engine_horsepower size_length size_weight size_width size_wheelbase engine_trans ///
  traction_control abs mpg electric doors bodystyle drivetype stability prices, by(year make model)

order year make model prices

* make zeros .'s
destring size_length, force replace
destring size_width, force replace
foreach ix in engine_horsepower size_width size_length size_wheelbase size_weight {
  replace `ix'=. if `ix'==0
}

sort year

merge m:1 year using ${DER}cpi.dta, assert(3 2) keep(3)
drop _merge
merge m:1 year using ${DER}gas-price.dta, assert(3 2) keep(3)
drop _merge

replace gas = gas/cpi
replace prices = prices/cpi

* miles per $
gen mpd = mpg/gas/10

* BLP's acceleration
gen hpwt = 10*engine_horsepower / size_weight

* BLP's size
gen space = size_length * size_width/1000

/* sort year make model */
/* save "${DER}wards-chars.dta", replace */

* create make and design year
sort make model year
save "${DER}wards-chars.dta", replace




** make t-1 variables for all variables to see if everything stays the same by 10%
* See BLP page 869: "...their horsepower, width, length, or wheelbase do not change by more than ten percent..."

/*


*** Save this next part for when all the data is merged
// foreach ix in engine_horsepower size_width size_length size_wheelbase {
//   gen lag_`ix' = `ix'[_n-1]
//   replace lag_`ix' = . if model!=model[_n-1] & year!=year[_n-1]+1
// }
//
// gen same_design = 0
// replace same_design = 1 if ///
//   engine_horsepower < lag_engine_horsepower + .1*lag_engine_horsepower ///
//   & size_width < lag_size_width + .1*lag_size_width ///
//   & size_length < lag_size_length + .1*lag_size_length ///
//   & size_wheelbase < lag_size_wheelbase + .1*lag_size_wheelbase ///
//   & engine_horsepower > lag_engine_horsepower - .1*lag_engine_horsepower ///
//   & size_width > lag_size_width - .1*lag_size_width ///
//   & size_length > lag_size_length - .1*lag_size_length ///
//   & size_wheelbase > lag_size_wheelbase - .1*lag_size_wheelbase ///
//   & make == make[_n-1] & model == model[_n-1] & year == year[_n-1]+1
//
// tostring year, g(year_str)
// replace year_str = substr(year_str,3,2)
// bysort make model: gen series = model + year_str if same_design==0
//
// replace series = series[_n-1] if make == make[_n-1] & model == model[_n-1] & year == year[_n-1]+1
//
// * create a variable that capture the number of years since previous re-design
// sort series year
// bysort series: gen design_year = year - year[1]
//
// drop year_str same_design
// drop lag* cpi gas_price

sort year make model
save "${DER}wards-chars.dta", replace
