#!/bin/sh

#
country='US'
source='US Census Bureau (TIGER)'
year='2014'
sourceurlroot='ftp://ftp2.census.gov/geo/tiger/TIGER'
license='Public Domain'
crs='WGS84'
originalcrs='NAD83'

# region and SourceURL will be computed on the fly

# load table of fips codes
. fips-codes.sh


# remove old lsad specific shape files
rm tl_????_??_*-??.???

# extract year, FIPS state code and tiger file type from base shapefile name
year=`echo tl_????_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
fips=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_\(.*\)_.*.shp/\1/g'`
type=`echo tl_????_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

echo $year $fips $type

if ! test X"$fips" = X"us"; then
   # get state postal code
   eval region=\$f_${fips}
else
   region="us"
fi

echo "Region:" $region

sourceurl=${sourceurlroot}${year}/${type}/tl_${year}_${fips}_${type}.zip
#echo $sourceurl

typestring=""

case $type in

state) typestring="States and State equivalents" ;;

county) typestring="Counties and County equivalents" ;;

cousub) typestring="County Subdivision" ;;

place) typestring="TIGER Places (Cities & other Municipalities, CDPs)" ;;

concity) typestring="Consolidated City/County Government" ;;

cnecta) typestring="New England Consolidated City/Town Government" ;;

esac

echo $typestring

lsad_list=''

ls

for f in tl_${year}_${fips}_${type}-??.geojson; do
    lsad=`echo $f | sed 's/tl_[0-9]*_.*_.*-\(.*\).geojson/\1/g'`
    echo "processing lsad " $lsad
    if test X"$lsad_list" = X""; then
	lsad_list=\"${lsad}\"
    else
	lsad_list=${lsad_list},\"${lsad}\"
    fi
done

echo "{" > METADATA.json

echo "    \"Country\":  \"$country\"," >> METADATA.json
if ! test X"$fips" = X"us"; then 
    echo "    \"State\":  \"$region\"," >> METADATA.json
fi
if ! test X"$typestring" = X""; then
    echo "    \"Description\":  \"$typestring\"," >> METADATA.json
fi
echo "    \"Source\":  \"$source\"," >> METADATA.json
echo "    \"SourceURL\": \"$sourceurl\"," >> METADATA.json
echo "    \"LSADs\":  [ $lsad_list ]," >> METADATA.json
echo "    \"Year\":  \"$year\"," >> METADATA.json
echo "    \"License\": \"$license\"," >> METADATA.json
echo "    \"CRS\":  \"$crs\"," >> METADATA.json
echo "    \"OriginalCRS\": \"$originalcrs\"" >> METADATA.json

echo "}" >> METADATA.json

#mv METADATA.json $1/$region
mv METADATA.json $1/
