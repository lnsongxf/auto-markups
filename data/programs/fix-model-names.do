*--------------------------------------------------
* Fix make names
* fix-make-names.do
* 1/25/2018
* Charlie Murry (BC) | Paul Grieco (PSU) | Ali Yurukoglu (Stanford)
*
*--------------------------------------------------

*--------------------------------------------------
* No Program Setup
*--------------------------------------------------
*version 15              // Set Version number for backward compatibility
*set more off            // Disable partitioned output
*set autotabgraphs on    // Graphs appear in a single window
*clear all               // Start with a clean slate
*set linesize 80         // Line size limit to make output more readable
*macro drop _all         // clear all macros
*capture log close       // Close existing log files
*log using clean-chars.log, text replace      // Open log file
* --------------------------------------------------
/*
## Description

There are some errors from upwork. This script changes model names from the
specs file so that they match the sales file.
*/

replace model=substr(model,1,8) if make=="LEXUS" & year<2007
replace model="JAGUAR XJ" if model=="JAGUAR XJ6/8" & year<2007
replace model="VOLVO 70" if model=="VOLVO 70 C" & year<2007
replace model="VOLVO 70" if model=="VOLVO 70 V" & year<2007
replace model="JAGUAR XJ6/8" if model=="JAGUAR XJ" & year>2006
replace model="4RUNNER" if model=="4RUNNER PASS"
replace model="WRX" if model=="WRX IMPREZA"
replace model="WRX" if model=="WRX (IMPREZA)"
replace model="VOYAGER" if model=="VOYAGER (CHRYSLER)"
