# shellcheck shell=sh

## Download Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

## Install Bicep CLI
if [ "$BICEP_VERSION" != 'latest' ]; then
    az bicep install -v "$BICEP_VERSION"
else
    az bicep install
fi

# Now either run the full analysis or files changed based on the settings defined
if [ "$ANALYSE_ALL_FILES" == 'true' ]; then
    while read -r file; do
        az bicep build --file "$file" 2>> errors.txt
    done <<< "$(find . -type f -name '*.bicep')"
else
    if [ "$ACTION_EVENT_NAME" == 'pull_request' ]; then
        while read -r file; do
            az bicep build --file "$file" 2>> errors.txt
        done <<< "$(git diff --name-only --diff-filter=d origin/"$CURRENT_CODE"..origin/"${CHANGED_CODE#"refs/heads/"}")"
    else
        while read -r file; do
            az bicep build --file "$file" 2>> errors.txt
        done <<< "$(git diff --name-only --diff-filter=d "$CURRENT_CODE".."$CHANGED_CODE")"
    fi
fi

## Clean empty lines
sed -i '/^[[:blank:]]*$/ d' errors.txt

## Clean the notifications that a linter configuration was found
sed -i '/Linter Configuration/d' errors.txt

## Loop through each line identified in linter and set a GitHub message
while read -r message; do
    SEVERITY="$(echo "$message" | grep -E ' Info | Warning | Error ' -o | sed 's/ //g')"
    FILENAME="$(sed "s#.*$WORKSPACE\([^(]*\).*#\1#" <<<"$message")"
    LINE="$(sed "s#.*(\([^,]*\).*#\1#" <<<"$message")"
    COLUMN="$(sed "s#.*,\([^)]*\).*#\1#" <<<"$message")"
    REMOVE_TITLE_START="${message#* : }"
    REMOVE_TITLE_END="${REMOVE_TITLE_START%%: *}"
    TITLE="${REMOVE_TITLE_END#*"$SEVERITY"}"
    MESSAGE="${message##*: }"

    ## Sets GitHub Notifications based on severity set
    if [ "$SEVERITY" == 'Info' ]; then
        echo "::notice file=$FILENAME,line=$LINE,col=$COLUMN,title=$TITLE::$MESSAGE"
    elif [ "$SEVERITY" == 'Error' ]; then
        echo "::error file=$FILENAME,line=$LINE,col=$COLUMN,title=$TITLE::$MESSAGE"
    else
        echo "::warning file=$FILENAME,line=$LINE,col=$COLUMN,title=$TITLE::$MESSAGE"
    fi
done < errors.txt