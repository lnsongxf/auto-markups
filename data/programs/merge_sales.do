*--------------------------------------------------
* Construct Wards Sales Data
* merge_sales.do
* 12/2/2018
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
log using merge_sales.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

use ${DER}wards.dta
/* drop if year<1991 */
drop if sales<10
gen dataset="Wards"

append using ${DER}blp.dta
replace dataset="BLP" if dataset==""

replace model = clustering_ids if model==""
drop clustering_ids

order year make model shares
sort year dataset make model

by year dataset: egen insideshare = total(shares)
replace insideshare=. if insideshare==0
replace shares = shares/insideshare

drop insideshare
by year dataset: egen totalsales = total(sales)
replace shares = sales/totalsales if dataset=="Wards"

save ${DER}merged_sales.dta, replace
