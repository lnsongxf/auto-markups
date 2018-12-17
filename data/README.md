# README for data construction



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
-
