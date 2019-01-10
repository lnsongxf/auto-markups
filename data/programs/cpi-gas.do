*--------------------------------------------------
* clean cpi and gas prices to merge with characteristics
* cpi-gas.do
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
log using cpi-gas.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

* ************
* CPI
* ************

import delimited ${RAW}auto_markups_freddata_txt/auto_markups_Annual.txt, delim(tab)

gen year = substr(observation_date,1,4)
rename cpaltt01usa661s cpi
keep year cpi
destring year, replace force
gen denomtemp = cpi if year==1983
egen denom = mean(denom)
replace cpi = cpi/denom

keep year cpi
save ${DER}cpi.dta, replace


* ************
* Gas prices
* ************
import delimited ${RAW}gas-price.csv, clear
gen newdate = date(date,"YMD")
gen year = year(newdate)
bysort year: egen gas_price = mean(gasregcovw)
duplicates drop year, force
sort year
keep year gas_price
save ${DER}gas-price.dta, replace


* ***************
* # Households
* ***************
import delimited ${RAW}hh.csv, clear
rename ïyear year
replace number_households=number_households*1000000
sort year
save ${DER}household.dta, replace
