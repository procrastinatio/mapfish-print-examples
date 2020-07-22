Mapfish Print examples
=====================


Some examples specification files to use with MapFish Print v2


## Using cUrl


    curl --max-time 60  --silent --header "Content-Type:application/json; charset=UTF-8" --header "Referer: http://ouzo.geo.admin.ch" \
    --data @specs/simple.json -X POST "https://print.geo.admin.ch/print/create.json?url=https%3A%2F%2Fprint.geo.admin.ch%2Fprint%2Fcreate.json"

Response


    {"getURL":"https://print.geo.admin.ch/print/8915298261794515909.pdf.printout"}
    
Download the PDF

    $ curl -o mapfish.pdf -H "Referer: https://map.geo.admin.ch" https://print.geo.admin.ch/print/8915298261794515909.pdf.printout
    
Everything fine

    $ file mapfish.pdf 
    mapfish.pdf: PDF document, version 1.5

## Use the provided script


    $ ./test_print_server.sh remote simple
    
PDF has been generated and downloded to

    ls -l pdfs/remote/
    total 8
    -rw-rw-r-- 1 marco marco 253 mai  9 18:19 marker_wc_only.pdf
    -rw-rw-r-- 1 marco marco 253 mai 11 09:00 simple.pdf

## Using custom host


     HOST=service-print.dev.bgdi.ch BASEURL=http://10.220.4.120:9090  ./test_print_server.sh remote  lv95-wmts-simplified-protocol




## Run all scripts

     $ for f in $(ls specs); do $(./test_print_server.sh remote   ${f%%.*}); done




## Large specs files

`squash` example:

    https://map.geo.admin.ch/?lang=fr&topic=ech&bgLayer=ch.swisstopo.pixelkarte-farbe&X=190000.00&Y=660000.00&zoom=1&catalogNodes=457,532&layers_opacity=0.75,1,0.75,1,1,1,1,0.75,0.75,0.75,0.75,0.75,0.75,0.75,0.75,1,0.75,0.75,1,1,0.75&layers=ch.bafu.naqua-grundwasser_psm,ch.bafu.bundesinventare-amphibien_anhang4,ch.bafu.bundesinventare-amphibien,ch.bafu.bundesinventare-amphibien_wanderobjekte,ch.bafu.fischerei-aeschen_kernzonen,ch.bafu.fischerei-aeschen_laichplaetze,ch.bafu.fischerei-aeschen_larvenhabitate,ch.blw.klimaeignung-futterbau,ch.blw.klimaeignung-getreidebau,ch.blw.klimaeignung-kartoffeln,ch.blw.klimaeignung-koernermais,ch.blw.klimaeignung-kulturland,ch.blw.klimaeignung-spezialkulturen,ch.blw.klimaeignung-typ,ch.blw.klimaeignung-zwischenfruchtbau,ch.bafu.nabelstationen,ch.blw.niederschlagshaushalt,ch.bafu.laerm-bahnlaerm_tag,ch.bav.kataster-belasteter-standorte-oev,ch.bafu.schutzgebiete-biosphaerenreservate,ch.bafu.laerm-bahnlaerm_nacht,WMS%7C%7CNatur-%20und%20Landschaftsschutz%7C%7Chttp:%2F%2Fwms.geo.gl.ch%2FPublic%3F%7C%7CNatur-%20und%20Landschaftsschutz%7C%7C1.3.0,KML%7C%7Chttp:%2F%2Fopendata.utou.ch%2Furbanproto%2Fgeneva%2Fgeo%2Fkml%2FRoutes.kml


## PNG to JPEG or PNG

     convert  -background white  -alpha remove  -density 250  lv95_simple_a6_256dpi.pdf -quality 92 lv95_simple_a6_256dpi_density250.jpeg
     
     DIN A6 is 	105 × 148 mm	4.13 × 5.83 (inches)    à 256dpi  1057 x1492 px  à 300 dpi   1240x1759 px
     
     Pour Poscard Creator (1819x1311 px)


     convert -units pixelspercentimeter -density 256  pdfs/remote/lv95_versoix_swissimage_a6_256dpi_rotated.pdf  -resize 124% pdfs/remote/lv95_versoix_swissimage_a6_256dpi_rotated_optimized.png
     
     convert -units pixelspercentimeter -density 256  pdfs/remote/lv95_habern_a6_snowsport_256dpi.pdf  -resize 124% pdfs/remote/lv95_habern_a6_snowsport_256dpi_optimized.png

     
