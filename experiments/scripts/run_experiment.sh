#!/bin/bash

SHUFFLED_FILE=shuffled_commands.txt
OUTPUT_BASE="energy-experiment-measurements"
RESULTS_DIR="$OUTPUT_BASE/results"
NOISE_DIR="$OUTPUT_BASE/noise"
EXPECTED_BRANCH="run-1"
PUSH_INTERVAL=30
LOG_FILE="$OUTPUT_BASE/experiment_log.txt"
IDLE_SCRIPT="$HOME/Documents/MasterThesis_ExperimentReady/idle_process.sh"

# Setup logging
mkdir -p "$OUTPUT_BASE"
touch "$LOG_FILE"
exec > >(tee -a "$LOG_FILE") 2>&1

# Run an artifact for 5 minutes to warm up
echo "Warming up..."
time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o warmup.csv -i 1000 java -jar benchmarks/jgit/artifacts/artifact_vanilla.jar 14300 false false" > /dev/null 2>&1
time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o warmup.csv -i 1000 java -jar benchmarks/jgit/artifacts/artifact_vanilla.jar 14300 false false" > /dev/null 2>&1
time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o warmup.csv -i 1000 java -jar benchmarks/jgit/artifacts/artifact_vanilla.jar 14300 false false" > /dev/null 2>&1
time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o warmup.csv -i 1000 java -jar benchmarks/jgit/artifacts/artifact_vanilla.jar 14300 false false" > /dev/null 2>&1
time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o warmup.csv -i 1000 java -jar benchmarks/jgit/artifacts/artifact_vanilla.jar 14300 false false" > /dev/null 2>&1

sleep 60

echo "Starting energy experiment run..."

# Check if input file exists
if [[ ! -f "$SHUFFLED_FILE" ]]; then
    echo "File not found: $SHUFFLED_FILE"
    exit 1
fi

# Verify Git branch
echo "Verifying Git branch in $OUTPUT_BASE..."
CURRENT_BRANCH=$(git -C "$OUTPUT_BASE" rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "$EXPECTED_BRANCH" ]]; then
    echo "Error: Git repo in '$OUTPUT_BASE' is on branch '$CURRENT_BRANCH' but expected '$EXPECTED_BRANCH'."
    echo "Please switch to the correct branch before running this script."
    exit 1
fi
echo "Git branch verified: $CURRENT_BRANCH"

# Phase 1: Determine all SUT/Tool combos
declare -A allCombos
while IFS= read -r cmd; do
    SUT=$(echo "$cmd" | grep -oE '/(benchmarks|real_world_programs)/[^/]+/artifacts' | head -n1 | awk -F'/' '{print $3}')

    if [[ "$cmd" == *"jlink-runtime"* ]]; then
        TOOL="jlink"
    elif [[ "$cmd" == *"artifact_depclean.jar"* ]]; then
        TOOL="depclean"
    elif [[ "$cmd" == *"artifact_deptrim.jar"* ]]; then
        TOOL="deptrim"
    elif [[ "$cmd" == *"artifact_proguard.jar"* ]]; then
        TOOL="proguard"
    elif [[ "$cmd" == *"artifact_vanilla.jar"* ]]; then
        TOOL="vanilla"
    else
        TOOL="unknown"
    fi

    KEY="${SUT}_${TOOL}"
    allCombos["$KEY"]="$SUT/$TOOL"
done < "$SHUFFLED_FILE"

# Phase 2: Create directories and validate they’re empty
echo "Checking measurement output directories..."
for combo in "${allCombos[@]}"; do
    RESULT_DIR="$RESULTS_DIR/$combo"
    NOISE_PATH="$NOISE_DIR/$combo"

    mkdir -p "$RESULT_DIR"
    mkdir -p "$NOISE_PATH"

    if [[ -n $(ls -A "$RESULT_DIR") || -n $(ls -A "$NOISE_PATH") ]]; then
        echo "Existing data found in $RESULT_DIR or $NOISE_PATH. Aborting to prevent data loss."
        exit 1
    fi
done
echo "All folders created and verified to be empty."

# Phase 3: Execute commands
declare -A counters
count_since_push=0
i=1

function push_data() {
    echo "Syncing with GitHub..."
    pushd "$OUTPUT_BASE" > /dev/null

    git add .
    git add experiment_log.txt

    git commit -m "Auto commit after $i commands"

    # Pull using merge (not rebase), and abort if there's a conflict
    if ! git pull --no-rebase --no-commit --no-edit; then
        echo "Merge conflict detected during 'git pull'. Aborting script to prevent data loss."
        exit 1
    fi

    if ! git push origin "$EXPECTED_BRANCH"; then
        echo "Failed to push to remote. Aborting."
        exit 1
    fi

    popd > /dev/null
}


while IFS= read -r cmd; do
    SUT=$(echo "$cmd" | grep -oE '/(benchmarks|real_world_programs)/[^/]+/artifacts' | head -n1 | awk -F'/' '{print $3}')

    if [[ "$cmd" == *"jlink-runtime"* ]]; then
        TOOL="jlink"
    elif [[ "$cmd" == *"artifact_depclean.jar"* ]]; then
        TOOL="depclean"
    elif [[ "$cmd" == *"artifact_deptrim.jar"* ]]; then
        TOOL="deptrim"
    elif [[ "$cmd" == *"artifact_proguard.jar"* ]]; then
        TOOL="proguard"
    elif [[ "$cmd" == *"artifact_vanilla.jar"* ]]; then
        TOOL="vanilla"
    else
        TOOL="unknown"
    fi

    KEY="${SUT}_${TOOL}"
    if [[ -z "${counters[$KEY]}" ]]; then
        counters[$KEY]=1
    else
        counters[$KEY]=$((counters[$KEY]+1))
    fi
    ITERATION=${counters[$KEY]}
    OUTPUT_PATH="$RESULTS_DIR/${SUT}/${TOOL}/${ITERATION}.csv"
    OUTPUT_PATH_NOISE="$NOISE_DIR/${SUT}/${TOOL}/${ITERATION}.csv"

    echo "[$i] Running: ./energibridge.exe -o \"$OUTPUT_PATH\" -i 1000 $cmd"
    { time bash -c "$HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o \"$OUTPUT_PATH\" -i 1000 $cmd"; } 2>&1


    ((count_since_push++))
    ((i++))

    if (( count_since_push == PUSH_INTERVAL )); then
        push_data
        count_since_push=0
    fi

    # Noise measurement
    echo "Measuring background system noise..."
    bash -c "time $HOME/Documents/MasterThesis/EnergiBridge/target/release/energibridge -o \"$OUTPUT_PATH_NOISE\" -i 1000 $IDLE_SCRIPT"

done < "$SHUFFLED_FILE"

# Final push if needed
if (( count_since_push > 0 )); then
    push_data
fi

echo "All commands completed with noise measurements and changes pushed to GitHub."
