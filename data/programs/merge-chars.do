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
capture log using logs/merge-chars.log, text replace      // Open log file
* --------------------------------------------------

*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

use ${DER}merged_sales.dta, clear

replace make = upper(make)
replace model = upper(model)

sort year make model


* note there are some duplicate year-make-models in the blp data, why?
* the pt cruiser is listed as a car and a light truck
drop if model=="PT CRUISER" & vehicletype=="Car"
replace vehicletype="Car" if model=="PT CRUISER"
rename design_year design_cal_year
merge m:1 year make model using ${DER}wards-chars.dta, update gen(merge_chars)

preserve
  keep if merge_chars==1 & year>1990
  keep year make model
  sort make model year
  save ${DER}not_merged_sales.dta, replace
restore

keep if merge_chars==1 | merge_chars==4


/*
A lot (most?) of the sales data that doesn't match is sales from the beginning or
end of a model-life. FOr example the 2006 sales of a Buick Lesabre, but the last model
year was 2005, so there is no 2006 Buick lesabre in the specs data.

I will fix this be filling in these things below.
*/

*keep if merge_chars==3
*drop merge_chars

sort year make model

* **************************
* Fix some things
* **************************
replace model="4RUNNER" if model=="4RUNNER PASS"
replace model="WRX" if model=="WRX IMPREZA"
replace model="VOYAGER" if model=="VOYAGER (CHRYSLER)"


* merge with US households to get shares

sort year
merge m:1 year using ${DER}household.dta, keep(3) nogen

sort make model year
order year make model sales price hpwt doors




* Export list of make-models up to the 1991 changeover so we can
* hand fill in the actual model names, the assign bosystyle.

preserve
  keep if year<1991
  keep make model year dataset bodystyle
  sort make year dataset model
  save ${DER}fill-models.dta, replace
restore

**************************
* BLP Model Names
**************************

* load Arnab's hand-filled model names
preserve
  import excel using ${DER}fill-models_AP_v4.xlsx, clear firstrow
  drop if dataset=="Wards"
  capture drop dataset I J K
  drop newmodel
  duplicates drop make model year, force
  sort make model year
  save ${DER}fill-models-BLP-done.dta, replace
restore

stop

* Merge Arnab's names to the main dataset, replacing current modelnames
sort make model year // Watch out, there are some model duplicates from BLP Dataset
merge m:1 make model year using ${DER}fill-models-BLP-done.dta, gen(merge_makemodel)

replace model=new_model2 if new_model2!=""

** The Ward's data seems better so let's take that version during


********************
* Bodystyles
********************
* first do some hand fixes
* merge in hand filled in bodystyles from WARDS data
* export list of still missing
* merge in hand filled in bodystyles from BLP data

preserve
  import excel using ${DER}fill-bodystyle.xlsx, clear firstrow
  sort make model
  save ${DER}fill-bodystyle-wards-done.dta, replace
restore

merge m:1 make model using ${DER}fill-bodystyle-wards-done.dta, update replace

* bodystyle fixes
replace bodystyle = trim(bodystyle)
replace bodystyle = "conv" if bodystyle=="convertible"
replace bodystyle = "hatchback" if bodystyle=="hatcbak"
replace bodystyle = "wagon" if bodystyle=="wagin"
replace bodystyle = "sedan" if bodystyle=="wagin"
replace bodystyle = "truck" if bodystyle=="pu"
replace bodystyle = "suv" if bodystyle=="cuv"

** Make manual bodystyle fixes
// replace bodystyle="sedan" if model=="SKYHAWK" & make=="BUICK"
// replace bodystyle="coupe" if model=="SKYHAWK" & make=="BUICK" & year<1982

tab bodystyle, m

* Before we fill in the rest of the bodystyles, we need to fill in the BLP model names.


STOP







** Interpolte missing characteristcs
* Example: for Acura CL, the characteristics do not exist for year==2000

* take average for prices.
replace prices = (prices[_n-1] + prices[_n+1])/2 if prices==. ///
  & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 ///
  & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1  & sales>0

* If the missing value is not in the middle of the time series, then take the
* or last available.
replace prices = prices[_n-1] if prices==. ///
  & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 & sales>0

replace prices = prices[_n+1] if prices==. ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1 & sales>0

local CHARS="engine_horsepower size_length size_width size_weight"

* for characteristics, take n-1
foreach ix in `CHARS' {
  replace `ix' = `ix'[_n-1]  if `ix'==. ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1  & sales>0
}

foreach ix in series {
  replace `ix' = `ix'[_n-1]  if `ix'=="" ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1  & sales>0
}

bysort make model: egen doortemp = mean(doors)
replace doors=doortemp if doors==. & doortemp==4
replace doors=doortemp if doors==. & doortemp==2


* then work on beginnings and ends
foreach ix in `CHARS' {
  replace `ix' = `ix'[_n-1]  if `ix'==. ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 & sales>0
}
foreach ix in series {
  replace `ix' = `ix'[_n-1]  if `ix'=="" ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 & sales>0
}

foreach ix in `CHARS' {
  replace `ix' = `ix'[_n+1]  if `ix'==. ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1 & sales>0
}

foreach ix in series {
  replace `ix' = `ix'[_n+1]  if `ix'=="" ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1 & sales>0
}






log close _all
