#!/bin/bash

# Fetch a random quote from an online API
QUOTE=$(curl -s https://api.quotable.io/random)

# Extract the content and author from the JSON response
CONTENT=$(echo $QUOTE | jq -r '.content')
AUTHOR=$(echo $QUOTE | jq -r '.author')

# Display the quote
echo "\"$CONTENT\" - $AUTHOR"
