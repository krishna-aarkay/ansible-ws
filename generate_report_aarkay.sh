#!/bin/bash

LOG_DIR="/home/ramkella/ansible-ws/daily_reports"
OUTPUT_FILE="/home/ramkella/ansible-ws/server_utilization_report.csv"
timestamp=$(date +"%m/%d/%Y %H:%M")

# Create CSV if it doesn't exist
if [ ! -f "$OUTPUT_FILE" ]; then
    echo "Server,$timestamp CPU%/MEM%" > "$OUTPUT_FILE"
    for file in "$LOG_DIR"/*.log
    do
        server=$(basename "$file" .log)
        raw=$(tail -n 1 "$file" | grep -Eo '[0-9.]+ / [0-9.]+' || echo "N/A")
        if [[ "$raw" == "N/A" ]]; then
            usage="N/A"
        else
            cpu=$(echo "$raw" | cut -d'/' -f1 | xargs printf "%.0f")
            mem=$(echo "$raw" | cut -d'/' -f2 | xargs printf "%.0f")
            usage="'$cpu / $mem"
        fi
        echo "$server,$usage" >> "$OUTPUT_FILE"
    done
    echo "✅ Report created with initial data."
    return 0
fi

# Update existing CSV with new column
first_line=$(head -n 1 "$OUTPUT_FILE")
echo "$first_line,$timestamp CPU%/MEM%" > "$OUTPUT_FILE.tmp"

tail -n +2 "$OUTPUT_FILE" > "$LOG_DIR/tmp_rows.txt"

while IFS= read -r line
do
    server=$(echo "$line" | cut -d',' -f1)
    file="$LOG_DIR/$server.log"
    if [ -f "$file" ]; then
        raw=$(tail -n 1 "$file" | grep -Eo '[0-9.]+ / [0-9.]+' || echo "N/A")
        if [[ "$raw" == "N/A" ]]; then
            usage="N/A"
        else
            cpu=$(echo "$raw" | cut -d'/' -f1 | xargs printf "%.0f")
            mem=$(echo "$raw" | cut -d'/' -f2 | xargs printf "%.0f")
            usage="'$cpu / $mem"
        fi
    else
        usage="N/A"
    fi
    echo "$line,$usage" >> "$OUTPUT_FILE.tmp"
done < "$LOG_DIR/tmp_rows.txt"

rm "$LOG_DIR/tmp_rows.txt"
mv "$OUTPUT_FILE.tmp" "$OUTPUT_FILE"
echo "✅ Report updated with timestamp: $timestamp"


