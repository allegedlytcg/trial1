#!/bin/bash

# Validate input arguments
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 '<dir_list>' '<new_version>' '<string_literal>' '<branch_name>'"
    exit 1
fi

DIR_LIST=$1      # First parameter: list of directory names
NEW_VERSION=$2   # Second parameter: new version to replace
STRING_LITERAL=$3 # Third parameter: string literal to search for
BRANCH_NAME=$4   # Fourth parameter: branch name to use in git commands

# Loop through the directories provided in DIR_LIST
for DIR in ${DIR_LIST}; do
    if [ -d "$DIR" ]; then
        # Navigate to the directory
        cd "$DIR" || continue

        echo "Processing directory: $DIR"

        # Perform git checkout and pull commands
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "Executing 'git checkout $BRANCH_NAME' and 'git pull origin $BRANCH_NAME'..."
            git checkout "$BRANCH_NAME" && git pull origin "$BRANCH_NAME"
        else
            echo "Directory $DIR is not a Git repository."
            cd - >/dev/null || exit
            continue
        fi

        # Find the first POM file in the directory recursively
        POM_FILE=$(find . -type f -name "pom.xml" | head -n 1)
        if [ -n "$POM_FILE" ]; then
            echo "Editing file: $POM_FILE in directory: $DIR"

            # Check if the STRING_LITERAL exists anywhere in the file
            if grep -q "$STRING_LITERAL" "$POM_FILE"; then
                echo "Found string literal '$STRING_LITERAL' in $POM_FILE. Updating version."

                # Use sed to find the next <version> tag after STRING_LITERAL and replace its content with the new version
                sed -i -E "/$STRING_LITERAL/,/<version>/ { /<version>/ { s|<version>.*</version>|<version>$NEW_VERSION</version>| } }" "$POM_FILE"

                # Perform git add, commit, and push
                echo "Saving changes to Git..."
                git add "$POM_FILE" && \
                git commit -m "Updated version to '$NEW_VERSION' after finding '$STRING_LITERAL'" && \
                git push origin "$BRANCH_NAME"
            else
                echo "String literal '$STRING_LITERAL' not found in $POM_FILE."
            fi
        else
            echo "No POM file found in directory: $DIR"
        fi

        # Navigate back to the initial directory
        cd - >/dev/null || exit
    else
        echo "Directory $DIR does not exist."
    fi
done
