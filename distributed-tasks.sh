#!/bin/bash

# Set the list of machines to use. For eg -
MACHINES=("machine1" "machine2" "machine3" "machine4") #eg MACHINES=("127.0.0.1")

# Set the list of users for each machine
USERS=("user1" "user2" "user3" "user4")

# Set the number of machines to use
NUM_MACHINES=${#MACHINES[@]}

# Split the Files into subsets
split -n $NUM_MACHINES --numeric-suffixes=1 -a 1 $1 $1_

# Copy the files to each machine in tmp/ directory
for i in $(seq 1 $NUM_MACHINES); do
    rsync $1_$i ${USERS[$i-1]}@${MACHINES[$i-1]}:/tmp/$1
done
echo "Copying files finished on each machine"

# Running Task on each machine
for i in $(seq 1 $NUM_MACHINES); do
    ssh ${USERS[$i-1]}@${MACHINES[$i-1]} "cd /tmp/ && cat $1 | /root/go/bin/httpx -title -silent > output-result; wait" & #command to run
done
echo "Task on each machine started"

#Storing output 0 for number of machines for comparing later
output=$(printf '0 %.0s' $(seq 1 $NUM_MACHINES))

# Wait for Task to finish on all machines
while true; do
    STATUS=$(for i in $(seq 1 $NUM_MACHINES); do ssh ${USERS[$i-1]}@${MACHINES[$i-1]} "pgrep -c httpx"; done)
        if [ $STATUS == $output ]; then
        break
    else
        sleep 15
    fi
done
echo "Task finished on each machine.....Collecting results"
# Collect and combine the results
for i in $(seq 1 $NUM_MACHINES); do
    rsync ${USERS[$i-1]}@${MACHINES[$i-1]}:/tmp/output-result results_$i.txt
done
cat results_*.txt > all_results.txt
echo "Distributed Processing Finished..... Results saved to current directory as all_results.txt"
