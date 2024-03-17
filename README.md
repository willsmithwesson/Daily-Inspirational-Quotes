# README

## Overview

This bash script fetches random inspirational quotes from two different online APIs and displays them in the terminal. It also saves these quotes to a text file for future reference.

## How to Run

To run this script, follow these steps:

1. Ensure you have `curl` and `jq` installed on your system. If not, you can install them using the following commands:

    ```
    sudo apt-get update
    sudo apt-get install curl jq
    ```

2. Make the script executable:

    ```
    chmod +x script_name.sh
    ```

3. Run the script:

    ```
    ./script_name.sh
    ```

Replace `script_name.sh` with the actual name of the script.

## What the Script Does

1. The script first specifies the category of the quote as "inspire".

2. It then fetches a random quote from the Quotable API.

3. The script checks if the API request was successful. If not, it displays an error message and exits.

4. If the API request was successful, the script checks if the API returned an error. If so, it displays the error message and exits.

5. If there were no errors, the script extracts the content and author from the JSON response and displays the quote.

6. The quote is then saved to a file named `quotes.txt`.

7. The script repeats the above steps for the They Said So API to fetch the quote of the day.

## Error Handling

The script includes error handling for unsuccessful API requests and for errors returned by the API. If an error occurs, the script will display an error message and exit.

## Dependencies

This script requires `curl` to make the API requests and `jq` to parse the JSON responses.
