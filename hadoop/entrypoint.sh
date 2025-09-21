#!/bin/bash

NODE_TYPE=$1

echo "NODE TYPE: $NODE_TYPE"

if [ "$NODE_TYPE" == "namenode" ]; then 
    if [ ! -d "/var/data/hadoop/hdfs/nn/current" ]; then
        echo "Formatting NameNode..."
        su - hdfs -c "hdfs namenode -format"
    fi
    su - hdfs -c "hdfs --daemon start namenode"
    # check if hdfs leave safemode or not
    until su - hdfs -c "hdfs dfsadmin -safemode get | grep -q 'OFF'"; do
        echo "Waiting for HDFS to leave safe mode..."
    done

    echo "HDFS to leave safe mode, start creating folders"

    # create folders in hdfs after leaving safe mode
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs"
    su - hdfs -c "hdfs dfs -mkdir -p /spark/jars"
    su - hdfs -c "hdfs dfs -put -f $SPARK_HOME/jars/* /spark/jars"
    # su - hdfs -c "hdfs dfs -chmod 775 /spark"
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /spark"

    su - hdfs -c "hdfs dfs -mkdir -p /user/spark"
    su - hdfs -c "hdfs dfs -chown spark:supergroup /user/spark"

    su - hdfs -c "hdfs dfs -mkdir -p /user/yarn"
    su - hdfs -c "hdfs dfs -chown yarn:supergroup /user/yarn"

    su - hdfs -c "hdfs dfs -mkdir -p /user/mapred"
    su - hdfs -c "hdfs dfs -chown mapred:supergroup /user/mapred"

    echo "Finish creating folders"

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

elif [ "$NODE_TYPE" == "edgenode" ]; then
    tail -f /dev/null
else
    echo "Unknown NODE_TYPE: $NODE_TYPE"
    exit 1
fi

tail -f /dev/null
