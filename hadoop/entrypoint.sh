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
    # hdfs namenode&
    # hdfs secondarynamenode&
    # yarn resourcemanager
    hdfs --daemon start namenode
    hdfs --daemon start secondarynamenode
    yarn --daemon start resourcemanager
    # create required directories, but may fail so do it in a loop
    hdfs dfs -mkdir -p /spark_logs
    echo "Created /spark_logs hdfs dir"
    hdfs dfs -mkdir -p /opt/spark/data
    echo "Created /opt/spark/data hdfs dir"

    # # copy the data to the data HDFS directory
    # hdfs dfs -copyFromLocal /opt/spark/data/* /opt/spark/data
    # hdfs dfs -ls /opt/spark/data
elif [ "$NODE_TYPE" == "worker" ];
then 
    rm -rf /opt/hadoop/data/dataNode/*
    # chown -R hadoop:hadoop /opt/hadoop/data/dataNode
    chmod 755 /opt/hadoop/data/dataNode
    # hdfs datanode&
    # yarn nodemanager
    hdfs --daemon start datanode
    yarn --daemon start nodemanager
elif [ "$SPARK_WORKLOAD" == "history" ];
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