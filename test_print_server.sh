#!/bin/bash

_V=0

ME=$(basename "$0")

DEFAULT_BASEURL=https://print.geo.admin.ch
DEFAULT_TOMCAT_URL=http://localhost:8011
DEFAULT_MAPFISH_LIBS=$HOME/mapfish-print/build/libs

# DEFAULT_BASEURL=https://service-print.dev.bgdi.ch

# BASEURL=https://service-print.int.bgdi.ch/mom_cf_fix


BASEURL_FIXED=https://service-print.int.bgdi.ch/mom_cf_fix
DEFAULT_CURL_OPTS=""
DOWNLOAD_PDF=${DOWNLOAD_PDF:-1}

BASEURL=${BASEURL:-${DEFAULT_BASEURL}}

DEFAULT_HOST=$(echo ${BASEURL} | sed -e "s/[^/]*\/\/\([^@]*@\)\?\([^:/]*\).*/\2/")

HOST=${HOST:-${DEFAULT_HOST}}

TOMCAT_URL=${TOMCAT_URL:-${DEFAULT_TOMCAT_URL}}
YAML_CONFIG=$HOME/service-print/tomcat/config.yaml

MAPFISH_PRINT=print-standalone-2.1.3-SNAPSHOT.jar
MAPFISH_LIBS=${MAPFISH_LIBS:-${DEFAULT_MAPFISH_LIBS}}
CURL_OPTS=${CURL_OPTS:-${DEFAULT_CURL_OPTS}}
DEBUG=${DEBUG:-0}


PRINT=printmulti
PRINT=print
#PRINT=pdf  # for tomcat

if [[ ${DEBUG} -eq 1 ]]; then
    CURL_OPTS=" -v ${CURL_OPTS} "
fi


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
    cat <<-EOF

    Testing a spec file against the mapfish print v2 server
    
    Synopsis:
    
      Printing with MapFish Print v2 is really only sending a specification file (found in then
      *specs* directory, to the print server, via *HTTP POST* or using the local *.jar*file.
      
      The *remote* print
      
      Send the *spec*file to the print server via HTTP POST. The server may run either locally via
      a *docker-compose up -d* or remotely on an *EC2*or *kubernetes* cluster.
      
      The basic worklflow to edit the *config.yaml* will be, in the *geoadmin/service-print* github project:
      
      *tomcat/config.yaml* && make printwar dockerbuild dockerrun
      
      and in this repository:
      
      export BASEURL=8009 && $(ME) remote lv95_simple
      
      The *local* print (*gradle* and *tomcat* are almost the same)
      
      Invoke the ${MAPFISH_LIBS}/${MAPFISH_PRINT} java .jar directly (the **standalone** version of the .jar,
      not the servlet one!). You must have a functionning java installation (an older one)
      
      Only useful when coding to the _mapfish-print_ java code!
    
    
    
    Usage:
    
      ${ME} <local|gradle|tomcat|remote> <spec file>
    
      Option for <remote>
        Print server url                              BASEURL=${BASEURL}
                                                      (default to ${DEFAULT_BASEURL})
        Print host                                    HOST=${HOST}
        Options for curl                              CURL_OPTS=${CURL_OPTS}
        Download the PDF (0/1)                        DOWNLOAD_PDF=${DOWNLOAD_PDF} 
        Be verbose                                    DEBUG=${DEBUG}
        Single print or multiprint (debug)            PRINT=${PRINT}
        
      Options for <local> and <gradle>
        Name of the **standalone** mapfish jar file   MAPFISH_PRINT=${MAPFISH_PRINT}
        Path to dir where Mapfish Print v2 store
        its war and jar build (local machine)         MAPFISH_LIBS=${MAPFISH_LIBS}
        Print config (only used by local and
        gradle print)                                 YAML_CONFIG=${YAML_CONFIG}
    
    Examples:
    
      Using a printerver (docker)
        
           test_print_server.sh remote lv95_simple
    
      Available spec files (in 'specs' directory), use the `lv95_` :
    
          ./test_print_server.sh list

EOF

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
        echo "Cannot find the spec file: ${specfile}"
        exit 4
    fi
}
function debug_print() {
    local specfile=$1
    # For SSL issues
    JAVA_OPTS=" -Djdk.tls.client.protocols=TLSv1.1,TLSv1.2 -Dhttps.protocols=TLSv1.1,TLSv1.2 -Ddeployment.security.SSLv2Hello=false -Ddeployment.security.SSLv3=false -Ddeployment.security.TLSv1=false -Ddeployment.security.TLSv1.1=true -Ddeployment.security.TLSv1.2=true -Djava.awt.headless=true  -Djavax.net.debug=ssl:handshake:verbose"
    # For general problems
    JAVA_OPTS=" -Djavax.net.debug=all "

    java ${JAVA_OPTS} -Djava.awt.headless=true   -cp ${MAPFISH_LIBS}/${MAPFISH_PRINT}   org.mapfish.print.ShellMapPrinter --config=${YAML_CONFIG} --spec=specs/${specfile}.json  --output=pdfs/debug/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?
    
    return $print_return_code
}

