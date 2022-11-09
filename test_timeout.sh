#!/bin/bash

# To test https://jira.swisstopo.ch/browse/BGDIINF_SB-2584
# Long requests


PRINT_SERVER=http://localhost:8009
PRINT_SERVER=https://print.geo.admin.ch

curl "${PRINT_SERVER}/print/create.json?url=https%3A%2F%2Fprint.geo.admin.ch%2Fprint%2Fcreate.json" \
  -H 'authority: print.geo.admin.ch' \
  -H 'accept: application/json, text/plain, */*' \
  -H 'accept-language: en-US,en;q=0.8' \
  -H 'content-type: application/json;charset=UTF-8' \
  -H 'origin: https://map.geo.admin.ch' \
  -H 'referer: https://map.geo.admin.ch/' \
  -H 'sec-fetch-dest: empty' \
  -H 'sec-fetch-mode: cors' \
  -H 'sec-fetch-site: same-site' \
  -H 'sec-gpc: 1' \
  -H 'user-agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36' \
 --data "@specs/lv95_A3_many_layers_timesout_formatted.json"\
   --compressed


  #
