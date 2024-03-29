#!/bin/bash

fetch_and_save_quote() {
    URL=$1
    CONTENT_PATH=$2
    AUTHOR_PATH=$3
    ERROR_LOG="error_log.txt"

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

    # Fetch a quote from an online API
    QUOTE=$(curl -s $URL)

    # Check if the API request was successful
    if [ $? -ne 0 ]; then
        echo "Error: Unable to fetch quote from API" | tee -a $ERROR_LOG
        exit 1
    fi

    # Check if the API returned an error
    if echo $QUOTE | jq -e .error > /dev/null 2>&1; then
        echo "Error: API returned an error - $(echo $QUOTE | jq -r '.error')" | tee -a $ERROR_LOG
        exit 1
    fi

    # Extract the content and author from the JSON response
    CONTENT_AND_AUTHOR=$(echo $QUOTE | jq -r "$CONTENT_PATH, $AUTHOR_PATH")
    CONTENT=$(echo $CONTENT_AND_AUTHOR | cut -d',' -f1)
    AUTHOR=$(echo $CONTENT_AND_AUTHOR | cut -d',' -f2)

    # Display the quote
    echo "\"$CONTENT\" - $AUTHOR"

    # Check if the file exists, if not create one
    if [ ! -f $FILE_NAME ]; then
        touch $FILE_NAME
    fi

    # Check if the quote already exists in the file
    if ! grep -Fxq "\"$CONTENT\" - $AUTHOR" $FILE_NAME
    then
        # Check if the file size exceeds 1MB
        if [ $(stat -c%s "$FILE_NAME") -gt 1048576 ]; then
            TIMESTAMP=$(date +%s)
            FILE_NAME="quotes_$TIMESTAMP.txt"
            touch $FILE_NAME
        fi

        # Save the quote to a file
        echo "\"$CONTENT\" - $AUTHOR" >> $FILE_NAME
        echo "Quote fetched and saved on $(date)" >> $FILE_NAME
    fi
}

# Specify the category
CATEGORY="inspire"

# Initialize the file name
FILE_NAME="quotes.txt"

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author'

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author'