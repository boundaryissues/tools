import sys
import os
import json

#decoder = json.JSONDecoder()

tiger_version = '2014'


url_prefix = 'https://github.com/boundaryissues/TIGER'
url_middle = '/tree/master/'

full_url_prefix = url_prefix + tiger_version + url_middle

embed_prefix = "https://embed.github.com/view/geojson/boundaryissues/TIGER"
embed_middle = '/master/'

def get_type (string):
    return string.partition("/")[2].partition("/")[0]

# traverse repository, find METADATA.json files

index = []

for root, dirs, files in os.walk( "."):
    for name in files:
        if name == 'METADATA.json':
# filter metadata file?
# load metadata file

            inputFile = open( os.path.join( root, name), "rb")
            result = json.load( inputFile)

#     build index data structure

            files = {}
            entry = {}
            if 'State' in result['Location'] :
                state = result['Location']['State']
            else :
                state = None
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
                        embed = embed_prefix + tiger_version + embed_middle
                        embed = embed + get_type( root) + "/"
                        if not state is None :
                            embed = embed + state + "/"
                        embed = embed + f
                        files[fileroot].append( {'embed' : embed})

            url = full_url_prefix + get_type( root) + "/"
            if not state is None :
                url = url + state + "/"
            entry['prefix'] = url
            entry['files'] = files
            entry['metadata'] = name
            if state is None :
                index_entry = {'country' : 'US'}
            else :
                index_entry = {'country' : 'US', 'state' : result['Location']['State']}
            entry['indexes'] = [ index_entry]

            index.append( entry)

# write out index to stdout for now

print json.dumps( index, indent=4, separators=(',',':'))
