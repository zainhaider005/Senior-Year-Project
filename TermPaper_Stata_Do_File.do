* PSLM 2013-14 (Poverty 29.06%)
cd "D:\Lums\Senior Year\Poverty and Income Distribution\Project"
set more off
use sec_6abcde, clear

* Step 1
drop if itc==1000 | itc==1001 | itc==1002 | itc==1003
drop if itc==2000 | itc==2001 | itc==2002
drop if itc==4000
drop if itc==5000 | itc==5001 | itc==5002
drop if itc>=6000

* Step 2
egen fexp = rsum(v*) if (itc>=1101 & itc<=2711) 
replace fexp= fexp*2.17 if (itc>=1101 & itc<=1903)

egen nfexp = rsum(v*) if (itc>=2801 & itc<=3003) | (itc>=4101  & itc<=5904) 
replace nfexp= nfexp/12 if (itc>=5101 & itc<=5904)

save expsheet, replace
 
* Step 3

collapse (sum)  fexp nfexp (mean) province region psu, by (hhcode)

order province region psu hhcode fexp nfexp 

lab val province province
lab val region region

save hhexp, replace

* Step 4
 
use roster, clear
gen ad =.
replace ad = 0.4298 if  (age<1) 
replace ad = 0.5549 if  (age>=1 & age<=4)
replace ad = 0.7523 if  (age>=5 & age<=9) 
replace ad = 1.1983 if (s1aq04 ==1 & (age>=10 & age<=14)) 
replace ad = 1.3136 if (s1aq04==1 & (age>=15 & age<=19))
replace ad = 1.1745 if (s1aq04==1 & (age>=20 & age<=39))
replace ad = 1.1234 if (s1aq04==1 & (age>=40 & age<=49))
replace ad = 1.0468 if (s1aq04==1 & (age>=50 & age<=59)) 
replace ad = 0.9132 if (s1aq04==1 & (age>=60))
 
replace ad = 1.0485 if (s1aq04==2 & (age>=10 & age<=14)) 
replace ad = 0.9881 if (s1aq04==2 & (age>=15 & age<=19))
replace ad = 0.8851 if (s1aq04==2 & (age>=20 & age<=39))
replace ad = 0.8409 if (s1aq04==2 & (age>=40 & age<=49))
replace ad = 0.7966 if (s1aq04==2 & (age>=50 & age<=59))
replace ad = 0.6945 if (s1aq04==2 & (age>=60))
  
bys hhcode: egen adult_eq=total(ad)
bys hhcode: egen hs=count(hhcode)

drop _merge
merge m:1 psu using "weight_file"

keep province region psu hhcode idc s1aq02 s1aq04 age adult_eq hs weights
order province region psu hhcode idc s1aq02 s1aq04 age adult_eq hs weights

save hhad, replace

collapse(mean) province region psu hs, by (hhcode)
save hhad1

use hhad
 
* Step 5
merge m:1 hhcode using"hhexp.dta"
drop _merge

gen pmtexp=(fexp +nfexp)/adult_eq

gen pov_line=3030.32

gen poverty=1 if pmtexp<pov_line
recode poverty (.=0)
tab poverty [aw=weights]

save poverty2013-14, replace

* Step 6

* Pasche Index to control for regional price variation

* A: save psu and weights in a separate file

use poverty2013-14, clear
collapse (mean) weights province region, by(psu)
save weights, replace

*B: generate price index for fortnightly food consumption

use sec_6abcde, clear

*i) drop totals & subtotals and keep fortnightly consumption 

drop if itc==1000 | itc==1001 |itc==1002 |itc==1003 
drop if itc==2000 | itc==2001 | itc==2002
drop if itc==4000 | itc==5000 | itc==5001 | itc==5002 
drop if itc>=6000

drop if itc>=2000

*ii) Drop Items
*	a) Without Quantities

drop if itc==1108 |itc==1109

*    	b) Others

drop if itc==1309| itc==1401 | itc==1509 | itc==1608

*iii) Generate q & v and drop those where q=0|q=. & v=0|v=.

egen q= rsum(q1 q2 q3 q4)
egen v= rsum(v1 v2 v3 v4)

drop if q==0 | q==.
drop if v==0 | v==.

keep psu hhcode itc q v

*iv) Check if hhcode & itc uniquely identify observations

bys hhcode itc: gen dup_=cond(_N==1,0,_n)

assert dup_==0

*v) generate prices of fortnightly food consumption

gen ph=v/q

gen fortnight=1

sort hhcode

compress

*vi) save this file as price_fort

save price_fort, replace

* C: generate price index for monthly food consumption

use sec_6abcde, clear

*i)  drop totals & subtotals and keep monthly consumption 

drop if itc==1000 | itc==1001 |itc==1002 |itc==1003 
drop if itc==2000 | itc==2001 | itc==2002
drop if itc==4000 | itc==5000 | itc==5001 | itc==5002 
drop if itc>=6000

drop if itc<2000 | itc>2800

