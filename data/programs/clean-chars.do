*--------------------------------------------------
* Clean characteristics data (from upwork)
* clean-chars.do
* 12/15/2018
* Charlie Murry (BC) etc.
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

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

import excel ${RAW}Cars_Characteristics.xlsx, sheet("Summary") firstrow case(lower)

drop if line_type=="HEADER"   // used to mark makes for inital clean
drop word*                    // used to mark makes for inital clean

** Drop <1991 b/c that is where the BLP data goes until
drop if year<1991


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


** Get body style
local BSLIST=". -dr -door 2 3 4 5"
for ix in `BSLIST' {
  replace bodystyle = regexr(bodystyle,"`ix'","")
}

tab bodystyle

stop
** Extract base transmission
gen trans_type = substr(standardenginetrans,1,1)  // "C" is CVT which is continuous variable trans.
replace trans_type = "M" if trans_type == "("
replace trans_type = "M" if trans_type == "5"
replace trans_type = "U" if ~inlist(trans_type,"A","M","C")

** Clean up prices and mpg -- I should export a list of non-msrps to see if we can hand collect them
destring pricemsrp, force replace ignore(",")
replace pricemsrp = . if pricemsrp<3000   // just a few odd prices
destring standardengineestmpghwy, force replace

keep year make final_series bodystyle-electricfederaltaxcredit doors trans_type makeseries


* ******************************************************************************
* Define and clean up vars
* Define base trim
* - needs an msrp
* - needs to be a 4-dr if that exists
* - base trim is the cheapest 4-dr variant with an MSRP
* ******************************************************************************
rename final_series model

***********************************************************
* * STOP HERE TO INVESTIGATE PROLEMS WITH SPECS
***********************************************************

/*
* Start comment here for investigating
sort make model year
order year make model pricemsrp doors bodystyle overallsizeinslengthstd

STOP
*/


** Hard-coded fixes
order year make model pricemsrp doors bodystyle overallsizeinslengthstd
replace pricemsrp = 42630 if make=="ACRUA" & model=="ACURA RL" & year==2000





** Fill in missig specs (before getting base model)
* the key is that we do this by makeseries, which is essentially the trim.
sort make makeseries year


* take average msrp
replace pricemsrp = (pricemsrp[_n-1] + pricemsrp[_n+1])/2 if pricemsrp==. ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1 ///
  & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1

* If the missing value is not in the middle of the time series, then take the
* or last available.
replace pricemsrp = pricemsrp[_n-1] if pricemsrp==. ///
  & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1

replace pricemsrp = pricemsrp[_n+1] if pricemsrp==. ///
  & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1


* replace doors
replace doors = doors[_n-1] if doors==. ///
    & make==make[_n-1] & makeseries==makeseries[_n-1] & year==year[_n-1]+1

replace doors = doors[_n+1] if doors==. ///
    & make==make[_n+1] & makeseries==makeseries[_n+1] & year==year[_n+1]-1

sort make model year
* drop if pricemsrp==.  // 390/30,036 dropped


* keep the lowest msrp 4 door version in the case when there are 2-drs and 4-drs.
bysort year make model: egen maxdoors=max(doors)
bysort make model: egen maxdoors_plus=max(doors)
replace maxdoors = maxdoors_plus if maxdoors==.
drop if maxdoors==4 & doors==2
drop if maxdoors==4 & doors==3



* If auto trans available, take the auto trans version
sort make model year trans_type
bysort make model year: egen auto_trans_available = first(trans_type)
replace auto_trans_available = "no" if auto_trans_available!="A"
replace auto_trans_available = "yes" if auto_trans_available=="A"

drop if trans_type !="A" & auto_trans_available=="yes"


* Stata treats missing as positive infinity, so to get base model lets
* pull the first make model year, sorted by pricemsrp
** this might leave some missing msrps, but we can fill that in later.

sort make model year pricemsrp
by make model year: keep if _n==1


** Some more baindaids
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

drop if pricemsrp==.


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

destring engine_horsepower, force replace
destring size_width, force replace
destring size_wheelbase, force replace
destring size_weight, force replace
destring engine_horsepower, force replace

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

// by year make model: keep if _n==1
collapse (firstnm) engine_liter engine_horsepower size_length size_weight size_width size_wheelbase engine_trans ///
  traction_control abs mpg electric doors bodystyle drivetype stability prices, by(year make model)

order year make model prices

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

** make t-1 variables for all variables to see if everything stays the same by 10%
* See BLP page 869: "...their horsepower, width, length, or wheelbase do not change by more than ten percent..."


foreach ix in engine_horsepower size_width size_length size_wheelbase {
  gen lag_`ix' = `ix'[_n-1]
  replace lag_`ix' = . if model!=model[_n-1] & year!=year[_n-1]+1
}



gen same_design = 0
replace same_design = 1 if ///
  engine_horsepower < lag_engine_horsepower + .1*lag_engine_horsepower ///
  & size_width < lag_size_width + .1*lag_size_width ///
  & size_length < lag_size_length + .1*lag_size_length ///
  & size_wheelbase < lag_size_wheelbase + .1*lag_size_wheelbase ///
  & engine_horsepower > lag_engine_horsepower - .1*lag_engine_horsepower ///
  & size_width > lag_size_width - .1*lag_size_width ///
  & size_length > lag_size_length - .1*lag_size_length ///
  & size_wheelbase > lag_size_wheelbase - .1*lag_size_wheelbase ///
  & make == make[_n-1] & model == model[_n-1] & year == year[_n-1]+1

tostring year, g(year_str)
replace year_str = substr(year_str,3,2)
bysort make model: gen series = model + year_str if same_design==0

replace series = series[_n-1] if make == make[_n-1] & model == model[_n-1] & year == year[_n-1]+1

* create a variable that capture the number of years since previous re-design
sort series year
bysort series: gen design_year = year - year[1]

drop year_str same_design
drop lag* cpi gas_price

sort year make model
save "${DER}wards-chars.dta", replace
