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


## Run all scripts

     $ for f in $(ls specs); do $(./test_print_server.sh remote   ${f%%.*}); done
