#!/bin/bash


HOST=https://print.geo.admin.ch



PRINT=printmulti
PRINT=print


function json_files {
    files=$(ls specs/*.json)
    for f in ${files}
    do
        echo "  $(basename ${f%.*})"
    done
}


function usage(){

    echo "Testing a spec file against the mapfish print server"
    echo
    echo "test_print <locate|remote> <spec file>"
    echo "Possible spec files (in 'specs' directory):"
    json_files

}


urlencode() {
    # urlencode <string>

    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}


function init() {
    local dir
    
    
    
    for dir in local remote; do
        echo "pdfs/${dir}"
        if [ ! -d "pdfs/${dir}" ]; then
             mkdir -p "pdfs/${dir}"
        fi
    done
}

function clean() {
    local action=$1
    local specfile=$2
    
    if [ -f "pdfs/${action}/${specfile}.pdf" ]; then
        rm  "pdfs/${action}/${specfile}.pdf"
    fi
}
    
    
function print_spec() {
    local specfile=$1
    if [ -f "specs/${specfile}.json" ]; then

    cat $HOME/print-examples/specs/${specfile}.json | jq '.'
    else
        echo "Cannot find the spec file"
        exit 4

fi

}

function local_print() {
    local specfile=$1
    
    java -Djava.awt.headless=true  -Djavax.net.debug=ssl:handshake:verbose  -cp $HOME/mapfish-print/build/libs/print-standalone-2.1-SNAPSHOT.jar  org.mapfish.print.ShellMapPrinter --config=$HOME/service-print/tomcat/config.yaml --spec=$HOME/print-examples/specs/${specfile}.json  --output=pdfs/local/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?
    
    return print_return_code
}


function remote_print() {
    local specfile=$1
    local json
    json=$(curl --max-time 60  --silent --header "Content-Type:application/json; charset=UTF-8" --header "Referer: http://ouzo.geo.admin.ch" --data @specs/${specfile}.json -X POST "${HOST}/${PRINT}/create.json?url=$(urlencode ${HOST}/${PRINT})")
    
    echo ${json}

}


if (( $# < 2 )); then
    usage
    exit 1
else
  action=$1
  specfile=$2
  init
fi









case "${action}" in


local) echo "Doing a local print"
       print_spec ${specfile}
       clean local ${specfile}
       local_print ${specfile}
      ;;

remote) echo "Doing a remote print"
print_spec ${specfile}
   clean remote ${specfile}
   json=$(remote_print  ${specfile})
   
   pdf_url=$(echo ${json} | jq -r '.getURL')
   
   echo $pdf_url
   
   
   curl -o "pdfs/remote/${specfile}.pdf" ${pdf_url}
   ;;
   
*) echo "Unkown action. Should be one of local,remote"
   exit 2

esac








