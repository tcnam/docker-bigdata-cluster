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
        sleep 3
    done

    echo "HDFS to leave safe mode, start creating folders"

    # create folders in hdfs after leaving safe mode

    # Create dir for yarn
    su - hdfs -c "hdfs dfs -mkdir -p /user/yarn"
    su - hdfs -c "hdfs dfs -chown -R yarn:supergroup /user/yarn"

    # Create dir for map reduce
    su - hdfs -c "hdfs dfs -mkdir -p /user/mapred"
    su - hdfs -c "hdfs dfs -chown -R mapred:supergroup /user/mapred"

    # Create dir for HIVE
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/tmp"
    su - hdfs -c "hdfs dfs -chmod a+w /user/hive/tmp"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/warehouse"
    su - hdfs -c "hdfs dfs -chmod a+w /user/hive/warehouse"
    su - hdfs -c "hdfs dfs -chown -R hive:supergroup /user/hive"

    # Create dir for spark
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs"
    su - hdfs -c "hdfs dfs -mkdir -p /spark/jars"
    su - hdfs -c "hdfs dfs -put -f $SPARK_HOME/jars/* /spark/jars"
    # su - hdfs -c "hdfs dfs -chmod 775 /spark"
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /spark"
    su - hdfs -c "hdfs dfs -mkdir -p /user/spark"
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /user/spark"

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

elif [ "$NODE_TYPE" == "hiveserver2" ]; then
    until hdfs dfsadmin -safemode get | grep -q 'OFF'; do
        echo "Waiting for HDFS to leave safe mode..."
        sleep 3
    done
    # Initialize the Hive Metastore schema if not already initialized
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    if schematool -dbType postgres -info | grep -q "Schema version"; then
        echo "Hive schema already initialized."
    else
        echo "Initializing Hive schema..."
        schematool -dbType postgres -initSchema || echo "Schema already initialized or encountered an error"
    fi
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    # Start Hive Metastore
    hive --service metastore &

    # Start HiveServer2
    hive --service hiveserver2 &

elif [ "$NODE_TYPE" == "edgenode" ]; then
    until hdfs dfsadmin -safemode get | grep -q 'OFF'; do
        echo "Waiting for HDFS to leave safe mode..."
        sleep 3
    done
    tail -f /dev/null
else
    echo "Unknown NODE_TYPE: $NODE_TYPE"
    exit 1
fi

tail -f /dev/null
