#!/bin/bash

fetch_and_save_quote() {
    URL=$1
    CONTENT_PATH=$2
    AUTHOR_PATH=$3
    FILE_NAME=$4

    # Check if jq is installed
    if ! command -v jq &> /dev/null
    then
        echo "jq could not be found"
        echo "Installing jq..."
        sudo apt-get install jq
    fi

    # Check if internet connection is available
    if ! ping -c 1 google.com > /dev/null 2>&1; then
        echo "Error: Internet connection not available"
        exit 1
    fi

    # Fetch a quote from an online API
    QUOTE=$(curl -s $URL)

    # Check if the API request was successful
    if [ $? -ne 0 ]; then
        echo "Error: Unable to fetch quote from API"
        exit 1
    fi

    # Check if the API returned an error
    if echo $QUOTE | jq -e .error > /dev/null 2>&1; then
        echo "Error: API returned an error - $(echo $QUOTE | jq -r '.error')"
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
        # Save the quote to a file
        echo "\"$CONTENT\" - $AUTHOR" >> $FILE_NAME
    fi
}

# Specify the category
CATEGORY="inspire"

# Check if the file size exceeds 1MB
if [ $(stat -c%s "quotes.txt") -gt 1048576 ]; then
    TIMESTAMP=$(date +%s)
    FILE_NAME="quotes_$TIMESTAMP.txt"
else
    FILE_NAME="quotes.txt"
fi

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author' $FILE_NAME

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author' $FILE_NAME