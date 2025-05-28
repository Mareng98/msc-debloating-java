#!/bin/bash

COMMAND_FILE=all_commands.txt

if [[ ! -f "$COMMAND_FILE" ]]; then
    echo "❌ Command file not found: $COMMAND_FILE"
    exit 1
fi

echo "▶️ Running all commands in $COMMAND_FILE with timing..."

i=1
while IFS= read -r cmd; do
    echo "🔹 [$i] Running: $cmd"
    
    # Run with timing
    { time bash -c "$cmd"; } 2>&1

    echo "--------------------------------------------------"
    ((i++))
done < "$COMMAND_FILE"

echo "✅ All commands completed."
