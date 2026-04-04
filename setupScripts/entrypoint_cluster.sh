#!/bin/bash
# Configuration constants based on your krb5.conf
REALM="DATAPLATFORM.LOCAL"

kinit_service() {
    local USER=$1
    local KEYTAB="/var/data/hadoop/keytabs/$2"
    local PRINCIPAL="$3@$REALM"

    if [ -f "$KEYTAB" ]; then
        echo "Authenticating $USER using $PRINCIPAL"
        chown $USER:hadoop "$KEYTAB"
        chmod 400 "$KEYTAB"
        su - $USER -c "kinit -kt $KEYTAB $PRINCIPAL"
    else
        echo "CRITICAL: Keytab $KEYTAB not found for $USER"
    fi
}

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
    kinit_service "hdfs" "namenode.keytab" "namenode/$MY_HOSTNAME"
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
    
    # Count local jars
    LOCAL_COUNT=$(ls -1 $SPARK_HOME/jars/*.jar | wc -l)

    # Count HDFS jars (using -ls and grep to avoid directory headers)
    HDFS_COUNT=$(hdfs dfs -ls /spark/jars/*.jar 2>/dev/null | grep '^-' | wc -l)

    echo "Local JAR count: $LOCAL_COUNT"
    echo "HDFS JAR count: $HDFS_COUNT"

    # Logic: If HDFS is empty OR counts do not match, refresh the directory
    if [ "$HDFS_COUNT" -eq 0 ]; then
        echo "HDFS directory /spark/jars is empty. Performing initial put."
        su - hdfs -c "hdfs dfs -mkdir -p /spark/jars && hdfs dfs -put $SPARK_HOME/jars/*.jar /spark/jars"
    elif [ "$LOCAL_COUNT" -ne "$HDFS_COUNT" ]; then
        echo "Count mismatch ($LOCAL_COUNT vs $HDFS_COUNT). Deleting and refreshing /spark/jars..."
        # Clear and Re-put
        su - hdfs -c "hdfs dfs -rm -f /spark/jars/*.jar && hdfs dfs -put $SPARK_HOME/jars/*.jar /spark/jars"
        echo "Sync complete."
    else
        echo "HDFS /spark/jars is already in sync with local $SPARK_HOME/jars. No action needed."
    fi

    # --- Spark Setup inside the namenode block ---
    su - hdfs -c "hdfs dfs -mkdir -p /spark/logs /spark/jars /user/spark"
    su - hdfs -c "hdfs dfs -chmod 1777 /spark/logs"
    su - hdfs -c "hdfs dfs -chown -R spark:supergroup /spark /user/spark"

    echo "Finish creating folders"

elif [ "$NODE_TYPE" == "secondarynamenode" ]; then
    kinit_service "hdfs" "secondarynamenode.keytab" "secondarynamenode/$MY_HOSTNAME"
    su - hdfs -c "hdfs --daemon start secondarynamenode"

elif [ "$NODE_TYPE" == "resourcemanager" ]; then
    kinit_service "yarn" "resourcemanager.keytab" "resourcemanager/$MY_HOSTNAME"
    su - yarn -c "yarn --daemon start resourcemanager"

elif [ "$NODE_TYPE" == "worker" ]; then
    kinit_service "hdfs" "worker.keytab" "worker/$MY_HOSTNAME"
    kinit_service "yarn" "worker.keytab" "worker/$MY_HOSTNAME"
    su - hdfs -c "hdfs --daemon start datanode"
    su - yarn -c "yarn --daemon start nodemanager"

elif [ "$NODE_TYPE" == "historyserver" ]; then
    kinit_service "mapred" "historyserver.keytab" "historyserver/$MY_HOSTNAME"
    kinit_service "spark" "historyserver.keytab" "historyserver/$MY_HOSTNAME"
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
    kinit_service "hive" "thriftserver.keytab" "thriftserver/$MY_HOSTNAME"
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
    su - hive -c "$SPARK_HOME/sbin/start-thriftserver.sh --master yarn --deploy-mode client"

    # 6. Start Spark Connect
    echo "Starting Spark Connect Server..."
    su - spark -c "$SPARK_HOME/sbin/start-connect-server.sh"

elif [ "$NODE_TYPE" == "krb5kdc" ]; then
    echo "Starting KDC Node..."
    
    # Check if the database exists; if not, create it
    if [ ! -f "/var/kerberos/krb5kdc/principal" ]; then
        echo "Initializing Kerberos Database..."
        # Create the database with a dummy master password 'password'
        # In production, use a more secure method or a mounted stash file
        kdb5_util create -s -P password
    fi

    # Start the KDC and Admin services
    echo "Launching krb5kdc and kadmind..."
    krb5kdc
    kadmind -nofork # -nofork keeps the container alive
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
