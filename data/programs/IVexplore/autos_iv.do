
cd "D:\Dropbox\autos\"


** Import steel prices by year
import delimited using "steelprices.csv", clear
rename wpu steelprices
gen year=substr(date,1,4)
destring year, replace force
keep steel year
save "steelpricebyyear.dta", replace


** Join quantities, prices, characteristics, and steel prices
use "D:\Dropbox (gsc)\CarMarkups\data\derived\merged_sales.dta", clear
drop prices hpwt air mpd mpg space trend make_id design_year totalsales
replace make=upper(make)
joinby make model year using "D:\Dropbox (gsc)\CarMarkups\data\derived\wards-chars.dta"
joinby year using "steelpricebyyear.dta", unm(master)

* rough imputation of market size as total hh in US (91M in 1988 growing by about 1.3% a year)
gen total_market_size=91000000*exp(.013*(year-1988))
gen new_shares=sales/total_market_size
bysort year: egen total_share=sum(new_shares)
gen logit_delta=log(new_sh)-log(1-total_s)

gen steelprice_X_weight=steelprices*size_weight

egen make_model_gr=group(make model)
duplicates drop make model year, force
tsset make_model_gr year

drop if price>100

* Time series prices and steel prices
bysort year: egen yearseq=seq(), from (1)
line steelprices year if yearseq==1, title("Steel Prices over Time")
bysort year: egen meanprice=mean(price)
line meanprice year if yearseq==1, title("Steel Prices over Time")


xi: areg steelprice_X_weight i.year, a(make)
predict hat_steelprice_X_weight, xbd
gen resid_steelprice_X=steelprice_X_weight-hat_steelprice_X
hist resid_steelprice_X, title("Histogram of Steel Price x Weight (residualized year and make)")
scatter price resid_steelprice_X, title("Steel Price x Weight against Car Price")

xi: areg steelprice_X_weight i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt, a(make)
predict hat_steelprice_X_weight2, xbd
gen resid_steelprice_X2=steelprice_X_weight-hat_steelprice_X_weight2
hist resid_steelprice_X2, title("Histogram of Steel Price x Weight (residualized FE+chars)")

** WITH MAKE FE
* OLS 
xi: areg logit_delta i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt price, clust(make) a(make)
* IV
xi: ivreg logit_delta i.year i.make  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt (price=steelprice_X_weight), clust(make)

* First stage
xi: areg price i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make)
* Reduced Form
xi: areg logit_delta i.year  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make)


** WITH MODEL FE
* OLS 
xi: areg logit_delta i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt price, clust(make) a(make_model_gr)
* IV
xi: ivreg logit_delta i.year i.model  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt (price=steelprice_X_weight), clust(make)

* First stage
xi: areg price i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make_model_gr)
* Reduced Form
xi: areg logit_delta i.year  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make_model_gr)

** WITH MAKE-YEAR FE
egen make_year=group(make year)
* OLS 
xi: areg logit_delta i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt price, clust(make) a(make_year)
* IV
xi: ivreg logit_delta i.year i.model  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt (price=steelprice_X_weight), clust(make)

* First stage
xi: areg price i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make_year)
* Reduced Form
xi: areg logit_delta i.year  i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt steelprice_X_weight, clust(make) a(make_year)


* Lagged steel prices
sort make_model_gr year
xi: areg price i.year i.bodystyle engine_horse size_weight engine_liter mpg i.doors i.engine_trans hpwt L.steelprice_X_weight, clust(make) a(make)

* Everything in logs

gen logprice=log(price)
gen loghp=log(engine_horsepower)
gen logweight=log(size_weight)
gen logmpg=log(mpg)
gen loghpwt=log(hpwt)
gen logsteelprice=log(steelprices)
gen logsteel_X_logweight=logsteelprice*logweight

** WITH MAKE FE
* OLS 
xi: areg logit_delta i.year i.bodystyle logweight loghp logmpg loghpwt engine_liter i.doors i.engine_trans price, clust(make) a(make)
* IV
xi: ivreg logit_delta i.year i.make i.year logweight loghp logmpg loghpwt engine_liter i.doors i.engine_trans (logprice=logsteel_X), clust(make)

* First stage
xi: areg price i.year logweight loghp logmpg loghpwt engine_liter i.doors i.engine_trans logsteel_X, clust(make) a(make)
* Reduced Form
xi: areg logit_delta i.year logweight loghp logmpg loghpwt engine_liter i.doors i.engine_trans logsteel_X, clust(make) a(make)


