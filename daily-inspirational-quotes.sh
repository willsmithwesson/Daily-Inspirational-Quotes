#!/bin/bash

fetch_and_save_quote() {
    URL=$1
    CONTENT_PATH=$2
    AUTHOR_PATH=$3
    FILE_NAME=$4
    NUM_QUOTES=$5
    AUTHOR_NAME=$6
    ERROR_LOG="error_log.txt"
    SUCCESS_LOG="success_log.txt"
    MAX_RETRIES=3

    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found" | tee -a $ERROR_LOG
        echo "Installing jq..." | tee -a $ERROR_LOG
        sudo apt-get install jq
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

    for ((i=0; i<$NUM_QUOTES; i++))
    do
        for ((j=0; j<$MAX_RETRIES; j++))
        do
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

            # Check if the API is rate-limited
            if echo $QUOTE | jq -e .rateLimit > /dev/null 2>&1; then
                RATE_LIMIT=$(echo $QUOTE | jq -r '.rateLimit')
                echo "API is rate-limited. Waiting for $RATE_LIMIT seconds before next request..." | tee -a $SUCCESS_LOG
                sleep $RATE_LIMIT
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
            if grep -Fxq "\"$CONTENT\" - $AUTHOR" $FILE_NAME
            then
                echo "Quote already exists in the file. Skipping..." | tee -a $SUCCESS_LOG
                continue
            fi

            # Display the quote
            echo "\"$CONTENT\" - $AUTHOR"

            # Check if the file exists, if not create one
            if [ ! -f $FILE_NAME ]; then
                touch $FILE_NAME
            fi

            # Check if the file size exceeds 1MB
            if [ $(stat -c%s "$FILE_NAME") -gt 1048576 ]; then
                TIMESTAMP=$(date +%s)
                FILE_NAME="quotes_$TIMESTAMP.txt"
                touch $FILE_NAME
            fi

            # Save the quote to a file
            echo "\"$CONTENT\" - $AUTHOR" >> $FILE_NAME
            echo "Quote fetched and saved on $(date)" >> $FILE_NAME
            echo "Quote fetched and saved on $(date)" >> $SUCCESS_LOG

            # If we reach this point, the quote was successfully fetched and saved, so break the retry loop
            break
        done
    done
}

# Specify the category
CATEGORY=${1:-"inspire"}

# Specify the file name
FILE_NAME=${2:-"quotes.txt"}

# Specify the number of quotes
NUM_QUOTES=${3:-1}

# Specify the author
AUTHOR_NAME=${4}

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author' $FILE_NAME $NUM_QUOTES $AUTHOR_NAME

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author' $FILE_NAME $NUM_QUOTES $AUTHOR_NAME
