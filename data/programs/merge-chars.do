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

/*
! this merge is not as bad as it looks. Most of the misses are model-years sold
in a different year. Like the 1995 Audi A4 started selling in 1994. So this will
be fixed when we fill in specs in neighboring years.

A lot (most?) of the sales data that doesn't match is sales from the beginning or
end of a model-life. FOr example the 2006 sales of a Buick Lesabre, but the last model
year was 2005, so there is no 2006 Buick lesabre in the specs data.

I will fix this be filling in these things below.

For now we keep everything except records from the sepcs files that did not merge (they
dont' have sales so there is no hope)
*/

drop if merge_chars==2

/* preserve
  keep if merge_chars==1 & year>1990
  keep year make model
  sort make model year
  save ${DER}not_merged_sales.dta, replace
restore */


* merge with US households to get shares

sort year
merge m:1 year using ${DER}household.dta, keep(3) nogen

sort make model year
order year make model sales price hpwt doors bodystyle


* Export list of make-models up to the 1991 changeover so we can
* hand fill in the actual model names, the assign bosystyle.

/* preserve
  keep if year<1991
  keep make model year dataset bodystyle
  sort make year dataset model
  save ${DER}fill-models.dta, replace
restore */

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


* Merge Arnab's names to the main dataset, replacing current modelnames
sort make model year // Watch out, there are some model duplicates from BLP Dataset
merge m:1 make model year using ${DER}fill-models-BLP-done.dta, gen(merge_makemodel)

replace model=new_model2 if new_model2!=""
drop make_new new_model2
** The Ward's data seems better so let's take that version during


********************
* Bodystyles
********************
* first do some hand fixes
* merge in hand filled in bodystyles from WARDS data
* export list of still missing
* merge in hand filled in bodystyles from BLP data

/* preserve
  import excel using ${DER}fill-bodystyle.xlsx, clear firstrow
  sort make model
  save ${DER}fill-bodystyle-wards-done.dta, replace
restore

merge m:1 make model using ${DER}fill-bodystyle-wards-done.dta, update replace */

replace bodystyle=CarType if bodystyle==""
drop CarType

* bodystyle fixes
replace bodystyle = lower(bodystyle)
replace bodystyle = trim(bodystyle)
replace bodystyle = "conv" if bodystyle=="convertible"
replace bodystyle = "hatchback" if bodystyle=="hatcbak"
replace bodystyle = "wagon" if bodystyle=="wagin"
replace bodystyle = "sedan" if bodystyle=="wagin"
replace bodystyle = "truck" if bodystyle=="pu"
replace bodystyle = "suv" if bodystyle=="cuv"
replace bodystyle = "coupe" if bodystyle=="sportscar"
replace bodystyle = "truck" if bodystyle=="pickup truck"
replace bodystyle = "wagon" if bodystyle=="station wagon"

** Make manual bodystyle fixes
replace bodystyle="sedan" if model=="SKYHAWK" & make=="BUICK"
replace bodystyle="coupe" if model=="SKYHAWK" & make=="BUICK" & year<1982

tab bodystyle, m

* fill in bodystyles
preserve
collapse (firstnm) bodystyle, by(make model)
sort make model
save bodystyle-merge-temp.dta, replace
restore

merge m:1 make model using bodystyle-merge-temp.dta, update



* Export list of remaining bodystyle issues
preserve
keep if bodystyle==""
duplicates drop make model, force
keep make model
sort make model
export delimited using "${DER}final-bodystyle-fill-out.csv", replace
restore

* Fixes
replace bodystyle="wagon" if model=="MAGNUM"


** Combine info for 1988-1990 between BLP and Wards.
gsort make model year - dataset // make Ward's the default

collapse (firstnm) sales-parent region-space drivetype-gas_price number_households, ///
  by(make model year)

** Interpolte missing characteristcs
* Example: for Acura CL, the characteristics do not exist for year==2000
sort make model year
* take average for prices.
replace prices = (prices[_n-1] + prices[_n+1])/2 if prices==. ///
  & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 ///
  & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1  & sales>0

* If the missing value is not in the middle of the time series, then take the
* or last available.
forvalues ix=1(1)3 {
replace prices = prices[_n-1] if prices==. ///
  & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1 & sales>0

replace prices = prices[_n+1] if prices==. ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1 & sales>0
}

/* STOP */
local CHARS="engine_horsepower size_length size_width size_weight mpg"

