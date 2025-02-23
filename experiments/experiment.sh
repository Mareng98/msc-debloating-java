#!/bin/bash

# Enable error handling
set -e

# Set environment variables
export PROJECT_DIR=$(pwd)
export VANILLA_JAR_NAME="artifact_vanilla.jar"
export DEPTRIM_JAR_NAME="artifact_deptrim.jar"
export DEPCLEAN_JAR_NAME="artifact_depclean.jar"
export PROGUARD_JAR_NAME="artifact_proguard.jar"

# Loop through each folder inside the SUT directory
for FOLDER in "$PROJECT_DIR/SUT"/*/; do
  # Check if the folder is indeed a directory (in case of symbolic links or other non-directory files)
  if [ -d "$FOLDER" ]; then
    export FOLDER_NAME=$(basename "$FOLDER") # Get name of folder
    export RESULT_FOLDER="$PROJECT_DIR/measurements/energibridge/$FOLDER_NAME"
    echo "Processing folder: $FOLDER"
    # Set the ARTIFACTS_FOLDER variable for each folder
    export ARTIFACTS_FOLDER="$FOLDER"artifacts

    # 0. Ensure result folder exists for SUT
    echo "0. Ensure result folder exists for $FOLDER_NAME"
    if [ ! -d "$RESULT_FOLDER" ]; then
      echo "Creating result directory at $RESULT_FOLDER"
      mkdir -p "$RESULT_FOLDER"
    fi

    # 1. For loop that runs 20 times and adds run_i folder in RESULT_FOLDER
    for i in {1..20}; do
      RUN_FOLDER="$RESULT_FOLDER/run_$i"
      echo "1.1 Creating run folder: $RUN_FOLDER"
      mkdir -p "$RUN_FOLDER"

      # 1.1 For loop that runs once for each artifact name (VANILLA_JAR_NAME, DEPTRIM_JAR_NAME, etc.)
      for ARTIFACT_NAME in "$VANILLA_JAR_NAME" "$DEPTRIM_JAR_NAME" "$DEPCLEAN_JAR_NAME" "$PROGUARD_JAR_NAME"; do
        echo "1.2 Running energibridge for artifact: $ARTIFACT_NAME"

        # Run the energibridge command and save the result in the corresponding CSV file
        "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge" -i 200 -o "$RUN_FOLDER/result_${ARTIFACT_NAME%.jar}.csv" java -jar "$ARTIFACTS_FOLDER/$ARTIFACT_NAME" 100 false
      done
    done
  fi
done
