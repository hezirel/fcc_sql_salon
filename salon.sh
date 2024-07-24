#!/bin/bash

local SERVICE_ID_SELECTED
local CUSTOMER_PHONE
local CUSTOMER_NAME
local SERVICE_TIME

# Make a function to call psql with the correct parameters
function run_psql {
  psql --username=freecodecamp --dbname=salon -c "$1"
}

function add_service {
    run_psql "INSERT INTO services (name) VALUES ('$1');"
}

function add_customer {
    run_psql "INSERT INTO customers (phone, name) VALUES ('$1', '$2');"
}

function add_appointment {
    run_psql "INSERT INTO appointments (customer_id, service_id, time) VALUES ((SELECT customer_id FROM customers WHERE phone='$1'), $2, '$3');"
}

function get_customer_by_phone {
    run_psql "SELECT * FROM customers WHERE phone='$1';"
}

function get_services {
    run_psql "SELECT * FROM services;"
}

function display_services {
    local services=$(get_services)
    local services_idx_array=()
    local services_names_array=()

    while IFS=$'|' read -r id name; do
        services_idx_array+=($id)
        services_names_array+=($name)
        echo "$id) $name"
    done <<< "$(echo "$services" | tail -n +3 | head -n -1 | tr -d ' ')"
}

function list_services {
    local services=$(get_services)
    local services_idx_array=()
    local services_names_array=()
    while IFS=$'|' read -r id name; do
        services_idx_array+=($id)
        services_names_array+=($name)
        echo "$id) $name"
    done <<< "$(echo "$services" | tail -n +3 | head -n -1 | tr -d ' ')"

    local valid=false
    while [ "$valid" = false ]; do
        read SERVICE_ID_SELECTED
        SERVICE_ID_SELECTED=($SERVICE_ID_SELECTED - 1)
        if [[ " ${services_idx_array[@]} " =~ " ${SERVICE_ID_SELECTED} " ]]; then
            valid=true
        else
            display_services
        fi
    done

    echo $SERVICE_ID_SELECTED
    read CUSTOMER_PHONE
    existing_customer=$(get_customer_by_phone $CUSTOMER_PHONE | tail -n +3 | head -n -1 | tr -d ' ')
    echo $existing_customer
    while IFS=$'|' read -r id phone name; do
        if [ "$phone" = "$CUSTOMER_PHONE" ]; then
            CUSTOMER_NAME=$name
        fi
    done <<< "$existing_customer"
    if [ -z "$CUSTOMER_NAME" ]; then
        read CUSTOMER_NAME
        add_customer $CUSTOMER_PHONE $CUSTOMER_NAME
    fi
    read SERVICE_TIME
    add_appointment $CUSTOMER_PHONE $SERVICE_ID_SELECTED $SERVICE_TIME
    echo "I have put you down for a ${services_names_array[$SERVICE_ID_SELECTED-1]} at $SERVICE_TIME, $CUSTOMER_NAME."
}

if [ "$1" = "add_service" ]; then
  add_service "$2"
elif [ "$1" = "list_services" ]; then
    list_services
else
    list_services
fi

