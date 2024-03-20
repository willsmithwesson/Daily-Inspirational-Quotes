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

    # Save the quote to a file
    echo "\"$CONTENT\" - $AUTHOR" >> quotes.txt
}

# Specify the category
CATEGORY="inspire"

# Fetch and save a random quote
fetch_and_save_quote "https://api.quotable.io/random?tags=$CATEGORY" '.content' '.author'

# Fetch and save quote of the day
fetch_and_save_quote "https://api.theysaidso.com/qod.json" '.contents.quotes[0].quote' '.contents.quotes[0].author'