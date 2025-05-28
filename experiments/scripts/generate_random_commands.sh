#!/bin/bash

# Set root directory
ROOT_DIR=~/Documents/MasterThesis_ExperimentReady
OUTPUT_FILE=all_commands.txt
FINAL_SHUFFLED_FILE=shuffled_commands.txt

# Clean old output
> "$OUTPUT_FILE"
> "$FINAL_SHUFFLED_FILE"

# 1. Process benchmarks with iterations
for dir in "$ROOT_DIR"/benchmarks/*/; do
    SUT=$(basename "$dir")
    ARTIFACT_PATH="$ROOT_DIR/benchmarks/$SUT/artifacts"
    ITERATION_FILE="$ROOT_DIR/benchmarks/$SUT/iterations.txt"

    if [[ -f "$ITERATION_FILE" ]]; then
        ITERATIONS=$(cat "$ITERATION_FILE")
    else
        echo "⚠️  Warning: No iterations.txt found for $SUT, defaulting to 1"
        ITERATIONS=1
    fi

    echo "java -jar $ARTIFACT_PATH/artifact_vanilla.jar $ITERATIONS false false" >> "$OUTPUT_FILE"
    echo "java -jar $ARTIFACT_PATH/artifact_proguard.jar $ITERATIONS false false" >> "$OUTPUT_FILE"
    echo "java -jar $ARTIFACT_PATH/artifact_depclean.jar $ITERATIONS false false" >> "$OUTPUT_FILE"
    echo "java -jar $ARTIFACT_PATH/artifact_deptrim.jar $ITERATIONS false false" >> "$OUTPUT_FILE"
    echo "$ARTIFACT_PATH/jlink-runtime/bin/java -jar $ARTIFACT_PATH/artifact_vanilla.jar $ITERATIONS false false" >> "$OUTPUT_FILE"
done

# 2. Process real_world_programs with $ARTIFACT_FOLDER$ placeholder
for dir in "$ROOT_DIR"/real_world_programs/*/; do
    SUT=$(basename "$dir")
    ARTIFACT_PATH="$ROOT_DIR/real_world_programs/$SUT/artifacts"
    CMD_FILE="$ROOT_DIR/real_world_programs/$SUT/runCommands.txt"

    if [[ -f "$CMD_FILE" ]]; then
        while IFS= read -r line; do
            # Replace $ARTIFACT_FOLDER$ with full path
            FIXED_CMD="${line//\$ARTIFACT_FOLDER\$/$ARTIFACT_PATH}"
            # Append output redirection to suppress stdout/stderr
            echo "$FIXED_CMD > /dev/null 2>&1" >> "$OUTPUT_FILE"
        done < "$CMD_FILE"
    fi
done


# 3. Deduplicate and repeat each command 30 times, then shuffle
declare -A unique_cmds

while IFS= read -r cmd; do
    unique_cmds["$cmd"]=1
done < "$OUTPUT_FILE"

for cmd in "${!unique_cmds[@]}"; do
    for i in {1..30}; do
        echo "$cmd"
    done
done | shuf > "$FINAL_SHUFFLED_FILE"

echo "✅ Done. Shuffled commands saved to: $FINAL_SHUFFLED_FILE"