function local_print() {
    local specfile=$1
    
    java -Djava.awt.headless=true  -cp ${MAPFISH_LIBS}/${MAPFISH_PRINT}  org.mapfish.print.ShellMapPrinter --config=${YAML_CONFIG} --spec=specs/${specfile}.json  --output=pdfs/local/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?
    
    return $print_return_code
}

function gradle_print() {
    local specfile=$1
    
    cd ../mapfish-print
     ./gradlew run  -Dconfig=${YAML_CONFIG} -Dspec=specs/${specfile}.json  -Doutput=pdfs/gradle/${specfile}.pdf | tee logs/${specfile}.log

    print_return_code=$?

    cd -
    
    return $print_return_code
}

function remote_print() {
    local specfile=$1
    local url=$2
    local json
    local fullpath_specfile="specs/${specfile}.json"
    


    #json=$(curl -v --max-time 60  --silent --header "Content-Type:application/json; charset=UTF-8" --header "Referer: http://ouzo.geo.admin.ch" --data @specs/${specfile}.json -X POST "${BASEURL}/${PRINT}/create.json?url=$(urlencode ${BASEURL}/${PRINT})")
    json=$(curl ${CURL_OPTS} --max-time 60  --silent --header "Content-Type: application/json; charset=UTF-8" \
           --header "Referer: https://map.geo.admin.ch" --header "User-Agent: Zorba is debugging the print server"  \
           --header "Host: ${HOST}" --data @specs/${specfile}.json \
           -X POST "${url}/create.json?url=$(urlencode ${url})")
    
    echo ${json}

}


function check_yaml() {
    if [ ! -f "$HOME/service-print/tomcat/config.yaml" ]; then
        echo "No file $HOME/service-print/tomcat/config.yaml found"
        echo "Please git clone git@github.com:geoadmin/service-print.git"
        exit 2
    fi

    if [ ! -f "${MAPFISH_LIBS}/${MAPFISH_PRINT}" ]; then
        echo "No file ${MAPFISH_LIBS}/${MAPFISH_PRINT} found!"
        echo "Please install and compile git@github.com:geoadmin/mapfish-print.git"
        exit 2
    fi 
}

function preflight() {
    local action=$1
    local specfile=$2

    
    spec=$(print_spec ${specfile})
    log $spec
    clean ${action} ${specfile}

}


if [ "$1" == "list" ]; then
    action=$1
elif (( $# < 2 )); then
    usage
    exit 1
else
  action=$1
  specfile=$2
  init
fi

case "${action}" in

list)
    json_files
    ;;

local) echo "Doing a local print"

    check_yaml
    preflight local ${specfile}
    local_print ${specfile}
    ;;

gradle) echo "Doing a gradle print"

    check_yaml
    preflight gradle ${specfile}
    gradle_print ${specfile}
    ;;

debug) echo "Doing a debug print"
    
    check_yaml
    preflight debug ${specfile}
    debug_print ${specfile}
    ;;

