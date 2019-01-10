*--------------------------------------------------
* Construct Aggregate Series for Graphs
* aggregate.do
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
log using logs/aggregate.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

*************************
** Parents
*************************

use ${DER}merged_sales.dta, clear

** There are some things I haven't figures out yet
drop if parent=="im"
drop if parent=="cp"
drop if parent=="honda" & year<1972
drop if make=="alfa romeo" & year>1980
drop if make=="bmw" & year<1975
drop if make=="mazda" & year<1976
/* foreach ix of numlist 1971(1)1980 {
tabstat shares if year==`ix', by(parent) s(sum)
} */

/* stop */


* Parent level stats
/* preserve */

collapse (sum) shares, by(dataset year parent)

/* drop if shares<.05 */

gen s05 = shares>0.05
gen s01 = shares>0.01
gen s10 = shares>0.1

sort year dataset
by year dataset: egen N_parent_05=total(s05)
by year dataset: egen N_parent_01=total(s01)
by year dataset: egen N_parent_10=total(s10)

sort dataset year shares
by dataset year : gen C4 = shares[_N] + shares[_N-1] + shares[_N-2] + shares[_N-3]
by dataset year : gen C2 = shares[_N] + shares[_N-1]


gen share_sq = shares*shares
bysort year dataset: egen HHI=total(share_sq)

duplicates drop year dataset, force

list dataset year C4 C2 HHI, clean

twoway (line HHI year if dataset=="BLP") (line C4 year if dataset=="BLP") ///
  (line C2 year if dataset=="BLP") ///
  (line HHI year if dataset=="Wards") ///
  (line C4 year if dataset=="Wards") ///
    (line C2 year if dataset=="Wards"), xtitle(Year) ///
  title("Auto Inidusty Concentration, 1971-2015") subtitle(Auto Manufacturer Groups, size(small)) ///
  ysc(r(0 1)) ylabel(0(.1)1) xsc(r(1971 2015)) xlabel(1971 1975 1980 1985 1990 1995 2000 2005 2010 2015)
graph export hhi.eps, replace
graph export hhi.pdf, replace


twoway (line N_parent_01 year if dataset=="BLP") (line N_parent_05 year if dataset=="BLP") ///
  (line N_parent_10 year if dataset=="BLP") ///
  (line N_parent_01 year if dataset=="Wards") ///
  (line N_parent_05 year if dataset=="Wards") ///
    (line N_parent_10 year if dataset=="Wards"), xtitle(Year) ///
  legend(label(1 "> 1% Share") label(2 "> 5% Share") ///
  label(3 "> 10% Share")) title("Number of Large Auto Groups, 1970-2015")
graph export num-parents.eps, replace
graph export num-parents.pdf, replace

stop
/* restore */

*************************
** Brands
*************************

use ${DER}merged_sales.dta, clear

** There are some things I haven't figures out yet
drop if parent=="im"
drop if parent=="cp"
drop if parent=="honda" & year<1972
drop if make=="alfa romeo" & year>1980
drop if make=="bmw" & year<1975
drop if make=="mazda" & year<1976

collapse (sum) shares, by(year make)

/* drop if shares<.05 */

gen s05 = shares>0.05
gen s01 = shares>0.01
gen s10 = shares>0.1
gen s_small = shares<0.1

by year: egen N_make_05=total(s05)
by year: egen N_make_01=total(s01)
by year: egen N_make_10=total(s10)
by year: egen N_make_small=total(s_small)

sort year shares
by year: gen C4 = shares[_N] + shares[_N-1] + shares[_N-2] + shares[_N-3]
by year: gen C2 = shares[_N] + shares[_N-1]


gen share_sq = shares*shares
by year: egen HHI=total(share_sq)

duplicates drop year, force

list year C4 C2 HHI, clean

twoway (line HHI year) (line C4 year) (line C2 year) , xtitle(Year) ///
  title("Auto Industy Concentration, 1971-2015") subtitle(Auto Brands, size(small)) ///
  ysc(r(0 1)) ylabel(0(.1)1) xsc(r(1971 2015)) xlabel(1971 1975 1980 1985 1990 1995 2000 2005 2010 2015)
graph export hhi-brands.eps, replace
graph export hhi-brands.pdf, replace


twoway (line N_make_01 year if dataset=="BLP") (line N_make_05 year if dataset=="BLP") ///
  (line N_make_10 year if dataset=="BLP") (line N_make_small year if dataset=="BLP") ///
  (line N_make_01 year if dataset=="Wards") (line N_make_05 year if dataset=="Wards") ///
    (line N_make_10 year if dataset=="Wards") (line N_make_small year if dataset=="Wards") , xtitle(Year) ///
  legend(label(1 "> 1% Share") label(2 "> 5% Share")  ///
  label(3 "> 10% Share") label(4 "< 1% Share")) title("Number of Brands, 1970-2015")
graph export num-brands.eps, replace
graph export num-brands.pdf, replace
