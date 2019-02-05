* Figure out production locations from squishvin data.

clear
*-------------
* Macros
*-------------
global RAW "../raw/"
global DER "../derived/"

import delimited ${RAW}years.csv, clear
keep v1 v3
destring v1, replace force
keep if ~missing(v1)
gen year = substr(v3,8,5)

destring year, force replace
drop if v1==3.5

sort v1
save ${DER}edmunds-years.dta, replace

*use ${RAW}squish_data.dta
import delimited ${RAW}squish_data.csv, clear varnames(1) case(preserve)
/* import delimited ${RAW}years.csv, clear */

keep v1 datamakeniceName datamodelniceName datasquishVin

sort v1
merge 1:1 v1 using ${DER}edmunds-years.dta

drop v1 v3

rename datasquishVin squishvin
rename datamakeniceName make
rename datamodelniceName model

gen country=substr(squishvin,1,1)

sort make model year

drop in 1

/* tab model year if country=="K" & make=="chevrolet" */
tab model year if make=="audi" & country=="T"

STOP


* export to excel to assign produciton countires.
export excel ${DER}edmunds-countires.xlsx, replace


use ${DER}cars-cleaned.dta, clear
keep make model year
sort make model year
export excel ${DER}production-out.xlsx, replace