tomcat)
    tomcat_url=${TOMCAT_URL}/service-print-main/pdf
    echo "Doing a local print on tomcat ${tomcat_url} (not for multiprint)"

    preflight remote ${specfile}
    json=$(remote_print  ${specfile} ${tomcat_url})
   
    pdf_url=$(echo ${json} | jq -r '.getURL')
   
    echo $pdf_url
    sleep 0.5
   
    curl -o "pdfs/tomcat/${specfile}.pdf" ${pdf_url}
    echo "Saved to pdfs/tomcat/${specfile}.pdf"
    ;;

remote) echo "Printing ${specfile} to remote on ${BASEURL}"
    
    start=$(date +%s%N)

    preflight remote ${specfile}
    fullpath_specfile="specs/${specfile}.json"
    if [ ! -f "${fullpath_specfile}" ]; then
        echo "Specfile ${fullpath_specfile} not found"
        json_files
        exit 3
    fi
    

     
    movie=$(cat specs/${specfile}.json  | jq '.movie')
    
    if [ "${movie}" == "true" ]; then
       echo "Multiprint mode" | ts '[%Y-%m-%d %H:%M:%S]'
       PRINT=printmulti
    else
      PRINT=print
      echo "Singleprint mode" | ts '[%Y-%m-%d %H:%M:%S]'
    fi
    # Multiprint
    if [ "${movie}" == "true" ]; then
     
        done="ongoing"
        merged='0'
        merging=${start}
     
        #{"idToCheck":"1711102228415808"}
      
        first=$(remote_print  ${specfile} ${BASEURL}/${PRINT})
      
        #  {"status":"done","getURL":"https://service-print.prod.bgdi.ch/print/-multi1711102035267851.pdf.printout","written":109884753}
     
        idToCheck=$(echo ${first} | jq -r '.idToCheck')
        echo "idToCheck=$idToCheck"
     
        # {"status":"ongoing","total":23,"done":0}
     
        while [[ "${status}" != "done" ]]; 
           do sleep 5; 
           json=$(curl -s  "${BASEURL}/printprogress?id=$idToCheck")
           echo $json | ts '[%Y-%m-%d %H:%M:%S]'
           status=$(echo $json | jq -r '.status')
           merged=$(echo $json | jq -r '.merged')
           total=$(echo $json | jq -r '.total')
           # echo ${merged} ${total} ${merging}
           # DEBUG echo "waiting  $json $status" [[ "${status}" != "done" ]]  && echo not-equal || echo equal
            [[ "${merged}" != "${total}" ]] &&  merging=$(date +%s%N) 
        
       done

    # simple
    else
        json=$(remote_print  ${specfile} ${BASEURL}/${PRINT})
    fi
    
    # Get the PDF 
    pdf_url=$(echo ${json} | jq -r '.getURL')
    echo ${json}   
    echo "#### $pdf_url ####"
    
    elapsed=$(echo "scale=3; ($(date +%s%N) - $start) / 1000000000.0" | bc)
    
    if [ "${movie}" == "true" ]; then
    
      merged=$(echo "scale=3; ($(date +%s%N) - $merging) / 1000000000.0" | bc)
      echo "Generation: ${elapsed} (s) (merging: ${merged})" 
    
    else
    
    echo "Generation (s): ${elapsed}" | ts '[%Y-%m-%d %H:%M:%S]'
    
    
    fi
    
 

    if [[ ${DOWNLOAD_PDF} -eq 1 ]]; then
      sleep 2
    
      echo "Dowloading.."
    
      #pdf_file="pdfs/remote/${specfile}.${RANDOM}.pdf"
      pdf_file="pdfs/remote/${specfile}.pdf"
   
      curl -s -o ${pdf_file} ${pdf_url}
    
      echo "Dowloaded to: ${pdf_file}"   | ts '[%Y-%m-%d %H:%M:%S]'
      echo "Testing if file is a PDF: $(file ${pdf_file})"
    else
    echo "File not downloaded"  | ts '[%Y-%m-%d %H:%M:%S]'
      
    fi
    echo "Done"
    #echo $PRINT
    #rm -f ${pdf_file}
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








