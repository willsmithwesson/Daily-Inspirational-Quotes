#!/bin/bash

fetch_and_save_quote() {
    URL=$1
    CONTENT_PATH=$2
    AUTHOR_PATH=$3

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
    if [ ! -f quotes.txt ]; then
        touch quotes.txt
    fi

    # Check if the quote already exists in the file
    if ! grep -Fxq "\"$CONTENT\" - $AUTHOR" quotes.txt
    then
        # Save the quote to a file
        echo "\"$CONTENT\" - $AUTHOR" >> quotes.txt
    fi
}

# Specify the category
CATEGORY="inspire"

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author'

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author'