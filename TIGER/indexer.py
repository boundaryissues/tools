import sys
import os
import json

#decoder = json.JSONDecoder()

# traverse repository, find METADATA.json files

index = []

for root, dirs, files in os.walk( "."):
    for name in files:
        if name == 'METADATA.json':
# filter metadata file?
# load metadata file
#            print( os.path.join( root, name))
            print( root, name)
            inputFile = open( os.path.join( root, name), "rb")
            result = json.load( inputFile)

#     build index data structure

            if not 'State' in result['Location'] :
                continue

            files = {}
            entry = {}
            candidate_files = os.listdir( root)
            for f in candidate_files:
                if f.endswith( ".geojson") or f.endswith( ".zip"):
                    partz = f.rpartition( ".")
                    fileroot = partz[0]
                    if partz[2] == 'geojson':
                        typ = 'geojson'
                    elif partz[2] == 'zip':
                        typ = 'shapefile'
                    if fileroot in files :
                        files[fileroot].append( typ)
                    else :
                        files[fileroot] = [typ]
                    if typ == 'geojson' :
                        embed = "https://embed.github.com/view/geojson"
                        embed = embed + "/openpolygons/TIGER2014/master/"
                        type2 = root.partition("/")
                        type3 = type2[2].partition( "/")
                        embed = embed + type3[0] + "/"
                        embed = embed + f
                        files[fileroot].append( {'embed' : embed})

            entry['prefix'] = "prefix for fetching from git goes here"
            entry['files'] = files
            entry['metadata'] = name
            index_entry = {'state' : result['Location']['State']}
            entry['indexes'] = [ index_entry]

            index.append( entry)

# write out index in appropriate place in front end repository

print json.dumps( index, indent=4, separators=(',',':'))
