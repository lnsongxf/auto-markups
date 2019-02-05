*--------------------------------------------------
* Construct Wards Sales Data
* make_wards.do
* 11/28/2018
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
log using make_wards.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"


** Sales 88-06
import delimited "${RAW}sales88-06.csv", varnames(1) clear
destring sales*, force replace ignore(",")
collapse (sum) sales*, by(parent make model vehicletype source)

reshape long sales, i(make model vehicletype source) j(datetmp)

* Create data variables
tostring datetmp, replace

gen year = substr(datetmp,-4,4)

gen month = ""
gen datelength = strlen(datetmp)
replace month = substr(datetmp,1,1) if datelength==5
replace month = substr(datetmp,1,2) if datelength==6
drop datetmp
drop datelength
drop *parent

destring year, replace
destring month, replace

replace make=lower(make)

quietly do make_parents
tab make if parent==""
drop if parent==""

save ${DER}sales88.dta, replace


** Sales 07-15
import delimited "${RAW}sales07-15.csv", varnames(1) clear
destring sales*, force replace ignore(",")
collapse (sum) sales*, by(parent make model)

drop if make==""
reshape long sales, i(make model) j(datetmp)

* Create data variables
tostring datetmp, replace

gen year = substr(datetmp,-4,4)

gen month = ""
gen datelength = strlen(datetmp)
replace month = substr(datetmp,1,1) if datelength==5
replace month = substr(datetmp,1,2) if datelength==6
drop datetmp
drop datelength
drop *parent

destring year, replace
destring month, replace

replace make=lower(make)

quietly do make_parents
tab make if parent==""
drop if parent==""

save ${DER}sales07.dta, replace

append using ${DER}sales88.dta


destring sales, ignore(",") force replace

* hardcode fixes to model names
replace model="4RUNNER" if model=="4RUNNER PASS"
replace model="WRX" if model=="WRX IMPREZA"
replace model="WRX" if model=="WRX (IMPREZA)"
replace model="VOYAGER" if model=="VOYAGER (CHRYSLER)"

collapse (sum) sales, by(make model year parent vehicletype)


save ${DER}wards.dta, replace
