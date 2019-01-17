# README for data construction

### outstanding issues
* Need to merge in EPA style (or other style) somehow
  * I propose using a modifies version of the EPA-class guide.
  * I could merge a lot based on an aux. dataset, but we will need to hand fill in many of the pre-1991 sample
* "model" in blp data is hard to decipher
  * this matters b/c blp define a "product" as a make-model-design, so to link the two datasets we need to continue the same make-model-design
  * eg. if Honda Accord was designed in 1987 and not redesigned until 1994, we don't want to count the merge year, 1991, as a new design because we cannot link models across datasets.
  * Example: AMHORN71 is an American Motors Hornet, TYCORO71 is a Toyota Corolla, ODDELT72 is an Oldsmobile something.
  * I think an RA might be able to hand collect these data.
* blp has "standard AC" as a variable. Ward's does not, but has things like traction control and ABS.
  * standard AC is universal by 2000, this is related to how we model preferences
  * we could construct a variable called "luxury" that just designates if the car has premium standard features.


### List of fixes that need to be addressed manually
* ACURA RL 1996, 1997, 2000 (weird price)


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
