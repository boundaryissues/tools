#!/bin/sh
#
# create temp directory for geojson files
if [ ! -d split-geojson ]; then
    mkdir split-geojson
fi

# create destination directory for zip and geojson files
if [ ! -d $1 ]; then
    mkdir $1
fi

# extract FIPS state code and tiger file type from base shapefile name
export FIPS=`echo tl_2014_??_*.shp | sed 's/tl_2014_\(.*\)_\(.*\).shp/\1/g'`
export TYPE=`echo tl_2014_??_*.shp | sed 's/tl_2014_\(.*\)_\(.*\).shp/\2/g'`

#echo $FIPS $TYPE

# split base shapefile by LSAD code
mapshaper tl_2014_${FIPS}_${TYPE}.shp encoding=latin1 -split LSAD 

# convert split shapefiles to geojson
mapshaper tl_2014_${FIPS}_${TYPE}-??.shp encoding=latin1 -o split-geojson/ format=geojson

# rename files for github
cd split-geojson
rename 's/.json/.geojson/' *.json
cd ..

# zip up split shapefiles
for f in tl_2014_${FIPS}_${TYPE}-??.shp; do
    LSAD=`echo $f | sed 's/tl_2014_\(.*\)_\(.*\)-\(.*\).shp/\3/g'`
    echo "processing LSAD " $LSAD
    zip tl_2014_${FIPS}_${TYPE}-${LSAD}.zip tl_2014_${FIPS}_${TYPE}-${LSAD}.[sdp]??
done

# move zipped shapefiles and geojson files to proper destination
mv tl_2014_${FIPS}_${TYPE}-??.zip $1
mv split-geojson/* $1
