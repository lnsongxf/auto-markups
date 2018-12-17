# README for data construction

### outstanding issues
* "model" in blp data is hard to decipher
  * this matters b/c blp define a "product" as a make-model-design, so to link the two datasets we need to continue the same make-model-design
  * eg. if Honda Accord was designed in 1987 and not redesigned until 1994, we don't want to count the merge year, 1991, as a new design because we cannot link models across datasets.
  * Example: AMHORN71 is an American Motors Hornet, TYCORO71 is a Toyota Corolla, ODDELT72 is an Oldsmobile something.
  * I think an RA might be able to hand collect these data.
* blp has "standard AC" as a variable. Ward's does not, but has things like traction control and ABS.
  * standard AC is universal by 2000, this is related to how we model preferences
  * we could construct a variable called "luxury" that just designates if the car has premium standard features.


#### explore_blp.do
uses: ${RAW}blp_products.csv

output: ${DER}blp.dta

- basic clean of blp sales/characteristics data
- merge with parents



#### merge-sales.do
uses: ${DER}blp.dta, ${DER}wards.dta

output: ${DER}merged_sales.dta

- appends Ward's sales data to blp data



#### make_parents.do
- script that assigns brand-years to parent corporations

#### cpi-gas.do
uses:${RAW}auto_markups_freddata_txt/auto_markups_Annual.txt, ${RAW}gas-price.csv

output: ${DER}cpi.dta, ${DER}gas-price.dta

- cleans and saves annual gas prices and annual cpi
