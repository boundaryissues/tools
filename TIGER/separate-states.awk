#!/usr/bin/awk -f
BEGIN { FS="--"; OFS="," }
{
    for( i=1; i<=NF; i++)
	$1=trim($1);print
}
function ltrim(s) { sub(/^ +/, "", s); return s }
function rtrim(s) { sub(/ +$/, "", s); return s }
function trim(s) { return rtrim(ltrim(s)); }
