* assign makes to parents. Call from another script. 


gen parent = ""

* acura
replace parent="honda" if make=="acura"

* acura
replace parent="honda" if make=="honda"

* audi
replace parent="volkswagen" if make=="audi"

* volkswagen
replace parent="volkswagen" if make=="volkswagen"

* amc
local ix = "amc"
replace parent="chrysler" if make=="`ix'"
replace parent="renault" if make=="`ix'" & year<1987
replace parent="amc" if make=="`ix'" & year<1979

* jeep
local ix = "jeep"
replace parent="chrysler" if make=="`ix'"
replace parent="renault" if make=="`ix'" & year<1987
replace parent="amc" if make=="`ix'" & year<1979

* eagle
local ix = "eagle"
replace parent="chrysler" if make=="`ix'"
replace parent="renault" if make=="`ix'" & year<1987
replace parent="amc" if make=="`ix'" & year<1979

* alfa romeo
local ix = "alfa romeo"
replace parent="fiat" if make=="`ix'"
replace parent="ili" if make=="`ix'" & year<1986

* ferrari
replace parent="fiat" if make=="ferrari"


** GM
* chevrolet
replace parent="gm" if make=="chevrolet"

* chevrolet
replace parent="gm" if make=="gmc"

* oldsmobile
replace parent="gm" if make=="oldsmobile"

* buick
replace parent = "gm" if make=="buick"

* pontiac
replace parent = "gm" if make=="pontiac"

* saab
replace parent = "saab" if make=="saab"
replace parent = "gm" if make=="saab" & year>1989 & year<2011

* cadillac
replace parent = "gm" if make=="cadillac"

* Daewoo
* Had a joint venture from 82-96 -- all daewoo cars were really GM cars
replace parent = "gm" if make=="daewoo (gm)"
replace parent = "daewoo" if make=="daewoo (gm)" & year<2001

* hummer
replace parent = "gm" if make=="hummer"
replace parent = "am general" if make=="hummer" & year<1998


** chrysler group **
* chrysler
replace parent="chrysler" if make=="chrysler"

* dodge
replace parent="chrysler" if make=="dodge"

* ram
replace parent="chrysler" if make=="ram"

*
replace parent="chrysler" if make=="plymouth"

* bmw
replace parent="bmw" if make=="bmw"

* mini
replace parent="bmw" if make=="mini"


** Ford
* ford
replace parent="ford" if make=="ford"

* lincoln
replace parent="ford" if make=="lincoln"

* mercury
replace parent="ford" if make=="mercury"

* merkur
replace parent="ford" if make=="merkur"

* fiat
replace parent="fiat" if make=="fiat"

* geo
replace parent="gm" if make=="geo"

* saturn
replace parent="gm" if make=="saturn"

* hyundai
replace parent="hyundai" if make=="hyundai"

* kia
replace parent="hyundai" if make=="kia"
replace parent="kia" if make=="kia" & year<1998

* genesis
replace parent="hyundai" if make=="genesis"

* isuzu
replace parent="gm" if make=="isuzu"
replace parent="gm" if make=="isuzu truck"
* this is weird case. 1972=32%, 1998=49% 2006 toyota purchases 6%

* jaguar
replace parent="tata" if make=="jaguar"
replace parent="ford" if make=="jaguar" & year<2008
replace parent="jaguar" if make=="jaguar" & year<1990

* land rover
* Conected with Honda at some point in the 80s
replace parent="tata" if make=="land rover"
replace parent="ford" if make=="land rover" & year<2008
replace parent="bmw" if make=="land rover" & year<2000
replace parent="rover" if make=="land rover" & year<1994

* sterling (glorified acura legend. )
replace parent="rover" if make=="sterling cars"
replace parent="rover" if make=="sterling"


* toyota
replace parent="toyota" if make=="toyota"
replace parent="toyota" if make=="lexus"

 * daihatsu
replace parent="toyota" if make=="daihatsu"
replace parent="daihatsu" if make=="daihatsu" & year<1998

* scion
replace parent="toyota" if make=="scion"


* mercedes-benz
replace parent="daimler" if make=="mercedes-benz"

* Mistsubishi
* (Chrysler sold Mitsu cars in the 1970s -- challenger and plymouth sapporo)
* (plus, joint venture in the 1980s -- eclipse, talon, laser)
* In 1991, Chrysler sold stake in Mitsi (what was original stake??)
replace parent="mitsubishi" if make=="mitsubishi"

* Mazda
* Ford: 24.5% from 1979 to 1995. 33.4% from 1995 to 2008.
replace parent="mazda" if make=="mazda"

** Nissan
* Renault holds 42% voting stake since 1999
* Now mitsubishi part of Renault-Nissan-Mitsubishi Alliance
* Ford and Nissan: Mercury Villager and NIssan Quest from 1993-2002
replace parent="nissan" if make=="nissan"

* datsun
replace parent="nissan" if make=="datsun"

* infiniti
replace parent="nissan" if make=="infiniti"


* peugeot
replace parent="peugeot" if make=="peugeot"

* porsche -- joint ventures with VW since 1960s
replace parent="porsche" if make=="porsche"
replace parent="volkswagen" if make=="porsche" & year>2009

* renault
replace parent="renault" if make=="renault"


* volvo
replace parent="volvo" if make=="volvo"
replace parent="ford" if make=="volvo" & year>1999
replace parent="geely" if make=="volvo" & year>2010

* yugo
replace parent="zastava" if make=="yugo"

* subaru
replace parent="subaru" if make=="subaru"

* suzuki
replace parent="suzuki" if make=="suzuki"

* smart
replace parent="daimler" if make=="smart"

* tesla
replace parent="tesla" if make=="tesla"


*******************
*******************

* Chrysler has a bit of a ricky recent history
* - cerberus is a private equity company
replace parent = "fiat" if parent=="chrysler" & year>2009
replace parent = "cerberus" if parent=="chrysler" & inlist(year,2008,2009)
replace parent = "daimler" if parent=="chrysler" & year<2008 & year>1997




/*
Notes:
Renault-Nissan-Mitsubishi alliance began in 2016
