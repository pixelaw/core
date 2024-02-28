#!/bin/bash

function buildWebApp() {
  npx import-meta-env -x .env.core -p static/index.html
}

# Define the first function (thread)
function thread1() {
    cd bots && npm run dev > ../log/bots.log 2>&1;
}

# Define the second function (thread)
function thread2() {
   ./keiko
}

buildWebApp

# Populate the storage folder only if its empty
if [ -d "storage" ] && [ "$(ls -A storage)" == "" ]; then
    cp -r storage_init/* storage/
fi

# Start the first thread in the background
thread1 &

# Start the second thread in the background
thread2 &

# Wait for all background threads to finish
wait

echo "Both threads have completed."





