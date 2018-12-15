*--------------------------------------------------
* Explore Original BLP Data
* explore_blp.do
* 11/26/2018
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
log using explore_blp.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"


import delimited ${RAW}blp_products.csv

gen make_id = substr(clustering_ids,1,2)
gen design_year = substr(clustering_ids,-2,2)

* Print out lsit of unique make names
* - I use this manually keyed in make names into "data/derived/make_list.csv"
preserve

duplicates drop make_id, force
sort make_id
list make_id, clean

restore


* Change a few of the make_ids because they duplicate
replace make_id = "HD" if make_id=="HN"
* Graph C4 by year

drop *instruments*

sort make_id

preserve

import delimited ${DER}make_list.csv, clear varnames(1)
rename ïmake make
drop if make==""
sort make_id
save ${DER}make_list.dta, replace

restore

merge m:1 make_id using ${DER}make_list, keep(3)
drop _merge

gen year = market_ids
drop market_ids
do make_parents

replace parent=make if parent==""

save ${DER}blp.dta, replace

/*





collapse (sum) shares , by(market_ids make_id)

sort market_ids shares
by market_ids: gen C4 = shares[_N] + shares[_N-2] + shares[_N-3] + shares[_N-4]
tabstat C4, by(market_ids )
