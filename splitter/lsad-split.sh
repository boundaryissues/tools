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

# extract fips state code and tiger file type from base shapefile name
year=`echo tl_20??_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
fips=`echo tl_2???_??_*.shp | sed 's/tl_[0-9]*_\(.*\)_.*.shp/\1/g'`
type=`echo tl_2???_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

#echo $year $fips $type

# split base shapefile by LSAD code
echo "splitting"
mapshaper tl_${year}_${fips}_${type}.shp encoding=latin1 -split LSAD 

echo "transforming"
# transform split files into WGS84
for i in tl_${year}_${fips}_${type}-??.shp; do
    ogr2ogr -t_srs EPSG:4326  tmp-shp $i
    mv tmp-shp/* .
done

rmdir tmp-shp

echo "converting to geojson"
# convert split shapefiles to geojson
for i in tl_${year}_${fips}_${type}-??.shp; do
    lsad=`echo $i | sed 's/tl_[0-9]*_.*_.*-\(.*\).shp/\1/g'`
    echo $lsad
    ogr2ogr -f "GeoJSON" tl_${year}_${fips}_${type}-${lsad}.geojson $i
done
#mapshaper tl_${year}_${fips}_${type}-??.shp encoding=latin1 -o split-geojson/ format=geojson

# rename files for github
#cd split-geojson
#rename 's/.json/.geojson/' *.json
#cd ..

# zip up split shapefiles
for f in tl_${year}_${fips}_${type}-??.shp; do
    lsad=`echo $f | sed 's/tl_[0-9]*_\(.*\)_\(.*\)-\(.*\).shp/\3/g'`
    echo "processing lsad " $lsad
    zip tl_${year}_${fips}_${type}-${lsad}.zip tl_${year}_${fips}_${type}-${lsad}.[sdp]??
done

# move zipped shapefiles and geojson files to proper destination
mv tl_${year}_${fips}_${type}-??.zip $1
#mv split-geojson/* $1
mv *.geojson $1

# create metadata
tiger-metadata.sh $1
