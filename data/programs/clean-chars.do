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

drop if line_type=="HEADER"


* extract number of doors.

drop word*

gen doors = .

replace doors=2 if regexm(makeseries,"2-dr") == 1
replace doors=4 if regexm(makeseries,"4-dr") == 1
replace doors=5 if regexm(makeseries,"5-dr") == 1

keep year make final_series bodystyle-electricfederaltaxcredit doors

* Drop <1991 b/c that is where the BLP data goes until
drop if year<1991

* ****************************************
* figure out base trim
* - needs an msrp
* - needs to be a 4-dr if that exists
* ****************************************

* ** Maybe take the cheapest 4-dr trim. **

* this starts in 1991 (I think the pre-1991 data is not very comprehensive..)
gen trans_type = substr(standardenginetrans,1,1)  // "C" is CVT which is continuous variable trans.
replace trans_type = "M" if trans_type == "("
replace trans_type = "M" if trans_type == "5"
replace trans_type = "U" if ~inlist(trans_type,"A","M","C")


rename final_series model
sort year make model doors

by year make model: egen maxdoors=max(doors)
drop if maxdoors==4 & doors!=4


destring pricemsrp, force replace ignore(",")
destring standardengineestmpghwy, force replace
** ! replace missing mpgs !!**


* I should export a list of non-msrps to see if we can hand collect them

drop if pricemsrp==.  // 390/30,036 dropped



* define characteristics we will use
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

gen electric=1 if electricelectricmotortype!=""
replace electric=0 if electric!=1


* adjusted price to merge with BLP data
destring guzzlertax, force replace ignore(",")
replace guzzlertax=0 if guzzlertax==.
destring electricfederaltaxcredit, force replace ignore(",")
replace electricfederaltaxcredit=0 if electricfederaltaxcredit==.

gen prices = (pricemsrp + guzzlertax - electricfederaltaxcredit)/1000


/*
Note: see 1991 Acura Integra. The three trims are identical according to my data.
However, the pricemsrp differs. So it must be non-structural things about the car, like
leather, sound system, etc. (actually, the more expensive one is 50lbs heavier, so it might have
a spoiler?).
You could think of the the higher trims representing the demand for leather interiors, not
a fundementally different car.
*/

sort year make model pricemsrp


// by year make model: keep if _n==1
collapse (firstnm) engine_liter engine_horsepower size_length size_width engine_trans ///
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


sort year make model
save "${DER}wards-chars.dta", replace


/*
* create make and design year
sort make model year
