#!/bin/bash

# Define the output CSV file
OUTPUT_FILE="file_sizes.csv"

# Define artifact paths and their corresponding program names
declare -A PROGRAM_MAP=(
    ["$HOME/Documents/MasterThesis_ExperimentReady/real_world_programs/coreNLP/artifacts"]="CoreNLP"
    ["$HOME/Documents/MasterThesis_ExperimentReady/real_world_programs/icij-extract/artifacts"]="ExtractCLI"
    ["$HOME/Documents/MasterThesis_ExperimentReady/real_world_programs/error-prone/artifacts"]="ErrorProne"
    ["$HOME/Documents/MasterThesis_ExperimentReady/real_world_programs/checkstyle/artifacts"]="Checkstyle"
    ["$HOME/Documents/MasterThesis_ExperimentReady/real_world_programs/tika/artifacts"]="ApacheTika"
)

# Write CSV header
echo "ID,Size (bytes)" > "$OUTPUT_FILE"

# Iterate over each artifact directory
for ARTIFACT_DIR in "${!PROGRAM_MAP[@]}"; do
    PROGRAM_NAME=${PROGRAM_MAP[$ARTIFACT_DIR]}

    if [ -d "$ARTIFACT_DIR" ]; then
        # Check jlink-runtime directory size
        if [ -d "$ARTIFACT_DIR/jlink-runtime" ]; then
            SIZE=$(du -sb "$ARTIFACT_DIR/jlink-runtime" | awk '{print $1}')
            echo "$PROGRAM_NAME,jlink,$SIZE" >> "$OUTPUT_FILE"
        fi

        # Check specified JAR files and extract ID
        for JAR_FILE in "$ARTIFACT_DIR"/artifact_*.jar; do
            if [ -f "$JAR_FILE" ]; then
                FILE_NAME=$(basename "$JAR_FILE")
                ID=${FILE_NAME#artifact_}  # Remove "artifact_"
                ID=${ID%.jar}  # Remove ".jar"
                SIZE=$(stat --format="%s" "$JAR_FILE")
                echo "$PROGRAM_NAME,$ID,$SIZE" >> "$OUTPUT_FILE"
            fi
        done
    else
        echo "Directory does not exist: $ARTIFACT_DIR"
    fi
done

echo "File sizes exported to $OUTPUT_FILE"
