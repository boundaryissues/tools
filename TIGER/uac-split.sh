#!/bin/sh
#
# produces: top25 file
#           files for blocks of 100 starting with 1, e.g. 1-100, 101-200, ...

destination=""
set -- `getopt d:s "$@"`
while test $# -gt 0
do
    case "$1" in
    -d)    destination="$2"; shift;;
    :*)    echo >&2 "usage: $0 [-s] [-d dir]"
           exit 1;;
    *)     break;;
    esac
    shift
done


root_name=tl_2014_us_uac10

#
# pull list out of csv file
#
sort -r -n --key=3 --field-separator=: ua_list_all.csv > /tmp/sorted-ua-list

query_prefix="UACE10 IN "

block_start=1
last_block_start=3601
lines=`wc -l < /tmp/sorted-ua-list`
num_entries=100

if [ ! -d tmp-shp ]; then
    mkdir tmp-shp
fi


while [ $block_start -le $last_block_start ]; do
    if [ $block_start -eq $last_block_start ]; then
	num_entries=`expr ${lines} - ${block_start}`
    fi
#    echo $block_start $num_entries
    tail -n +${block_start} /tmp/sorted-ua-list | head -n ${num_entries} | cut -d : -f 1 > /tmp/${block_start}

    #process list

    id_list=""
    while read line
    do
#	echo $line
	if test X"$id_list" = X""; then
	    id_list=\'$line\'
	else
	    id_list=$id_list,\'$line\'
	fi
    done < "/tmp/${block_start}"

    block_end=`expr ${block_start} + ${num_entries} - 1`

    query="${query_prefix} (${id_list})"
    echo "$query"

    ogr2ogr -t_srs EPSG:4326 -where "$query" tmp-shp ${root_name}.shp

    cd tmp-shp
    start_end=${block_start}-${block_end}
    new_name=${root_name}-${start_end}

    mv ${root_name}.dbf ${new_name}.dbf
    mv ${root_name}.prj ${new_name}.prj
    mv ${root_name}.shp ${new_name}.shp
    mv ${root_name}.shx ${new_name}.shx
    zip ${new_name}.zip ${new_name}*

    ogr2ogr -f "GeoJSON" ${new_name}.geojson ${new_name}.shp
    mv ${new_name}.zip ${new_name}.geojson ..
    rm *
    cd ..

    # move if destination is set
    if [ X"$destination" = X"" ]; then
	tiger-metadata-other.sh
    else
	tiger-metadata-other.sh -d $destination/${start_end}
	mkdir ${destination}/${start_end}
	mv ${new_name}.zip ${new_name}.geojson $destination/${start_end}
    fi

    # increment for next go round
    block_start=`expr ${block_start} + ${num_entries}`
done