forvalues jx=1(1)3 {

* mpg space size_weight engine_horsepower doors
* for characteristics, take n-1
foreach ix of varlist mpg space size_weight engine_horsepower doors {
  replace `ix' = `ix'[_n-1]  if `ix'==. ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1
}

foreach ix of varlist drivetype traction_control-engine_trans {
  replace `ix' = `ix'[_n-1]  if `ix'=="" ///
    & make==make[_n-1] & model==model[_n-1] & year==year[_n-1]+1
}

* for characteristics, take n+1
foreach ix of varlist mpg space size_weight engine_horsepower doors {
  replace `ix' = `ix'[_n+1]  if `ix'==. ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1
}

foreach ix of varlist drivetype traction_control-engine_trans {
  replace `ix' = `ix'[_n+1]  if `ix'=="" ///
    & make==make[_n+1] & model==model[_n+1] & year==year[_n+1]-1
}
}


* I need to remerge cpi and gas price
sort year
merge m:1 year using ${DER}cpi.dta, update
drop if _merge<3
drop _merge
merge m:1 year using ${DER}gas-price.dta, update
drop if _merge==2
drop _merge

replace gas = gas/cpi

* miles per $
replace mpd = mpg/gas/10 if mpd==.

* BLP's acceleration
replace hpwt = 10*engine_horsepower / size_weight if hpwt==.

sort make model year

*** There are a few missing bodystyles
replace bodystyle="sedan" if model=="SUPREME" & make=="OLDSMOBILE"
replace bodystyle="sedan" if model=="VOLVO 200"
replace bodystyle="sedan" if model=="VOLVO 700"

drop if bodystyle=="truck"
drop if missing(prices)
drop if missing(sales)
drop if sales<200
drop if make=="IN"
drop if make=="CH"
drop if make=="CP"


* compute shares
gen shares = sales/(number_households/7)
bysort year: gen insideshare = sum(shares)
gen outsideshare = 1-insideshare
bysort year bodystyle: gen shares_bodystyle_total = sum(shares)
gen shares_bodystyle = shares/shares_bodystyle_total


/*
Missings: Most missings are cars that we have little info for, or weird commercial vans.
mpg - 43. Need to fix Excursion and Hummer H1.
bodystyles -- just drop missings.
doors -- 106. Replace using bodystyle
*/
replace doors=4 if bodystyle=="sedan"
replace doors=3 if bodystyle=="van"


/*
Still need to figure out design yeasrs.
- Use hpwt to straddle 88-90 sample?
*/


** Merge production locations.
preserve
  import excel using ${DER}production-in.xlsx, clear firstrow
  drop J
  sort make model year
  save ${DER}production-locations.dta, replace
restore

merge 1:1 make model year using ${DER}production-locations.dta
keep if _merge==3
drop _merge

tab country1
do make-countries

sort country year
merge m:1 country year using ${RAW}pwt90.dta, keepusing(country year pl_gdpo rtfpna)
keep if _merge==3 | _merge=1
drop _merge





/* encode bodystyle, gen(bodystyle_num)
encode make, gen(make_num)
encode country1 , g(country1_num)
reg prices i.country1_num i.make_num i.bodystyle_num */


* add Mexico and Korea dummy
/* do make-production.do */


save ${DER}cars-cleaned.dta, replace

/*
** Construct Instruments
* Squared difference from mean, by bodystyle and year
local SPECS = "mpd space hpwt"
foreach ix of varlist `SPECS' {
  bysort bodystyle year: egen `ix'_mean = mean(`ix')
  egen `ix'_mean_total = mean(`ix')
  gen iv_`ix' = `ix'-`ix'_mean
  gen iv_`ix'2 = (`ix'-`ix'_mean)^2
  /* gen iv_`ix'_total = (`ix'-`ix'_mean_total)^2 */
  gen log`ix' = log(`ix')
}

* Number of


gen logp = log(prices)
gen logq = log(sales)

encode bodystyle, gen(bodystyle_num)
encode make, gen(make_num)
reg logp mpd space hpwt iv* i.year i.bodystyle_num i.make_num

ivregress 2sls logq (logp = iv*) logmpd logspace loghpwt i.year i.bodystyle_num i.make_num, first

/* preserve
keep if year<2011
keep make model year
export delimited using ${DER}forGavin.csv, replace
restore */


STOP


%%%%%%%%%%%%%%%%%%%%%%%%%
*************************
*************************

* *******************************
* Create design year and tenure
* *******************************




log close _all
