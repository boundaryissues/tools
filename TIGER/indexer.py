import sys
import os
import json

#decoder = json.JSONDecoder()

tiger_version = '2014'


data_url_prefix = 'https://github.com/boundaryissues/TIGER'
data_url_middle = '/tree/master/'

full_data_url_prefix = data_url_prefix + tiger_version + data_url_middle

#embed_prefix = "https://embed.github.com/view/geojson/boundaryissues/TIGER"
#embed_middle = '/master/'

def get_type (string):
    return string.partition("/")[2].partition("/")[0]

def get_range( string):
    return string.partition("-")[2].partition(".")[0]

# traverse repository, find METADATA.json files

collection = {}
filelist = []
index = {'collection' : collection, 'files' : filelist}

collection['metadataURL'] = full_data_url_prefix
collection['dataURL'] = full_data_url_prefix
collection['name'] = 'TIGER' + tiger_version
collection['indexes'] = {'country' : 'US'}

for root, dirs, files in os.walk( "."):
    for name in files:
        if name == 'METADATA.json':
# filter metadata file?
# load metadata file

            tiger_type = get_type( root)

            if tiger_type == '':
                break

            inputFile = open( os.path.join( root, name), "rb")
            result = json.load( inputFile)

#     build index data structure

            entry = {}
            if 'State' in result['Location'] :
                state = result['Location']['State']
            else :
                state = None
            candidate_files = os.listdir( root)
            fileroot = ''
            index_entry = {}
            file_type_list = []
            for f in candidate_files:
                if f.endswith( ".geojson") or f.endswith( ".zip"):
                    partz = f.rpartition( ".")
                    fileroot = partz[0]
                    if partz[2] == 'geojson':
                        typ = 'geojson'
                    elif partz[2] == 'zip':
                        typ = 'zipped_shapefile'
                    file_type_list.append( typ)
                    if state is None :
                        index_entry = {'country' : 'US'}
                    else :
                        index_entry = {'country' : 'US', 'states' : [ result['Location']['State'] ]}
            entry['name'] = fileroot
            entry['types'] = file_type_list
            entry['indexes'] = index_entry
            subdir = tiger_type
            if tiger_type == 'county' or tiger_type == 'place' or tiger_type == 'cousub':
                subdir = subdir + '/' + state
            elif tiger_type == 'uac':
                subdir = subdir + '/' + get_range( f)
            entry['subdir'] = subdir

            filelist.append( entry)

# write out index to stdout for now

print json.dumps( index, indent=4, separators=(',',':'))
