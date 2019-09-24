#!/bin/sh
set -e
value_by_name()
{
 # Set params we are looking for
 params=$1
 shift
 while [[ $# -gt 0 ]]; do
  if [ ! -z $(echo $1 | grep "=") ]; then
   if [ "$params" == "$(echo $1 | cut -d= -f1)" ]; then
      echo "$(echo $1 | cut -d= -f2 | sed 's/\"//g' )"
   fi
  fi
  shift
 done
}

update_webhook()
{
 # GITHUB API: https://developer.github.com/v3/repos/hooks/
 # LIST HOOKS: GET https://$CREDENTIALS@api.github.com/repos/$ORG/$REPO/hooks
 # GET HOOK DETAILS: GET https://$CREDENTIALS@api.github.com/repos/$ORG/$REPO/hooks/$HOOKID
 # UPDATE HOOK: PATCH https://$CREDENTIALS@api.github.com/repos/$ORG/$REPO/hooks/$HOOKID?config='{json data here}'
 # CREATE NEW HOOK: POST https://$CREDENTIALS@api.github.com/repos/$ORG/$REPO/hooks?config='{json data here}'
 read INP 
 # AUTH=$(cat /etc/credentials) 
 AUTH=$AUTH
 ORG=$ORG
 JQ=jq
 CURL=curl
 BASE="api.github.com/repos"
 REPO=$(value_by_name "name" $INP)
 URL=$(value_by_name "url" $INP)
 if [[ -z $REPO || -z $URL ]]; then
   echo "Error parsing NGROK output"
   exit 1
 fi
 echo "REPO: $REPO, URL: $URL"
 HOOKS=$($CURL -s -X GET "https://$AUTH@$BASE/$ORG/$REPO/hooks" )
 if [ $(expr match $(echo "$HOOKS"|$JQ type) '"array"') ]; then
  HOOKS=$(echo $HOOKS | $JQ -r '.[]|(.id|tostring)+" "+.config.url+" "+(.last_response.code|tostring)')
  echo "$HOOKS"
 else
  echo "$HOOKS"
  exit 1
 fi
 MYHOOK=$(echo "$HOOKS" | while read hook; do if [ $(expr match "$hook" $URL) ]; then echo "$hook"; fi; done)
 echo "MYHOOK: $MYHOOK"
 # We do not have it configured
 if [[ -z $MYHOOK ]]; then
   HOOKID=$(echo "$HOOKS" | while read hook; do if [[ ! -z $(echo $hook | grep -v 200) ]]; then  echo $hook | cut -d" " -f1; fi; done | head -1)
   echo "$HOOKID"
   RET=
   DATA="{\"active\": true, \"config\":{\"url\":\"$URL/github-webhook/\"}}"
   if [[ ! -z $HOOKID ]]; then
     RET=$($CURL -s -X PATCH https://$AUTH@$BASE/$ORG/$REPO/hooks/$HOOKID --data "$DATA")
   else
     RET=$($CURL -s -X POST https://$AUTH@$BASE/$ORG/$REPO/hooks --data "$DATA")
   fi
   if [[ $(echo "$RET" | $JQ .message) == null ]]; then
     echo "Hook was created/updated"
   else
     echo "$RET"
   fi
 else
   echo "Hook with this url($URL) already exists"
 fi
}

#read PARAMS
exec $@ | grep 'started tunnel' | update_webhook
