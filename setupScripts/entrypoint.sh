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

    su - hdfs -c "hdfs dfs -mkdir -p /mr-history/tmp"
    su - hdfs -c "hdfs dfs -mkdir -p /mr-history/done"
    su - hdfs -c "hdfs dfs -chmod -R 1777 /mr-history/tmp"
    su - hdfs -c "hdfs dfs -chmod -R 750 /mr-history/done"
    su - hdfs -c "hdfs dfs -chown -R mapred:supergroup /mr-history"

    # Create dir for HIVE
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/tmp"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/repl"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/cmroot"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/querylog"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/warehouse/internal"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/warehouse/external"

    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/tmp/resultscache"
    su - hdfs -c "hdfs dfs -mkdir -p /user/hive/repl/functions"

    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/tmp"
    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/repl"
    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/cmroot"
    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/querylog"
    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/warehouse/internal"
    su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/warehouse/external"
    # su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/tmp/resultscache"
    # su - hdfs -c "hdfs dfs -chmod -R a+w /user/hive/repl/functions"

    su - hdfs -c "hdfs dfs -chown -R hive:supergroup /user/hive"

    su - hdfs -c "hdfs dfs -mkdir -p /tmp"
    su - hdfs -c "hdfs dfs -chmod -R a+w /tmp"

    # Create dir for spark
    # Create Spark History directory in HDFS
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs"
    su - hdfs -c "hdfs dfs -mkdir -p /spark/jars"

    # Permissions: Must be writable by all users (1777) so Spark jobs can write logs
    su - hdfs -c "hdfs dfs -chmod -R 1777 /spark/logs"

    # Ownership
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /spark"
    
    # Check if the /spark/jars exists and is not empty
    if [ $(hdfs dfs -count /spark/jars | awk '{print $2}') -gt 0 ]; then
        echo "HDFS directory /spark/jars is either empty or does not exist. Not performing put."
    else
        echo "HDFS directory /spark/jars exists and is not empty. Proceeding with put."
        su - hdfs -c "hdfs dfs -put $SPARK_HOME/jars/* /spark/jars"
    fi
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
    until HADOOP_USER_NAME=hdfs hdfs dfsadmin -fs hdfs://namenode:9000 -safemode get 2>/dev/null | grep -q 'OFF'; do
        echo "Waiting for HDFS to leave safe mode..."
        sleep 3
    done
    echo "HDFS is UP and out of Safe Mode."

    # 2. Now, wait specifically for the MapReduce directory to be created by the NameNode
    echo "Waiting for NameNode to create /mr-history/tmp..."
    while ! HADOOP_USER_NAME=mapred hdfs dfs -fs hdfs://namenode:9000 -test -d /mr-history/tmp; do
        echo "Directory /mr-history/tmp not found yet. NameNode is likely still initializing folders..."
        sleep 5
    done

    echo "HDFS Directories detected! Proceeding to start services."

    # 3. Start MapReduce History Server
    su - mapred -c "mapred --daemon start historyserver"

    # 5. Start Spark History Server
    echo "Starting Spark History Server..."
    su - spark -c "${SPARK_HOME}/sbin/start-history-server.sh"


elif [ "$NODE_TYPE" == "thriftserver" ]; then
    # 1. Wait for Postgres (The DB for the Metastore)
    until nc -z "metastore" 5432; do
        echo "Waiting for Postgres database on metastore:5432..."
        sleep 2
    done

    # 2. Wait for HDFS (Dependency)
    until HADOOP_USER_NAME=hdfs hdfs dfsadmin -fs hdfs://namenode:9000 -safemode get 2>/dev/null | grep -q 'OFF'; do
        echo "Waiting for HDFS to leave safe mode..."
        sleep 3
    done
    echo "HDFS is UP and out of Safe Mode."

    # 3. Schema Initialization
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    if schematool -dbType postgres -info > /dev/null 2>&1; then
        echo "Hive schema already initialized."
    else
        echo "Initializing Hive schema for Postgres..."
        schematool -dbType postgres -initSchema || echo "Schema already exists or failed."
    fi
    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"

    # 4. Start Hive Metastore Service (Background)
    # We use 'nohup' and redirection to keep logs clean and prevent hangup
    echo "Starting Hive Metastore Service..."
    hive --service metastore &
    
    # Wait for the Metastore RPC port (9083) to open before starting Spark
    until nc -z localhost 9083; do
        echo "Waiting for Hive Metastore service to bind to port 9083..."
        sleep 2
    done

    # 5. Start Spark Thrift Server
    echo "Starting Spark Thrift Server..."
    $SPARK_HOME/sbin/start-thriftserver.sh \
    --master yarn \
    --deploy-mode client

elif [ "$NODE_TYPE" == "edgenode" ]; then
    until hdfs dfsadmin -safemode get | grep -q 'OFF'; do
        echo "Waiting for HDFS to leave safe mode..."
        sleep 3
    done
else
    echo "Unknown NODE_TYPE: $NODE_TYPE"
    exit 1
fi

tail -f /dev/null
