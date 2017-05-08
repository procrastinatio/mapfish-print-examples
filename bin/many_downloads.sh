#!/bin/bash



declare -a urls=(
               "https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/21781/17/7/9.jpeg"
               # empty
               "https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/21781/1/7/9.jpeg"
               # Not found
               "https://api3.geo.admin.ch//toto.png"
               'https://www.procrastinatio.org/assets/lib/leaflet/images/marker.png'
               'https://map.geo.admin.ch/master/688362f/1704261351/1704261351/img/marker.png'
               'https://dfa30utos8zzp.cloudfront.net/1455526563/img/marker.png'
               'https://mf-geoadmin3.prod.bgdi.ch/master/688362f/1704261351/1704261351/img/marker.png'
               "https://wmts108.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/21781/17/7/8.jpeg"
               "https://wmts.geo.admin.ch/1.0.0/ch.swisstopo.pixelkarte-farbe/default/current/21781/17/7/6.jpeg"
               'https://www.procrastinatio.org/tmp/qrcode.png'
               'https://api3.geo.admin.ch/qrcodegenerator?url=https%3A%2F%2Fmap.geo.admin.ch%2F%3Flang%3Dfr%26topic%3Dech%26bgLayer%3Dch.swisstopo.pixelkarte-farbe%26layers_opacity%3D0.75%26X%3D127456.30%26Y%3D501379.81%26zoom%3D6'
               ) 
               

for url in "${urls[@]}"; do

  echo "=================================="
  echo "${url}"
  echo
  java -jar apache_download-all-1.0.jar ${url}
  echo
done




