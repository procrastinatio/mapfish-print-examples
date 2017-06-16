#!/bin/bash


DEFAULT_HOST=https://print.geo.admin.ch

# DEFAULT_HOST=https://service-print.dev.bgdi.ch

# HOST=https://service-print.int.bgdi.ch/mom_cf_fix


HOST_FIXED=https://service-print.int.bgdi.ch/mom_cf_fix

HOST=${HOST:-${DEFAULT_HOST}}


MAPFISH_PRINT=print-standalone-2.1.3-SNAPSHOT.jar


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
    
    for dir in "pdfs/local" "pdfs/remote" "pdfs/gradle" "pdfs/fixed" logs; do
        echo "${dir}"
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
    json=$(curl -v --max-time 60  --silent --header "Content-Type:application/json; charset=UTF-8" --header "Referer: http://ouzo.geo.admin.ch" --data @specs/${specfile}.json -X POST "${HOST}/${PRINT}/create.json?url=$(urlencode ${HOST}/${PRINT})")
    
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

gradle) echo "Doing a gradle print"
    print_spec ${specfile}
    clean gradle ${specfile}
    gradle_print ${specfile}
    ;;

debug) echo "Doing a debug print"
    print_spec ${specfile}
    clean debug ${specfile}
    debug_print ${specfile}
    ;;

remote) echo "Doing a remote print"
    print_spec ${specfile}
    clean remote ${specfile}
    json=$(remote_print  ${specfile} ${HOST})
   
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo $pdf_url
   
    curl -o "pdfs/remote/${specfile}.pdf" ${pdf_url}
    ;;
fixed) echo "Doing a remote print on fixed"
    print_spec ${specfile}
    clean remote ${specfile}
    json=$(remote_print  ${specfile} ${HOST_FIXED})
   
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo $pdf_url
   
    curl -o "pdfs/fixed/${specfile}.pdf" ${pdf_url}
    ;;
   
*) echo "Unkown action. Should be one of local,remote"
   exit 2

esac








