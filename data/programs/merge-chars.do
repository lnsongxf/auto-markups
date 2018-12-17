*--------------------------------------------------
* Merge characteristics data (1991-2015) w/ sales
* data (BLP + Ward's)
* merge-chars.do
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
log using merge-chars.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

use ${DER}merged_sales.dta, clear

replace make = upper(make)

sort year make model


* note there are some duplicate year-make-models in the blp data, why?
* the pt cruiser is listed as a car and a light truck
drop if model=="PT CRUISER" & vehicletype=="Car"
replace vehicletype="Car" if model=="PT CRUISER"
rename design_year design_cal_year
merge m:1 year make model using ${DER}wards-chars.dta, update assert(1 2 3) gen(merge_chars)

preserve
  keep if merge_chars==2
  save ${DER}not_merged_chars.dta, replace
restore

keep if merge_chars==3
drop merge_chars

sort year make model

* merge with US households to get shares

sort year
merge m:1 year using ${DER}households.dta, keep(3) nogen
