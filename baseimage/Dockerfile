# --- STAGE 1: Extraction Builder ---
FROM ubuntu:16.04 AS builder

# Re-declare your ARGs exactly as before
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG HIVE_VERSION

# Copy your local source files
COPY baseimage/files/ /opt/
COPY baseimage/3rdjars/ /opt/3rdjars/

# Extract and move to generic paths in one layer
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    tar -zxvf /opt/spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark && \
    tar -xvzf /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-${HIVE_VERSION}-bin /opt/hive && \
    # Logic: Move shuffle jar and 3rd party jars here
    cp /opt/spark/yarn/spark-${SPARK_VERSION}-yarn-shuffle.jar /opt/hadoop/share/hadoop/yarn/lib/ && \
    mv /opt/3rdjars/spark/*.jar /opt/spark/jars/


# --- STAGE 2: Final Slim Image ---
FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Consolidated APT Install (Includes cleanup in the same layer)
RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-8-jdk wget curl net-tools netcat gnupg libsnappy-dev \
    krb5-user libkrb5-3 krb5-kdc krb5-admin-server haveged && \
    rm -rf /var/lib/apt/lists/*

# 2. Re-establish your exact JAVA logic
ARG ARCHITECTURE
RUN mv /usr/lib/jvm/java-8-openjdk-${ARCHITECTURE} /usr/lib/jvm/java-8-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk \
    JRE_HOME=/usr/lib/jvm/java-8-openjdk/jre
ENV PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

# 3. Copy extracted folders from Builder (The .tar.gz files stay behind)
COPY --from=builder /opt/hadoop /opt/hadoop
COPY --from=builder /opt/spark /opt/spark
COPY --from=builder /opt/hive /opt/hive

# 4. Consolidate Environment Variables
ENV HADOOP_HOME=/opt/hadoop \
    SPARK_HOME=/opt/spark \
    HIVE_HOME=/opt/hive \
    KRB5_CONFIG=/etc/krb5.conf \
    KRB5_KDC_PROFILE=/etc/krb5kdc/kdc.conf \
    HDFS_NAMENODE_USER=hdfs \
    HDFS_DATANODE_USER=hdfs \
    HDFS_SECONDARYNAMENODE_USER=hdfs \
    YARN_RESOURCEMANAGER_USER=yarn \
    YARN_NODEMANAGER_USER=yarn \
    POSTGRES_HOST=metastore \
    POSTGRES_DB=metastore \
    POSTGRES_USER=hive \
    POSTGRES_PASSWORD=hive \
    LD_LIBRARY_PATH=/opt/hadoop/lib/native \
    HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop \
    HIVE_CONF_DIR=/opt/hive/conf \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:/opt/spark/bin:/opt/spark/sbin:/opt/hive/bin:$PATH

# 5. Consolidated User & Directory Logic
RUN groupadd hadoop && \
    usermod -aG hadoop root && echo "root:root" | chpasswd && \
    useradd -m -g hadoop yarn   && echo "yarn:yarn"     | chpasswd && \
    useradd -m -g hadoop hdfs   && echo "hdfs:hdfs"     | chpasswd && \
    useradd -m -g hadoop mapred && echo "mapred:mapred" | chpasswd && \
    useradd -m -g hadoop spark  && echo "spark:spark"   | chpasswd && \
    useradd -m -g hadoop hive   && echo "hive:hive"     | chpasswd && \
    # Create all directories in one command
    mkdir -p /var/lib/krb5kdc/logs /var/data/hadoop/keytabs /var/data/hadoop/hdfs/nn \
             /var/data/hadoop/hdfs/snn /var/data/hadoop/hdfs/dn /var/data/hadoop/logs \
             /var/data/hadoop/pid /var/data/hadoop/tmp /var/data/hadoop/hive/local \
             /var/data/hadoop/hive/resources /var/data/hadoop/hive/operationlog \
             /var/data/hadoop/hive/logs /workspace && \
    # Permissions
    chown root:hadoop /var/data/hadoop/keytabs && chmod 750 /var/data/hadoop/keytabs && \
    chown -R hdfs:hadoop /var/data/hadoop/hdfs && \
    chown -R yarn:hadoop /var/data/hadoop/logs /var/data/hadoop/pid /var/data/hadoop/tmp && \
    chmod -R 775 /var/data/hadoop/logs /var/data/hadoop/pid /var/data/hadoop/tmp && \
    chown -R hive:hadoop /var/data/hadoop/hive /opt/hive && \
    chmod -R 775 /var/data/hadoop/hive

# 6. Final Profile setup (Exact strings from original)
RUN echo 'export HADOOP_HOME=/opt/hadoop' >> /etc/profile && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /etc/profile && \
    echo 'export SPARK_HOME=/opt/spark' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk' >> /etc/profile && \
    echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native' >> /etc/profile && \
    echo 'export HIVE_HOME=/opt/hive' >> /etc/profile && \
    echo 'export HIVE_CONF_DIR=$HIVE_HOME/conf' >> /etc/profile && \
    echo 'export POSTGRES_HOST=metastore' >> /etc/profile && \
    echo 'export POSTGRES_DB=metastore' >> /etc/profile && \
    echo 'export POSTGRES_USER=hive' >> /etc/profile && \
    echo 'export POSTGRES_PASSWORD=hive' >> /etc/profile && \
    echo 'export KRB5_CONFIG=/etc/krb5.conf' >> /etc/profile && \
    echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:$PATH' >> /etc/profile

WORKDIR /workspace