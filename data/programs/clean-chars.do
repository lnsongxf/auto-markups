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
replace doors=4 if regexm(makeseries,"4-dr") == 1
replace doors=5 if regexm(makeseries,"5-dr") == 1

** Extract base transmission
gen trans_type = substr(standardenginetrans,1,1)  // "C" is CVT which is continuous variable trans.
replace trans_type = "M" if trans_type == "("
replace trans_type = "M" if trans_type == "5"
replace trans_type = "U" if ~inlist(trans_type,"A","M","C")

** Clean up prices and mpg -- I should export a list of non-msrps to see if we can hand collect them
destring pricemsrp, force replace ignore(",")
replace pricemsrp = . if pricemsrp<3000   // just a few odd prices
destring standardengineestmpghwy, force replace

keep year make final_series bodystyle-electricfederaltaxcredit doors trans_type


* ******************************************************************************
* Define and clean up vars
* Define base trim
* - needs an msrp
* - needs to be a 4-dr if that exists
* - base trim is the cheapest 4-dr variant with an MSRP
* ******************************************************************************
rename final_series model

drop if pricemsrp==.  // 390/30,036 dropped

bysort year make model: egen maxdoors=max(doors)
bysort make model: egen maxdoors_plus=max(doors)
replace maxdoors = maxdoors_plus if maxdoors==.
drop if maxdoors==4 & doors!=4

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
rename trans_type engine_trans
rename standardenginetractioncontro traction_control
rename standardengineabs abs
rename standardengineestmpghwy mpg
rename standardenginestabilitycontr stability
rename wheelbasewheelbaseinsstd size_wheelbase

gen electric=1 if electricelectricmotortype!=""
replace electric=0 if electric!=1


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
collapse (firstnm) engine_liter engine_horsepower size_length size_width size_wheelbase engine_trans ///
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
gen mpd = mpg/gas


/* sort year make model */
/* save "${DER}wards-chars.dta", replace */



* create make and design year
sort make model year

** make t-1 variables for all variables to see if everything stays the same by 10%
* See BLP page 869: "...their horsepower, width, length, or wheelbase do not change by more than ten percent..."

destring engine_horsepower, force replace
destring size_width, force replace
destring size_wheelbase, force replace


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

save "${DER}wards-chars.dta", replace
