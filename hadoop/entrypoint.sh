#!/bin/bash

NODE_TYPE=$1

echo "NODE TYPE: $NODE_TYPE"

if [ "$NODE_TYPE" == "master" ];
then 
    if [ ! -d "/opt/hadoop/data/nameNode/current" ]; 
    then
        echo "Formatting NameNode..."
        hdfs namenode -format
    fi
    hdfs namenode&
    hdfs secondarynamenode&
    yarn resourcemanager
    # hdfs start namenode
    # hdfs start secondarynamenode
    # yarn start resourcemanager
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
    hdfs datanode&
    yarn nodemanager
    # hdfs start datanode
    # yarn start nodemanager
elif [ "$SPARK_WORKLOAD" == "history" ];
then
    # while ! hdfs dfs -test -d /spark_logs;
    # do
    # echo "spark_logs doesn't exist yet... retrying"
    # sleep 1;
    # done
    # echo "Exit loop"

    # start the spark history server
    start-history-server.sh
fi