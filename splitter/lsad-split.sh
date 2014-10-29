#!/bin/sh
#
# create temp directory for transformed shapefiles
if [ ! -d tmp-shp ]; then
    mkdir tmp-shp
fi

# create temp directory for geojson files
#if [ ! -d split-geojson ]; then
#    mkdir split-geojson
#fi

# create destination directory for zip and geojson files
if [ ! -d $1 ]; then
    mkdir $1
fi

# remove old lsad specific shape files
rm tl_????_??_*-??.???

# extract FIPS state code and tiger file type from base shapefile name
export YEAR=`echo tl_20??_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
export FIPS=`echo tl_2???_??_*.shp | sed 's/tl_[0-9]*_\(.*\)_.*.shp/\1/g'`
export TYPE=`echo tl_2???_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

#echo $YEAR $FIPS $TYPE

# split base shapefile by LSAD code
echo "splitting"
mapshaper tl_${YEAR}_${FIPS}_${TYPE}.shp encoding=latin1 -split LSAD 

echo "transforming"
# transform split files into WGS84
for i in tl_${YEAR}_${FIPS}_${TYPE}-??.shp; do
    ogr2ogr -t_srs EPSG:4326  tmp-shp $i
    mv tmp-shp/* .
done

rmdir tmp-shp

echo "converting to geojson"
# convert split shapefiles to geojson
for i in tl_${YEAR}_${FIPS}_${TYPE}-??.shp; do
    LSAD=`echo $i | sed 's/tl_[0-9]*_.*_.*-\(.*\).shp/\1/g'`
    echo $LSAD
    ogr2ogr -f "GeoJSON" tl_${YEAR}_${FIPS}_${TYPE}-${LSAD}.geojson $i
done
#mapshaper tl_${YEAR}_${FIPS}_${TYPE}-??.shp encoding=latin1 -o split-geojson/ format=geojson

# rename files for github
#cd split-geojson
#rename 's/.json/.geojson/' *.json
#cd ..

# zip up split shapefiles
for f in tl_${YEAR}_${FIPS}_${TYPE}-??.shp; do
    LSAD=`echo $f | sed 's/tl_[0-9]*_\(.*\)_\(.*\)-\(.*\).shp/\3/g'`
    echo "processing LSAD " $LSAD
    zip tl_${YEAR}_${FIPS}_${TYPE}-${LSAD}.zip tl_${YEAR}_${FIPS}_${TYPE}-${LSAD}.[sdp]??
done

# move zipped shapefiles and geojson files to proper destination
mv tl_${YEAR}_${FIPS}_${TYPE}-??.zip $1
#mv split-geojson/* $1
mv *.geojson $1

# create metadata
tiger-metadata.sh $1
