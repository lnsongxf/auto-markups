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

import delimited "${RAW}characteristics1988-2015.csv"

* fix weird encoding
rename ïfilename filename

drop if line_type=="HEADER"


* extract number of doors.

drop word*

gen doors = .

replace doors=2 if regexm(makeseries,"2-dr") == 1
replace doors=4 if regexm(makeseries,"4-dr") == 1
replace doors=5 if regexm(makeseries,"5-dr") == 1

keep year make final_series bodystyle-electricfederaltaxcredit doors

* some basic cleaing
gen first2year = substr(year,1,2)
keep if inlist(first2year,"19","20")
drop first2year
destring year, force replace

drop if year<1991

drop if make==""

* ****************************************
* figure out base trim
* - needs an msrp
* - needs to be a 4-dr if that exists
* ****************************************

* ** Maybe take the cheapest 4-dr trim. **

* this starts in 1991 (I think the pre-1991 data is not very comprehensive..)
gen trans_type = substr(standardenginetrans,1,1)  // "C" is CVT which is continuous variable trans.
replace trans_type = "U" if ~inlist(trans_type,"A","M","C")


rename final_series model
sort year make model doors

by year make model: egen maxdoors=max(doors)
drop if maxdoors==4 & doors!=4

stop
destring pricemsrp, force replace ignore(",")

* I should export a list of non-msrps to see if we can hand collect them

drop if pricemsrp==.  // 410/30,411 dropped

/*
Note: see 1991 Acura Integra. The three trims are identical according to my data.
However, the pricemsrp differs. So it must be non-structural things about the car, like
leather, sound system, etc. (actually, the more expensive one is 50lbs heavier, so it might have
a spoiler?).
You could think of the the higher trims representing the demand for leather interiors, not
a fundementally different car.
*/

sort year make model pricemsrp

by year make model: keep if _n==1


* define characteristics we will use
/*
From BLP:
number of cylinders, number of doors, weight, engine displacement, horsepower,
length, width, wheelbase, EPA miles per gallon rating (MPG), and dummy variables
for whether the car has front wheel drive, automatic transmission, power steering,
and air conditioning as standard equipment.
*/

rename standardenginesizeliter engine_liter
rename standardenginenethprpmnethp engine_horsepower
rename overallsizeinslengthstd size_length
rename overallsizeinswidthins size_width
rename trans_type engine_trans
rename standardenginetractioncontrol traction_control
rename standardengineabs abs
rename standardengineestmpghwy mpg



gen electric=1 if electricmotortype!=""

* adjusted price to merge with BLP data
gen prices = (pricemsrp + guzzlertax - electricfederaltaxcredit)/1000

order year make model doors

* create make and design year
sort make model year
