#!/bin/bash

filename="$1"

if [[ -f "$filename" ]]; then
    while IFS= read -r line
    do
        echo "$line"
    done < "$filename"
else
    echo "Error: File does not exist."
fi

fetch_and_save_quote() {
    URL=$1
    CONTENT_PATH=$2
    AUTHOR_PATH=$3
    DIR_PATH=$4
    FILE_NAME=$5
    NUM_QUOTES=$6
    AUTHOR_NAME=$7
    ERROR_LOG="error_log.txt"
    SUCCESS_LOG="success_log.txt"
    MAX_RETRIES=3
    EMAIL="user@example.com"
    TIME_LOG="time_log.txt"

    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found" | tee -a $ERROR_LOG
        echo "Installing jq..." | tee -a $ERROR_LOG
        sudo apt-get install jq
    fi

    # Check if mailutils is installed
    if ! command -v mail &> /dev/null
    then
        echo "mail could not be found" | tee -a $ERROR_LOG
        echo "Installing mailutils..." | tee -a $ERROR_LOG
        sudo apt-get install mailutils
    fi

    # Check if internet connection is available
    if ! ping -c 1 google.com > /dev/null 2>&1; then
        echo "Error: Internet connection not available" | tee -a $ERROR_LOG
        exit 1
    fi

    # Check if the API URL is valid
    if ! curl -Is $URL | head -n 1 | grep "HTTP/1.[01] [23].." > /dev/null; then
        echo "Error: Invalid API URL" | tee -a $ERROR_LOG
        exit 1
    fi

    # Check if the directory exists, if not create one
    if [ ! -d $DIR_PATH ]; then
        mkdir -p $DIR_PATH
    fi

    FILE_PATH="$DIR_PATH/$FILE_NAME"

    for ((i=0; i<$NUM_QUOTES; i++))
    do
        for ((j=0; j<$MAX_RETRIES; j++))
        do
            # Start the timer
            START_TIME=$(date +%s)

            # Fetch a quote from an online API
            QUOTE=$(curl -s $URL)

            # Check if the API request was successful
            if [ $? -ne 0 ]; then
                echo "Error: Unable to fetch quote from API" | tee -a $ERROR_LOG
                continue
            fi

            # Check if the API returned an error
            if echo $QUOTE | jq -e .error > /dev/null 2>&1; then
                echo "Error: API returned an error - $(echo $QUOTE | jq -r '.error')" | tee -a $ERROR_LOG
                continue
            fi

            # Extract the content and author from the JSON response
            CONTENT_AND_AUTHOR=$(echo $QUOTE | jq -r "$CONTENT_PATH, $AUTHOR_PATH")
            CONTENT=$(echo $CONTENT_AND_AUTHOR | cut -d',' -f1)
            AUTHOR=$(echo $CONTENT_AND_AUTHOR | cut -d',' -f2)

            # Check if the author is empty
            if [ -z "$AUTHOR" ]; then
                AUTHOR="Unknown"
            fi

            # Check if the quote is empty
            if [ -z "$CONTENT" ]; then
                echo "Error: Quote is empty" | tee -a $ERROR_LOG
                continue
            fi

            # If an author is specified, check if the quote is from the specified author
            if [ -n "$AUTHOR_NAME" ] && [ "$AUTHOR" != "$AUTHOR_NAME" ]; then
                continue
            fi

            # Check if the quote already exists in the file before making a request to the API
            if grep -Fxq "\"$CONTENT\" - $AUTHOR" $FILE_PATH
            then
                echo "Quote already exists in the file. Skipping..." | tee -a $SUCCESS_LOG
                continue
            fi

            # Display the quote
            echo "\"$CONTENT\" - $AUTHOR"

            # Check if the file exists, if not create one
            if [ ! -f $FILE_PATH ]; then
                touch $FILE_PATH
            fi

            # Check if the file size exceeds 1MB
            if [ $(stat -c%s "$FILE_PATH") -gt 1048576 ]; then
                TIMESTAMP=$(date +%s)
                FILE_PATH="$DIR_PATH/quotes_$TIMESTAMP.txt"
                touch $FILE_PATH
            fi

            # Save the quote to a file
            echo "\"$CONTENT\" - $AUTHOR" >> $FILE_PATH
            echo "Quote fetched and saved on $(date)" >> $FILE_PATH
            echo "Quote fetched and saved on $(date)" >> $SUCCESS_LOG

            # Send an email notification
            echo "Quote fetched and saved on $(date)" | mail -s "Quote Saved" $EMAIL

            # Stop the timer and log the time taken
            END_TIME=$(date +%s)
            TIME_TAKEN=$((END_TIME - START_TIME))
            echo "Time taken to fetch and save quote: $TIME_TAKEN seconds" >> $TIME_LOG

            # If we reach this point, the quote was successfully fetched and saved, so break the retry loop
            break
        done
    done
}

# Specify the directory
DIR_PATH=${1:-"./quotes"}

# Specify the category
CATEGORY=${2:-"inspire"}

# Specify the file name
FILE_NAME=${3:-"quotes.txt"}

# Specify the number of quotes
NUM_QUOTES=${4:-1}

# Specify the author
AUTHOR_NAME=${5}

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author' $DIR_PATH $FILE_NAME $NUM_QUOTES $AUTHOR_NAME

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author' $DIR_PATH $FILE_NAME $NUM_QUOTES $AUTHOR_NAME