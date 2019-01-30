# README for data construction

### outstanding issues
1. air conditioning for Ward's sample (*ali look at MRI for AC variable*)
2. Country/State of production (*Charlie try hand entering a few years*)
 - Paul's data from IER paper + Ward's books + new data Ward's data(?) + VIN data from Ohio.
 - Here for VIN lookup: https://en.wikibooks.org/wiki/Vehicle_Identification_Numbers_(VIN_codes)/World_Manufacturer_Identifier_(WMI)
3. Create a design year varaible to track design tenure and refreshes. 
4. Right now we are using base trim. We could use base 4-door trim. My guess is this will mainly affect bodystyle, which could be a big deal.

### List of fixes that we addressed
#### Various hand fixes to weird values. 
- Ex. ACURA RL 1996, 1997, 2000 (weird price)
- To fix issues like this I looked up individual cars on autotrader/edmunds

#### Bodystyle
- About 75% of Ward's data had bodystyle embeded in trim variable
- "Back-filled" using a merge to the rest of the Ward's data and the BLP data
- Hand entered remaining bodystyles. 

#### BLP Model Names
- Hand filled in by RA (Arnab at BC) and checked by Charlie


#### explore_blp.do
input: ${RAW}blp_products.csv, ${DER}make_list.csv

output: ${DER}blp.dta, ${DER}make_list.dta

- basic clean of blp sales/characteristics data
- merge with parents



#### merge-sales.do
input: ${DER}blp.dta, ${DER}wards.dta

output: ${DER}merged_sales.dta

- appends Ward's sales data to blp data



#### merge-chars.do
input: ${DER}merged_sales.dta, ${DER}wards-chars.dta, ${DER}household.dta (num of households)

output:

- takes all sales (including blp chars) and merges with the ward's chars. So really the merge is just between the wards sales and wards chars.
- then it interpolates missing char data by a simple fill-in for missing years.


#### aggregate.do
input: ${DER}merge_sales.dta

- creates figures for aggregate sales over time



#### make_parents.do
- script that assigns brand-years to parent corporations

#### cpi-gas.do
uses:${RAW}auto_markups_freddata_txt/auto_markups_Annual.txt, ${RAW}gas-price.csv

output: ${DER}cpi.dta, ${DER}gas-price.dta

- cleans and saves annual gas prices and annual cpi


#### squishvins.xlsx
- This is from a squishvin data pull from edmunds. 
- the hope is that this can tell us bodystyle for many of the cars. But I think we will have to go through manually. 
