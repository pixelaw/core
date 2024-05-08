#!/bin/bash

# Define the first function (thread)
function thread1() {
    cd bots && npm run dev > ../log/bots.log 2>&1;
}

# Define the second function (thread)
function thread2() {
   ./keiko
}


# Start the first thread in the background
thread1 &

# Start the second thread in the background
thread2 &

# Wait for all background threads to finish
wait

echo "Both threads have completed."