*ii) Drop Items
*	a) Without Quantities
drop if  itc==2706|itc==2708|itc==2709
*	b) Others
drop if itc==2105|itc==2206|itc==2304|itc==2403|itc==2506

*iii) Generate q & v and drop those where q=0|q=. & v=0|v=.

egen q= rsum(q1 q2 q3 q4)
egen v= rsum(v1 v2 v3 v4)

drop if q==0 | q==.
drop if v==0 | v==.

keep psu hhcode itc q v

*iv) Check if hhcode & itc uniquely identify observations

bys hhcode itc: gen dup_=cond(_N==1,0,_n)
assert dup_==0 

*v) generate prices of fortnightly food consumption

gen ph=v/q

gen fortnight=0

table itc, c(n ph)

sort hhcode

compress

*vi) save this file as price_monthly   

save price_monthly, replace

*Step 4: Append both these food files

*i) append files

append using price_fort

drop dup_

*ii) save this file as foodprice

save foodprice, replace

* D: Merge this file with hhad1 and weight to get hs & weight

* hhad1 has to be at household level

sort hhcode
merge m:1 hhcode using "hhad1"

tab _merge
drop if _merge==2
drop _merge
order psu, b(hhcode)

sort psu

merge m:1 psu using "weights" 
tab _merge
drop _merge

* E: 
*i) drop households with less than 5 items of consumption

gen one=1
egen items=sum(one), by(hhcode)
count if items==.

tab items if items<5
list hhcode itc items if items<5, sepby(hhcode)

keep if items>=5

drop one items

*ii) generate population weights

gen popwgt= weights*hs

*iii) generate sub stratum variable

gen subst= int(psu/100)

* F: Clean the data

* i) drop the outlier prices

table itc, c(p99 ph p1 ph)

* prices do not vary much no need to clean the data

* ii) count # of prices by each item

egen double n_p=count(ph), by(itc)

sort hhcode itc

compress
* iii) save the file as foodprice_hhweights

save foodprice_hhweights, replace

* G: Generate median prices of each item at psu, substratum and national level

*i) At psu level

preserve
collapse (median) psu_medph=ph [aw=weights], by(psu itc)

sort psu itc

save medpsup, replace
restore

*ii) At substratum level

preserve
collapse (median) subst_medph=ph [aw=weights], by(subst itc)

sort subst itc

save medsubstp, replace
restore

*iii) At national level
preserve
collapse (median) p0=ph [aw=weights], by(itc)

sort itc

save mednatp, replace
restore


* H: Generate total expenditure & item level expenditure per psu

*i) Generate a v_i=v & convert fortnightly consumption into monthly

gen v_i=v
replace v_i= 2.17*v if fortnight==1 

*ii) Generate total monthly household expenditure

egen double hhexp= total(v_i), by(hhcode)

label var hhexp "total monthly hh exp"

*iii) Generate total monthly psu level expenditure

egen double psuexp= total(v_i*popwgt), by(psu)

label var psuexp "Total monthly weighted exp in psu"

*iv) Generate total monthly psu level expenditure by item

bys psu itc:egen double psuexp_i=total(v_i*popwgt) 

label var psuexp_i "Total monthly weighted exp of item i in each psu"

*v) Generate share of expenditure on each item per psu in total psu's expenditure

gen double wi=psuexp_i/psuexp

label var wi "Share of item i in psu total exp"

*vi) Keep every item once for each psu
bys psu itc: keep if _n==_N

save foodprice_hhweights, replace

* I: Compute Pasche index 

* i) keep the psu level variables

keep psu itc hhexp psuexp psuexp_i wi weights subst 

*ii) merge the median price files with this file

*	a) psu level

sort psu itc
merge psu itc using medpsup, uniq
tab _merge
drop _merge

*	b) substratum level

sort subst itc
merge subst itc using medsubstp, uniqusing
tab _merge
drop _merge

*	c) national level

sort itc
merge itc using mednatp, uniqusing
tab _merge
drop _merge

*	d) verify that the median prices at psu level are not missing

count if psu_medph==.
* not missing

gen double lnindex= wi*(p0/psu_medph)
label var lnindex "sum over items wi*(p0/psu_medph)"

codebook lnindex

sort psu itc
list psu itc psu_medph p0 wi lnindex weights in 1/171, sepby(psu)

collapse (sum)lnindex (mean)weights, by(psu)

gen psuindex=1/lnindex

list psu lnindex psuindex weights, sep(0)

label var lnindex "Sum (over items) wi*(p0/ppsu)"
label var psuindex "Paasche Index by PSU"

sum psuindex [aw=weights]
return list
gen psuindex2= psuindex/r(mean)
sum psuindex2 [aw=weights]

gen province=int(psu/10000000)

label def pr 1"kpk" 2"punjab" 3"sindh" 4"baluchistan" 6"islamabad"
label values province pr

*drop region
gen region= real(substr(string(psu/1000),5,1))

label def reg 1"rural" 2"urban"
label values region reg

table province region [aw=weight], c(mean psuindex) row col

sort psu
compress

save pascheindex, replace

use poverty2013-14, clear

*drop _merge
merge m:1 psu using "pascheindex"

