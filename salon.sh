#! /bin/bash

PSQL="psql --username=freecodecamp --dbname=salon --tuples-only -c"

MAIN_MENU() {
  if [[ $1 ]]
  then
    echo -e "\n$1"
  fi

  # Display numbered list of services
  SERVICES=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id;")
  echo "$SERVICES" | while read SERVICE_ID BAR SERVICE_NAME
  do
    echo "$SERVICE_ID) $SERVICE_NAME"
  done

  # Prompt for service_id
  read SERVICE_ID_SELECTED

  # Check if service exists
  SERVICE_EXIST=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED;")
  
  if [[ -z $SERVICE_EXIST ]]
  then
    MAIN_MENU "I could not find that service. What would you like today?"
  else
    BOOK_APPOINTMENT $SERVICE_ID_SELECTED
  fi
}

BOOK_APPOINTMENT() {
  LOCAL_SERVICE_ID=$1

  # Prompt for phone number
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE

  # Check if customer exists
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';" | sed 's/ //g')

  # If customer doesn't exist, get name and insert into customers table
  if [[ -z $CUSTOMER_ID ]]
  then
    echo -e "\nI don't have a record for that phone number, what's your name?"
    read CUSTOMER_NAME

    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(phone, name) VALUES('$CUSTOMER_PHONE', '$CUSTOMER_NAME');")
    
    # Retrieve new customer_id
    CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone = '$CUSTOMER_PHONE';" | sed 's/ //g')
  else
    # Get existing customer's name
    CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE customer_id = $CUSTOMER_ID;" | sed 's/^[ \t]*//;s/[ \t]*$//')
  fi

  # Prompt for appointment time
  echo -e "\nWhat time would you like your appointment, $CUSTOMER_NAME?"
  read SERVICE_TIME

  # Insert appointment
  INSERT_APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments(customer_id, service_id, time) VALUES($CUSTOMER_ID, $LOCAL_SERVICE_ID, '$SERVICE_TIME');")

  # Get service name for final output message
  SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $LOCAL_SERVICE_ID;" | sed 's/^[ \t]*//;s/[ \t]*$//')

  # Final confirmation message
  echo -e "\nI have put you down for a $SERVICE_NAME at $SERVICE_TIME, $CUSTOMER_NAME."
}

MAIN_MENU