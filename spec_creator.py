#!/usr/bin/env python
# -*- coding: utf-8 -*-


import json
import csv
import os
import sys
from itertools import islice



TEMPLATE = u'''{"layout":"1 A4 landscape","srs":"EPSG:21781","units":"m","rotation":0,"app":"config","lang":"fr","dpi":"150","layers":[%(layers)s],"qrcodeurl":"%(qrcode)s","movie":false,"pages":[{"center":[501379.81499999936,127456.2985],"bbox":[497843.2177777772,125119.14572222222,504916.4122222216,129793.45127777779],"display":[802,530],"scale":"25000.0","dataOwner":"© swisstopo","thirdPartyDataOwner":false,"shortLink":"https://s.geo.admin.ch/72db21d4b9","rotation":0,"langfr":true,"timestamp":""}]}'''


WMTS_TPL = u'''{"layer":"ch.swisstopo.pixelkarte-farbe","opacity":1,"type":"WMTS","baseURL":"%(wmts_url)s","maxExtent":[420000,30000,900000,350000],"tileOrigin":[420000,350000],"tileSize":[256,256],"resolutions":[4000,3750,3500,3250,3000,2750,2500,2250,2000,1750,1500,1250,1000,750,650,500,250,100,50,20,10,5,2.5,2,1.5],"zoomOffset":0,"version":"1.0.0","requestEncoding":"REST","formatSuffix":"jpeg","style":"default","dimensions":["TIME"],"params":{"TIME":"current"},"matrixSet":"21781"}'''

VECTOR_TPL = u'''{"opacity":1,"type":"Vector","styles":{"0":{"id":0,"rotation":0,"externalGraphic":"%(vector_url)s","fillOpacity":1,"graphicWidth":18,"graphicHeight":24,"graphicXOffset":-9,"graphicYOffset":-24,"strokeOpacity":0}},"styleProperty":"_gx_style","geoJson":{"type":"FeatureCollection","features":[{"type":"Feature","geometry":{"type":"Point","coordinates":[501170.84375,127455.4765625]},"properties":{"label":"query_search","_gx_style":0}}]}}'''




resources = {
    'wmts': {
        'v': 'https://wmts.geo.admin.ch',
        'cf': 'https://wmts108.geo.admin.ch'
    },
    
    'vector': {
        'cf': 'https://map.geo.admin.ch/master/688362f/1704261351/1704261351/img/marker.png',
        'v': 'https://mf-geoadmin3.prod.bgdi.ch/master/688362f/1704261351/1704261351/img/marker.png',
        'ext': 'https://www.procrastinatio.org/assets/lib/leaflet/images/marker.png',
        'alt': 'https://dfa30utos8zzp.cloudfront.net/1455526563/img/marker.png',
        'wc': 'https://api.geo.admin.ch/color/255,165,0/heart-24@2x.png'
    },
    
    'qr': {
        'v': 'https://api3.geo.admin.ch/qrcodegenerator?url=https%3A%2F%2Fmap.geo.admin.ch%2F%3Flang%3Dfr%26topic%3Dech%26bgLayer%3Dch.swisstopo.pixelkarte-farbe%26layers_opacity%3D0.75%26X%3D127456.30%26Y%3D501379.81%26zoom%3D6',
        'ext': 'https://www.procrastinatio.org/tmp/qrcode.png'}
 }
    
    
def nested_values(d, values=[]):
  for k, v in d.iteritems():
    if isinstance(v, dict):
      nested_values(v, values)
    else:
      values.append(v)
      
  return values
    

def generate_spec(wmts, vector, qrcode):
    
    layers = []
    
    if wmts !='' and resources['wmts'].keys():
        wmts_url= resources['wmts'][wmts]
        layers.append(WMTS_TPL % ({'wmts_url': wmts_url}))
        
    if vector != '' and resources['vector'].keys():
        vector_url = resources['vector'][vector]
        
        layers.append(VECTOR_TPL % ({'vector_url': vector_url}))


    if qrcode !='':
        qrcode_url = resources['qr'][qrcode]
    else:
        qrcode_url = 'https://api3.geo.admin.ch/qrcodegenerator?url=https%3A%2F%2Fmap.geo.admin.ch%2F%3Flang%3Dfr%26topic%3Dech%26bgLayer%3Dch.swisstopo.pixelkarte-farbe%26layers_opacity%3D0.75%26X%3D127456.30%26Y%3D501379.81%26zoom%3D6'
        
    data = {'layers': ",".join(layers), 'qrcode': qrcode_url }



    spec = TEMPLATE %(data)


    return spec.encode('utf-8')

fname = "tests.csv"
file = open(fname, "rb")

print resources['wmts']
 
try:
    
    with open(fname) as f:
        reader = csv.reader(islice(f, 21,None))

    

    
        for row in reader:
        
	    basename, wmts, vector, qrcode, pdf, java_errors, remarks = row
	    filename = os.path.join('specs', basename + '.json')
	    print filename, wmts, vector, qrcode
	
	    spec = generate_spec(wmts, vector, qrcode)
	
	    with open(filename, 'w') as f:
                f.write(spec)
	    #print spec
finally:
    file.close()
    
urls = nested_values(resources)

print "\n".join(["'%s'" % u for u in urls])





      


