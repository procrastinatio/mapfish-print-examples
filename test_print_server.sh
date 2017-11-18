#!/bin/bash

_V=0

DEFAULT_BASEURL=https://print.geo.admin.ch

# DEFAULT_BASEURL=https://service-print.dev.bgdi.ch

# BASEURL=https://service-print.int.bgdi.ch/mom_cf_fix


BASEURL_FIXED=https://service-print.int.bgdi.ch/mom_cf_fix


BASEURL=${BASEURL:-${DEFAULT_BASEURL}}

DEFAULT_HOST=$(echo ${BASEURL} | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")

HOST=${HOST:-${DEFAULT_HOST}}


MAPFISH_PRINT=print-standalone-2.1.3-SNAPSHOT.jar


PRINT=printmulti
PRINT=print
#PRINT=pdf  # for tomcat




function log () {
    if [[ $_V -eq 1 ]]; then
        echo "$@"
    fi
}


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
    echo "test_print <local|tomcat|remote> <spec file>"
    echo "BASEURL=${BASEURL}"
    echo "HOST=${HOST}"
    echo "MAPFISH_PRINT=${MAPFISH_PRINT}"
    echo "PRINT=${PRINT}"
    echo
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
    
    for dir in "pdfs/local" "pdfs/tomcat" "pdfs/remote" "pdfs/gradle" "pdfs/fixed" logs; do
        #echo "${dir}"
        if [ ! -d "${dir}" ]; then
             mkdir -p "${dir}"
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
        cat specs/${specfile}.json | jq '.'
    else
        echo "Cannot find the spec file"
        exit 4
    fi
}
function debug_print() {
    local specfile=$1
    
    #java -Djdk.tls.client.protocols=TLSv1.1,TLSv1.2 -Dhttps.protocols=TLSv1.1,TLSv1.2 -Ddeployment.security.SSLv2Hello=false -Ddeployment.security.SSLv3=false -Ddeployment.security.TLSv1=false -Ddeployment.security.TLSv1.1=true -Ddeployment.security.TLSv1.2=true -Djava.awt.headless=true  -Djavax.net.debug=ssl:handshake:verbose  -cp $HOME/mapfish-print/build/libs/${MAPFISH_PRINT}   org.mapfish.print.ShellMapPrinter --config=$HOME/service-print/tomcat/config.yaml --spec=specs/${specfile}.json  --output=pdfs/debug/${specfile}.pdf | tee logs/${specfile}.log
    java -Djava.awt.headless=true  -Djavax.net.debug=all  -cp $HOME/mapfish-print/build/libs/${MAPFISH_PRINT}   org.mapfish.print.ShellMapPrinter --config=$HOME/service-print/tomcat/config.yaml --spec=specs/${specfile}.json  --output=pdfs/debug/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?
    
    return $print_return_code
}

function local_print() {
    local specfile=$1
    
    java -Djava.awt.headless=true  -cp $HOME/mapfish-print/build/libs/${MAPFISH_PRINT}  org.mapfish.print.ShellMapPrinter --config=$HOME/service-print/tomcat/config.yaml --spec=specs/${specfile}.json  --output=pdfs/local/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?
    
    return $print_return_code
}

function gradle_print() {
    local specfile=$1
    
    cd ../mapfish-print
     ./gradlew run  -Dconfig=$HOME/service-print/tomcat/config.yaml -Dspec=specs/${specfile}.json  -Doutput=pdfs/gradle/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?

    cd -
    
    return $print_return_code
}

function remote_print() {
    local specfile=$1
    local url=$2
    local json
    #json=$(curl -v --max-time 60  --silent --header "Content-Type:application/json; charset=UTF-8" --header "Referer: http://ouzo.geo.admin.ch" --data @specs/${specfile}.json -X POST "${BASEURL}/${PRINT}/create.json?url=$(urlencode ${BASEURL}/${PRINT})")
    json=$(curl -v --max-time 60  --silent --header "Content-Type: application/json; charset=UTF-8" \
           --header "Referer: http://map.geo.admin.ch" --header "User-Agent: Zorba is debugging the print server" --header "Host: ${HOST}" --data @specs/${specfile}.json \
           -X POST "${url}/create.json?url=$(urlencode ${url})")
    
    echo ${json}

}

function preflight() {
    local action=$1
    local specfile=$2
    
    spec=$(print_spec ${specfile})
    log $spec
    clean ${action} ${specfile}

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

    preflight local ${specfile}
    local_print ${specfile}
    ;;

gradle) echo "Doing a gradle print"

    preflight gradle ${specfile}
    gradle_print ${specfile}
    ;;

debug) echo "Doing a debug print"

    preflight debug ${specfile}
    debug_print ${specfile}
    ;;

tomcat)
    tomcat_url=http://localhost:8009/service-print-main/pdf
    echo "Doing a local print on tomcat ${tomcat_url} (not for multiprint)"

    preflight remote ${specfile}
    json=$(remote_print  ${specfile} ${tomcat_url})
   
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo $pdf_url
    sleep 0.5
   
    curl -o "pdfs/tomcat/${specfile}.pdf" ${pdf_url}
    ;;

remote) echo "Doing a remote print"

    preflight remote ${specfile}
     
    movie=$(cat specs/${specfile}.json  | jq '.movie')
    
    if [ "${movie}" == "true" ]; then
       echo "Movie mode"
       PRINT=printmulti
    else
      PRINT=print
    fi
    # Multiprint
    if [ "${movie}" == "true" ]; then
     
        done="ongoing"
     
        #{"idToCheck":"1711102228415808"}
      
        first=$(remote_print  ${specfile} ${BASEURL}/${PRINT})
      
        #  {"status":"done","getURL":"https://service-print.prod.bgdi.ch/print/-multi1711102035267851.pdf.printout","written":109884753}
     
        idToCheck=$(echo ${first} | jq -r '.idToCheck')
        echo "idToCheck=$idToCheck"
     
        # {"status":"ongoing","total":23,"done":0}
     
        while [[ "${status}" != "done" ]]; 
           do sleep 5; 
           json=$(curl -s  "${BASEURL}/printprogress?id=$idToCheck")
           echo $json
           status=$(echo $json | jq -r '.status')
           echo "waiting  $json $status" [[ "${status}" != "done" ]]  && echo not-equal || echo equal
        
       done

    # simple
    else
        json=$(remote_print  ${specfile} ${BASEURL}/${PRINT})
    fi
    
    # Get the PDF 
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo "#### $pdf_url ####"

    sleep 0.5
    
    pdf_file="pdfs/remote/${specfile}.pdf"
   
    curl -s -o ${pdf_file} ${pdf_url}
    
    echo "Dowloaded to: ${pdf_file}"
    echo
    echo $(file ${pdf_file})
    
    echo $PRINT
    ;;

fixed) echo "Doing a remote print on fixed"

    preflight remote ${specfile}
    json=$(remote_print  ${specfile} ${BASEURL_FIXED})
   
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo $pdf_url
   
    curl -o "pdfs/fixed/${specfile}.pdf" ${pdf_url}
    ;;
   
*) echo "Unkown action. Should be one of local,remote"
   exit 2

esac








