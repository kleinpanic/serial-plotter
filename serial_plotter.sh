#!/usr/bin/env bash

# Configuration
SERIAL_PORT="/dev/ttyACM0"   # Update if needed
BAUD_RATE="9600"
DATA_FILE="/tmp/gnuplot_data.txt"

# Clean up previous data file
> $DATA_FILE

# Set up the serial port
stty -F $SERIAL_PORT $BAUD_RATE raw -echo

# Start gnuplot in live mode
gnuplot -persist <<- EOF &
    set title "Real-time Sensor Data"
    set xlabel "Time (s)"
    set ylabel "Sensor Value"
    set grid
    set autoscale
    plot '-' using 1:2 with lines title "Sensor Data"
EOF

# Allow time for Arduino initialization
echo "Initializing Arduino and sensors..."
sleep 5  # Adjust if needed based on Arduino setup time
echo "Initialization complete. Starting data collection..."

# Initialize time index
time_index=0

# Read data from the serial port
cat $SERIAL_PORT | while read -r line; do
    # Output every raw line for debugging purposes
    echo "Raw data: $line" >&2
    
    # Skip non-data lines
    if [[ "$line" =~ [a-zA-Z] ]] || [[ -z "$line" ]]; then
        continue
    fi

    # Extract numeric values and validate them
    valid_data=($(echo "$line" | grep -Eo '[+-]?[0-9]+(\.[0-9]+)?'))
    
    # Proceed only if we have at least one valid numeric entry
    if [ ${#valid_data[@]} -gt 0 ]; then
        # Join valid data into a space-separated string
        formatted_line="${time_index} ${valid_data[0]}"
        
        # Write to the data file and output to `gnuplot`
        echo "$formatted_line" >> $DATA_FILE
        echo "$formatted_line"
        
        echo "Filtered data: $formatted_line" >&2  # Debug output
        
        # Increment the time index
        time_index=$((time_index + 1))
    fi
done > >(gnuplot -persist)
