#!/bin/bash

CONFIG_LOCATION="${1}"
NEW_IP="${2}"


source "${CONFIG_LOCATION}"
CLOUDDNS_ENDPOINT="https://dns.api.rackspacecloud.com/v1.0/${TENANT_ID}"


retrieve_token() {
    local API_USERNAME="${1}"
    local API_KEY="${2}"
    local ENDPOINT="https://identity.api.rackspacecloud.com/v2.0/tokens"

 
    read -r -d '' PAYLOAD <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<auth>
<apiKeyCredentials xmlns="http://docs.rackspace.com/identity/api/ext/RAX-KSKEY/v1.0" username="${API_USERNAME}" apiKey="${API_KEY}"/>
</auth>
EOF
    
    # Specify insecure because OpenWRT doesn't provide a CA cert bundle
    local RESPONSE=$( curl --insecure --silent "${ENDPOINT}" -H "Content-Type: application/xml" --data "${PAYLOAD}" -H "Accept: application/xml" )

    local TOKEN=$( echo "${RESPONSE}" | grep "<token" | sed 's/.*token id="\([0-z]*\)".*/\1/' )

    echo "${TOKEN}"
}

lookup_domain_id() {
    local API_TOKEN="${1}"
    local DOMAIN_NAME="${2}"
    local ENDPOINT="{$CLOUDDNS_ENDPOINT}/domains/?name=${DOMAIN_NAME}"


    local RESPONSE=$( curl --silent "${ENDPOINT}" -H "Accept: application/xml" -H "X-Auth-Token: ${API_TOKEN}" )

    echo $RESPONSE
}


search_record_id() {
    local API_TOKEN="${1}"
    local DOMAIN_ID="${2}"
    local RECORD_TYPE="${3}"
    local RECORD_NAME="${4}"
    local ENDPOINT="{$CLOUDDNS_ENDPOINT}/domains/${DOMAIN_ID}/records?type={$RECORD_TYPE}&name=${RECORD_NAME}"


    local RESPONSE=$( curl --silent "${ENDPOINT}" -H "Accept: application/xml" -H "X-Auth-Token: ${API_TOKEN}" )

    echo $RESPONSE
}


update_record() {
    local API_TOKEN="${1}"
    local DOMAIN_ID="${2}"
    local RECORD_ID="${3}"
    local RECORD_DATA="${4}"
    local ENDPOINT="{$CLOUDDNS_ENDPOINT}/domains/${DOMAIN_ID}/records/${RECORD_ID}"

    read -r -d '' PAYLOAD <<EOF
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<record data="${RECORD_DATA}" ttl="3600" xmlns:ns2="http://www.w3.org/2005/Atom" xmlns="http://docs.rackspacecloud.com/dns/api/v1.0" xmlns:ns3="http://docs.rackspacecloud.com/dns/api/management/v1.0"/>
EOF


    # Specify insecure because OpenWRT doesn't provide a CA cert bundle
    local RESPONSE=$( curl -X PUT --silent --insecure "${ENDPOINT}" -H "Content-Type: application/xml" --data "${PAYLOAD}" -H "Accept: application/xml" -H "X-Auth-Token: ${API_TOKEN}" )

    echo $RESPONSE
}

check_status() {
    local API_TOKEN="${1}"
    local ENDPOINT="${2}?showDetails=true"

    local RESPONSE=$( curl --silent "${ENDPOINT}" -H "Accept: application/xml" -H "X-Auth-Token: ${API_TOKEN}" )

    echo $RESPONSE
}



TOKEN=$( retrieve_token "${API_USERNAME}" "${API_KEY}" )
update_record "${TOKEN}" "${DOMAIN_ID}" "${RECORD_ID}" "${NEW_IP}" > /dev/null


#lookup_domain_id "${TOKEN}" "example.com"
#search_record_id "${TOKEN}" "${DOMAIN_ID}" "A" "www.example.com"
#update_record "${TOKEN}" "${DOMAIN_ID}" "${RECORD_ID}" "127.0.0.2"
#check_status "${TOKEN}" "https://dns.api.rackspacecloud.com/v1.0/831941/status/9d867a64-df76-4d51-9b63-a41"

