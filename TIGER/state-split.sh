#!/bin/sh

destination=
set -- `getopt d: "$@"`
while test $# -gt 0
do
    case "$1" in
    -d)    destination="$2"; shift;;
    :*)    echo >&2 "usage: $0 [-d dir]"
           exit 1;;
    *)     break;;
    esac
    shift
done

. fips-codes.sh

# create temp directory for transformed shapefiles
if [ ! -d tmp-shp ]; then
    mkdir tmp-shp
fi

# create destination directory for zip and geojson files
if [ ! -d $destination ]; then
    mkdir $destination
fi

# remove old state specific shape files
rm tl_????_??_*-??.???

# extract year & tiger file type from base shapefile name
year=`echo tl_2???_??_*.shp | sed 's/tl_\([0-9]*\).*\.shp/\1/g'`
type=`echo tl_2???_??_*.shp | sed 's/tl_[0-9]*_.*_\(.*\).shp/\1/g'`

echo $year $type

# split base shapefile by STATEFP code
echo "splitting"
mapshaper tl_${year}_us_${type}.shp encoding=latin1 -split STATEFP
echo "transforming"

# transform split files into WGS84 and move into state directories
for i in tl_${year}_us_${type}-??.shp; do
    ogr2ogr -t_srs EPSG:4326  tmp-shp $i
    fips=`echo $i | sed 's/tl_[0-9]*_.*_.*-\(.*\).shp/\1/g'`
    eval state=\$f_${fips}
    echo "Destination/State: " $destination/$state
    if [ ! -d $state ]; then
        mkdir $state
    fi
    if [ ! -d $destination/$state ]; then
        mkdir $destination/$state
    fi
    mv tmp-shp/* $state
    cd $state
    zip tl_${year}_us_${type}-${fips}.zip tl_${year}_us_${type}-${fips}.[sdp]??
    ogr2ogr -f "GeoJSON" tl_${year}_us_${type}-${fips}.geojson tl_${year}_us_${type}-${fips}.shp
    if test X"$destination" = X""; then
      tiger-metadata.sh -n
    else
      tiger-metadata.sh -d $destination/$state -e $state -n
      mv tl_${year}_us_${type}-??.zip $destination/$state
      mv *.geojson $destination/$state
    fi

    cd ..
done

rm tl_${year}_us_${type}-??.???

rmdir tmp-shp
