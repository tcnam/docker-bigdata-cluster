#!/bin/bash

NODE_TYPE=$1

echo "NODE TYPE: $NODE_TYPE"

if [ "$NODE_TYPE" == "namenode" ];
then 
    sudo -u hdfs
    if [ ! -d "/opt/hadoop/data/namenode/current" ]; 
    then
        echo "Formatting NameNode..."
        hdfs namenode -format
    fi
    hdfs --daemon start namenode
    # create required directories, but may fail so do it in a loop
elif [ "$NODE_TYPE" == "resourcemanager" ];
then
    sudo -u yarn
    yarn --daemon start resourcemanager
elif [ "$NODE_TYPE" == "worker" ];
then 
    sudo -u hdfs
    rm -rf /opt/hadoop/data/datanode/*
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
elif [ "$NODE_TYPE" == "livy" ];
then 
    livy-server start
elif [ "$NODE_TYPE" == "secondarynamenode" ];
then
    # su -u hdfs
    hdfs --daemon start secondarynamenode
    # su -u yarn
    yarn --daemon start historyserver
elif [ "$NODE_TYPE" == "history" ];
then
    while ! hdfs dfs -test -d /spark_logs;
    do
    echo "spark_logs doesn't exist yet... retrying"
    sleep 1;
    done
    echo "Exit loop"

    # start the spark history server
    start-history-server.sh
fi
tail -f /dev/null