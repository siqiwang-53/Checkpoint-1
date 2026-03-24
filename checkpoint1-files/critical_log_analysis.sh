#!/bin/bash

# Define file paths
LOG_FILE="sys_log.txt"
OUTPUT_FILE="top10_critical.txt"

# Check if the log file exists before proceeding
if [[ ! -f "$LOG_FILE" ]]; then
    echo "Error: Source file '$LOG_FILE' not found."
    exit 1
fi

echo "Starting Analysis..."

# --- 3.0.1 Step 1: Filter critical log lines ---
# Extract lines containing ERROR, CRITICAL, or FATAL (case-insensitive)
filtered_lines=$(grep -iE "ERROR|CRITICAL|FATAL" "$LOG_FILE")

# --- 3.0.2 Step 2: Tokenize the filtered lines ---
# 1. Replace spaces with newlines (one word per line)
# 2. Remove punctuation (keep only alphanumeric characters)
# 3. Remove any empty lines
tokens=$(echo "$filtered_lines" | \
    tr '[:space:]' '\n' | \
    sed 's/[^a-zA-Z0-9]//g' | \
    grep -v '^$')

# --- 3.0.3 Step 3: Count frequency and display the top 10 ---
# --- 3.0.4 Step 4: Save results to top10_critical.txt ---
# Sort alphabetically -> count unique -> sort numerically descending -> take top 10
echo "$tokens" | sort | uniq -c | sort -rn | head -10 > "$OUTPUT_FILE"

# Display the top 10 results to the terminal (Step 3 Requirement)
cat "$OUTPUT_FILE"

# Print confirmation message (Step 4 Requirement)
echo "Results saved to $OUTPUT_FILE"
