#!/bin/bash

NODE_TYPE=$1

echo "NODE TYPE: $NODE_TYPE"

if [ "$NODE_TYPE" == "namenode" ]; then 
    if [ ! -d "/var/data/hadoop/hdfs/nn/current" ]; then
        echo "Formatting NameNode..."
        su - hdfs -c "hdfs namenode -format"
    fi
    su - hdfs -c "hdfs --daemon start namenode"

elif [ "$NODE_TYPE" == "secondarynamenode" ]; then
    su - hdfs -c "hdfs --daemon start secondarynamenode"

elif [ "$NODE_TYPE" == "resourcemanager" ]; then
    su - yarn -c "yarn --daemon start resourcemanager"
    # su - spark -c "start-master.sh"

elif [ "$NODE_TYPE" == "worker" ]; then 
    su - hdfs -c "hdfs --daemon start datanode"
    su - yarn -c "yarn --daemon start nodemanager"
    # su - spark -c "start-worker.sh"

elif [ "$NODE_TYPE" == "historyserver" ]; then
    su - yarn -c "mapred --daemon start historyserver"
elif [ "$NODE_TYPE" == "edgenode" ]; then
    su - root -c "tail -f /dev/null"
else
    echo "Unknown NODE_TYPE: $NODE_TYPE"
    exit 1
fi

tail -f /dev/null
