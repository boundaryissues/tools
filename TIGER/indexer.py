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
            print( os.path.join( root, name))
            print( root, name)
            inputFile = open( os.path.join( root, name), "rb")
            result = json.load( inputFile)

#     build index data structure

            entry = {'metadata' : name}
            index_entry = {'state' : result['Location']['State']}
            entry['indexes'] = [ index_entry]

            files = {}
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
                        # need to add type
                        embed = embed + "typegoeshere/"
                        embed = embed + f
                        files[fileroot].append( {'embed' : embed})

            entry['files'] = files

            index.append( entry)

# write out index in appropriate place in front end repository

print json.dumps( index, indent=4, separators=(',',':'))
