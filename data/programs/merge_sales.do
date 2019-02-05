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
log using "logs/merge_sales.log", text replace      // Open log file
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

order year make model sales
sort year dataset make model

save ${DER}merged_sales.dta, replace


* Create master make-model list
preserve

duplicates drop make model, force
keep make model
sort make model
save ${DER}make-model-list.dta, replace

restore