drop _merge

gen pmtexp_d= [(fexp/psuindex2)+nfexp]/ad

gen poor=1 if pmtexp_d<pov_line
replace poor=0 if poor==.

tabstat poor [aw=weights]




gen m_hh=1 if s1aq02==1 & s1aq04==1
bys hhcode : egen male_hh_head=mean(m_hh )
recode male_hh_head (.=0)
tab male_hh_head
drop m_hh

gen hh_h_age= age if s1aq02==1
bys hhcode: egen hh_head_age=mean(hh_h_age)
recode hh_head_age (.=0)
drop hh_h_age
save poverty2013-14, replace

*Make a no. of dependents variable by seeing if the person works or not.
use sec_1b,clear
gen working=1 if s1bq01==1 |  s1bq03==2
bys hhcode: egen no_of_working=sum(working)
save sec_1b,replace
use poverty2013-14,clear
merge 1:1 hhcode idc using "D:\Lums\Senior Year\Poverty and Income Distribution\Project\sec_1b.dta", keepusing (no_of_working employment_status* sector*)
drop _merge
gen dependents=hs-no_of_working
bys hhcode:egen no_of_dependents=mean(dependents)
drop dependents 
save poverty2013-14, replace


merge m:1 hhcode using "D:\Lums\Senior Year\Poverty and Income Distribution\Project\sec_5m.dta", keepusing (s5q03)
drop _merge
rename s5q03 rooms
destring rooms,gen(Rooms)
drop rooms
save poverty2013-14, replace


use sec_8,clear
tab itc
tab itc,nolab
reshape wide value, j(itc) i(hhcode)
keep value802 value804 value805 value8061 value8062 hhcode
egen international_remittances=rsum( value804 value805 value8061 value8062)
rename value802 internal_remittance
save Remittances


use poverty2013-14,clear
merge m:1 hhcode using "Remittances.dta", keepusing (international_remittances)
drop _merge
save poverty2013-14,replace

collapse (mean) region province hs weights pmtexp poor male_hh_head hh_head_age no_of_dependents international_remittances, by(hhcode )
save Final_poverty2013-14,replace

merge 1:1 hhcode using PSLM_HIES2013-14, keepusing(lowly_educated medium_educated highly_educated)
drop _merge

tab region , gen(region)
rename region1 Rural
rename region2 Urban

gen International_remittance_dummy=1 if international_remittances>0
recode International_remittance_dummy(.=0)

gen Small_hs=1 if hs<=5
recode Small_hs (.=0)
gen Large_hs=1 if hs>10
recode Large_hs (.=0)
gen Medium_hs=1 if hs>5 & hs<=10
recode Medium_hs(.=0)

tab province, gen(prov)
rename prov1 KPK
rename prov2 Punjab
rename prov3 Sindh
rename prov4 Balochistan

rename lowly_educated Lowly_educated 
rename medium_educated Medium_educated 
rename highly_educated Highly_educated
rename male_hh_head Male_hh_head 
rename hh_head_age HH_head_age 
rename no_of_dependents No_of_dependents

save Final_poverty2013-14,replace

psmatch2 International_remittance_dummy  , mahalanobis( Male_hh_head HH_head_age No_of_dependents Lowly_educated Medium_educated Highly_educated Small_hs Large_hs Rural KPK Punjab Sindh ) outcome(poor) population altvariance kernel bwidth(1) caliper(1)  ate
pstest Male_hh_head HH_head_age No_of_dependents Lowly_educated Medium_educated Highly_educated Small_hs Large_hs Rural KPK Punjab Sindh , sum

merge 1:1 hhcode using PSLM_HIES2013-14
drop _merge
save Final_poverty2013-14,replace


use poverty2013-14
collapse (mean) sector* employment_status*, by(hhcode)
save new
use Final_poverty2013-14
merge 1:1 hhcode using new
drop _merge
 
rename sub_land Sub_land 
rename eco_land Eco_land 
rename large_land Large_land 
rename livestock Livestock 
rename financial_asset Financial_asset
rename poor Poor
rename illitrate Illitrate
rename no_land No_land

save Final_poverty2013-14,replace

dprobit Poor International_remittance_dummy Rural KPK Punjab Sindh dist* Male_hh_head HH_head_age No_of_dependents Lowly_educated Medium_educated Highly_educated Small_hs Large_hs Sub_land Eco_land Large_land Livestock Financial_asset sector* employment_status* if _support==1
dprobit Poor International_remittance_dummy Rural KPK Punjab Sindh dist* Male_hh_head HH_head_age No_of_dependents Lowly_educated Medium_educated Highly_educated Small_hs Large_hs Sub_land Eco_land Large_land Livestock Financial_asset sector* employment_status* if _support==1 & Urban==1
dprobit Poor International_remittance_dummy Rural KPK Punjab Sindh dist* Male_hh_head HH_head_age No_of_dependents Lowly_educated Medium_educated Highly_educated Small_hs Large_hs Sub_land Eco_land Large_land Livestock Financial_asset sector* employment_status* if _support==1 & Rural==1




