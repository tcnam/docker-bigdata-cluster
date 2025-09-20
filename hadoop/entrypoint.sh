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

elif [ "$NODE_TYPE" == "worker" ]; then 
    su - hdfs -c "hdfs --daemon start datanode"
    su - yarn -c "yarn --daemon start nodemanager"

elif [ "$NODE_TYPE" == "historyserver" ]; then
    su - yarn -c "mapred --daemon start historyserver"
    su - root -c "start-history-server.sh"
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs"
    su - hdfs -c "hdfs dfs -chown -R spark:hadoop /spark/logs"
elif [ "$NODE_TYPE" == "edgenode" ]; then
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs"
    tail -f /dev/null
else
    echo "Unknown NODE_TYPE: $NODE_TYPE"
    exit 1
fi

tail -f /dev/null
