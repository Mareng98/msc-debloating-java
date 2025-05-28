#!/bin/bash

# Define the output CSV file
OUTPUT_FILE="file_sizes.csv"

# Base directory for benchmarks
BENCHMARKS_DIR="$HOME/Documents/MasterThesis_ExperimentReady/benchmarks"

# Write CSV header
echo "ID,Variant,Size (bytes)" > "$OUTPUT_FILE"

# Iterate over each benchmark's artifacts directory
find "$BENCHMARKS_DIR" -type d -path "*/artifacts" | while read -r ARTIFACT_DIR; do
    # Get the program/benchmark name from the parent directory of artifacts
    PROGRAM_NAME=$(basename "$(dirname "$ARTIFACT_DIR")")

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
            ID=${ID%.jar}              # Remove ".jar"
            SIZE=$(stat --format="%s" "$JAR_FILE")
            echo "$PROGRAM_NAME,$ID,$SIZE" >> "$OUTPUT_FILE"
        fi
    done
done

echo "File sizes exported to $OUTPUT_FILE"
