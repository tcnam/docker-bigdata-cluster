#!/bin/bash

check_spark_jars_synced() {
    # 1. Count local files
    local LOCAL_COUNT=$(ls -1 "$SPARK_HOME/jars" 2>/dev/null | wc -l)
    
    # 2. Count HDFS files (using HADOOP_USER_NAME and explicit NameNode URI)
    local HDFS_COUNT=$(HADOOP_USER_NAME=hdfs hdfs dfs -fs hdfs://namenode:9000 -count /spark/jars 2>/dev/null | awk '{print $2}')
    HDFS_COUNT=${HDFS_COUNT:-0}

    # 3. Return 0 (True) only if they match and are not zero
    if [ "$LOCAL_COUNT" -eq "$HDFS_COUNT" ] && [ "$LOCAL_COUNT" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

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

    su - hdfs -c "hdfs dfs -mkdir -p /mr-history/tmp /mr-history/done"
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

    # --- Spark Setup inside the namenode block ---
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs /spark/jars /user/spark"
    su - hdfs -c "hdfs dfs -chmod 1777 /spark/logs"
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /spark /user/spark"
    
    echo "Checking Spark JARs..."
    # Get the count safely; if it fails, default to 0
    JAR_COUNT=$(su - hdfs -c "hdfs dfs -count /spark/jars" 2>/dev/null | awk '{print $2}')
    JAR_COUNT=${JAR_COUNT:-0}

    if [ "$JAR_COUNT" -eq 0 ]; then
        echo "HDFS /spark/jars is empty. Uploading JARs..."
        su - hdfs -c "hdfs dfs -put $SPARK_HOME/jars/* /spark/jars"
    else
        echo "Spark JARs already detected ($JAR_COUNT files). Skipping upload."
    fi

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

    # 2. Wait specifically for /mr-history/done to be created AND owned by mapred
    echo "Waiting for NameNode to initialize /mr-history/done..."
    while true; do
        # Check if directory exists
        if hdfs dfs -fs hdfs://namenode:9000 -test -d /mr-history/done; then
            # Check if ownership has been switched to mapred (the last step in your NN block)
            OWNER=$(hdfs dfs -fs hdfs://namenode:9000 -ls -d /mr-history/done | awk '{print $3}')
            if [ "$OWNER" == "mapred" ]; then
                echo "Directories ready and owned by mapred. Starting service..."
                break
            fi
        fi
        echo "Directories not ready or incorrect permissions. Waiting 5s..."
        sleep 5
    done

    # 3. Start MapReduce History Server
    echo "HDFS Directories detected! Proceeding to start services."
    su - mapred -c "mapred --daemon start historyserver"

    # 4. Now, wait specifically for the Spark directory to be created by the NameNode
    echo "Waiting for Spark JARs to be fully synced from NameNode..."
    until check_spark_jars_synced; do
        echo "JAR count mismatch or HDFS not ready. Retrying in 5s..."
        sleep 5
    done
    echo "Spark JARs are synced! Proceeding with service start."

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

    echo "Waiting for Spark JARs to be fully synced from NameNode..."
    until check_spark_jars_synced; do
        echo "JAR count mismatch or HDFS not ready. Retrying in 5s..."
        sleep 5
    done
    echo "Spark JARs are synced! Proceeding with service start."

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
