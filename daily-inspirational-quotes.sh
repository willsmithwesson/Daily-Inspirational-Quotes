#!/bin/bash

# Specify the category
CATEGORY="inspire"

# Fetch a random quote from an online API
QUOTE=$(curl -s https://api.quotable.io/random?tags=$CATEGORY)

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
CONTENT=$(echo $QUOTE | jq -r '.content')
AUTHOR=$(echo $QUOTE | jq -r '.author')

# Display the quote
echo "\"$CONTENT\" - $AUTHOR"

# Save the quote to a file
echo "\"$CONTENT\" - $AUTHOR" >> quotes.txt
