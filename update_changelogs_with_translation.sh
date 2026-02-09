#!/bin/bash

# Update changelogs with automatic translation via OpenAI API.
# Usage: ./update_changelogs_with_translation.sh "version" "english_changelog_entry"
# Requires OPENAI_API_TOKEN in .env file.

set -a
source .env
set +a

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 version english_changelog_entry"
    echo "Example: $0 0.1.0 '- Initial release'"
    exit 1
fi

VERSION=$1
ENGLISH_CHANGELOG=$2

# Convert semantic version to version code if needed
if [[ $VERSION == *.* ]]; then
    IFS='.' read -ra VERSION_PARTS <<< "$VERSION"
    MAJOR=${VERSION_PARTS[0]}
    MINOR=${VERSION_PARTS[1]}
    PATCH=${VERSION_PARTS[2]}
    VERSION_CODE=$((MAJOR * 10000 + MINOR * 100 + PATCH))
else
    VERSION_CODE=$VERSION
fi

# Create English changelog
mkdir -p fastlane/metadata/android/en-US/changelogs
ENGLISH_FILE="fastlane/metadata/android/en-US/changelogs/$VERSION_CODE.txt"
echo -e "$ENGLISH_CHANGELOG" > "$ENGLISH_FILE"
echo "Created English changelog: $ENGLISH_FILE"

# Language mappings
declare -A LANGUAGE_CODES=(
    ["de-DE"]="de"
    ["es-ES"]="es"
    ["fr-FR"]="fr"
    ["it-IT"]="it"
)

translate_text() {
    local text="$1"
    local target_lang="$2"

    curl -s -X POST "https://api.openai.com/v1/chat/completions" \
    -H "Authorization: Bearer $OPENAI_API_TOKEN" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"gpt-4.1-mini\",
        \"messages\": [
        {\"role\": \"system\", \"content\": \"You are a professional translator. Translate the given text to $target_lang. Return ONLY the translation, nothing else. The hard limit is 500 characters. No trailing empty newlines.\"},
        {\"role\": \"user\", \"content\": \"$text\"}
        ]
    }" | jq -r '.choices[0].message.content'
}

for LANG in "${!LANGUAGE_CODES[@]}"; do
    TARGET_LANG=${LANGUAGE_CODES[$LANG]}
    mkdir -p "fastlane/metadata/android/$LANG/changelogs"

    TRANSLATED_CHANGELOG=""
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            translated_line=$(translate_text "$line" "$TARGET_LANG")
            TRANSLATED_CHANGELOG+="$translated_line\n"
        fi
    done <<< "$ENGLISH_CHANGELOG"

    TRANSLATED_FILE="fastlane/metadata/android/$LANG/changelogs/$VERSION_CODE.txt"
    echo -en "$TRANSLATED_CHANGELOG" > "$TRANSLATED_FILE"
    echo "Created $LANG changelog: $TRANSLATED_FILE"
done

echo "Changelogs created for version $VERSION (code: $VERSION_CODE) across all languages"
