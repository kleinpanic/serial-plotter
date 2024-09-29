#!/usr/bin/env bash

# Replace /dev/ttyACM0 with your actual Arduino port
SERIAL_PORT="/dev/ttyACM0"
BAUD_RATE="9600"

# Configure the serial port
stty -F $SERIAL_PORT $BAUD_RATE raw -echo

# Read data from the serial port and print to terminal
cat $SERIAL_PORT | while read -r line; do
    echo "Raw data: $line" >&2  # Output every line to the terminal
done

