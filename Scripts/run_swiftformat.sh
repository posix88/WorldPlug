#!/bin/sh

osascript -e "display notification \"🔬 Looking at your changes\" with title \"SwiftFormat\""

LIST_FILE=formatList.txt

#Store the project root
PROJECT_ROOT=$(git rev-parse --show-toplevel)

# Retrieve all changed files
staged=$(git diff --name-only --diff-filter=d --staged) # staged (ignore deleted)
unstaged=$(git diff --name-only --diff-filter=d) # unstaged (ignore deleted)
untracked=$(git ls-files --others --exclude-standard) # untracked

files=$(echo "$staged\n$unstaged\n$untracked" | grep ".*\.swift$" | sort | uniq)
formatter=$(echo "$staged\n$unstaged\n$untracked" | grep ".*\.swiftformat" | sort | uniq)
swiftformatconfigpath=$PROJECT_ROOT/".swiftformat"

cd  "$PROJECT_ROOT/Tools/Formatter"
if [ -z "$formatter" ] && echo "Empty"; then
    if [ -z "$files" ] && echo "Empty"; then
        osascript -e "display notification \"🤷‍♂️ No new files to format\" with title \"SwiftFormat\""
        afplay /System/Library/Sounds/Bottle.aiff
    else
        osascript -e "display notification \"🪄 Formatting your code, this may take a while...\" with title \"SwiftFormat\""
        touch $LIST_FILE

        stringBuilder=""

        SAVEIFS=$IFS   # Save current IFS (Internal Field Separator)
        IFS=$'\n'      # Change IFS to newline char
        files=($files) # split the `names` string into an array by the same name
        IFS=$SAVEIFS   # Restore original IFS

        for (( i=0; i<${#files[@]}; i++ ))
        do
            stringBuilder+="$PROJECT_ROOT/${files[$i]}"$'\n'
        done
        echo "$stringBuilder" > $LIST_FILE
        
        swift run -c release swiftformat --config "$swiftformatconfigpath" --filelist $LIST_FILE
        rm $LIST_FILE
        if [ $? -eq 0 ]; then
            osascript -e "display notification \"✅ Formatting completed\" with title \"SwiftFormat\""
            afplay /System/Library/Sounds/Purr.aiff
        else
            osascript -e "display notification \"⛔️ Formatting failed with an error, please check the formatting definition\" with title \"SwiftFormat\""
            afplay /System/Library/Sounds/Sosumi.aiff
        fi
    fi
else
    osascript -e "display notification \"♻️ Refreshing all rules, this may take a while...\" with title \"SwiftFormat\""
    swift run -c release swiftformat --config "$swiftformatconfigpath" "$PROJECT_ROOT"
    if [ $? -eq 0 ]; then
       osascript -e "display notification \"✅ Formatting completed\" with title \"SwiftFormat\""
       afplay /System/Library/Sounds/Purr.aiff 
    else
       osascript -e "display notification \"⛔️ Formatting failed with an error, please check the formatting definition\" with title \"SwiftFormat\""
       afplay /System/Library/Sounds/Sosumi.aiff 
    fi
fi
