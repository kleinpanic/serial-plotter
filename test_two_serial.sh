#!/usr/bin/env bash

# Configuration
SERIAL_PORT="/dev/ttyACM0"   # Adjust if needed
BAUD_RATE="9600"
DATA_FILE="/tmp/gnuplot_data.txt"

# Initialize or clear the data file
> $DATA_FILE

# Set up the serial port
stty -F $SERIAL_PORT $BAUD_RATE raw -echo

# Start data collection
time_index=0
echo "Initializing Arduino and sensors..."
sleep 5
echo "Initialization complete. Starting data collection..."

# Function to handle cleanup and process termination
cleanup() {
    echo "Cleaning up and closing..."
    pkill -P $$  # Kills all child processes of this script
    exit 0
}
trap cleanup SIGINT SIGTERM

# Read data from the serial port
cat $SERIAL_PORT | while read -r line; do
    echo "Raw data: $line" >&2
    
    # Clean up line: keep only numbers, dots, and spaces
    clean_line=$(echo "$line" | sed 's/[^0-9\.\- ]//g')
    
    # Extract valid numeric data (ignoring everything else)
    valid_data=($(echo "$clean_line" | grep -Eo '[+-]?[0-9]+(\.[0-9]+)?'))

    # Process only if there's valid data
    if [ ${#valid_data[@]} -gt 0 ]; then
        formatted_line="${time_index} ${valid_data[0]}"
        echo "$formatted_line" >> $DATA_FILE
        echo "Filtered data: $formatted_line" >&2
        time_index=$((time_index + 1))
    fi
done &

# Allow gnuplot to initialize correctly
sleep 2
echo "Starting gnuplot..."

# Start gnuplot to read from the data file continuously
gnuplot -persist <<- EOF
    set title "Real-time Sensor Data"
    set xlabel "Time (s)"
    set ylabel "Sensor Value"
    set grid
    set autoscale
    plot "$DATA_FILE" using 1:2 with lines title "Sensor Data"
    pause 2
    while (1) {
        replot
        pause 1
    }
EOF

# Keep script running until interrupted
wait

