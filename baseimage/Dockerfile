# --- STAGE 1: Extraction Builder ---
FROM debian:12-slim AS builder

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
FROM debian:12-slim

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install Base Tools, Python 3.11, and Adoptium Java 8
RUN apt-get update && apt-get install -y --no-install-recommends \
    wget curl ca-certificates gnupg software-properties-common lsb-release \
    net-tools netcat-openbsd libsnappy-dev \
    procps psmisc \
    krb5-user libkrb5-3 krb5-kdc krb5-admin-server haveged \
    python3 python3-dev python3-pip python3-distutils && \
    ln -s /usr/bin/python3 /usr/bin/python && \
    # Add Adoptium Repository (Universal)
    mkdir -p /etc/apt/keyrings && \
    wget -O - https://packages.adoptium.net/artifactory/api/gpg/key/public | gpg --dearmor > /etc/apt/keyrings/adoptium.gpg && \
    # FIXED PATH: /etc/apt/sources.list.d/
    echo "deb [signed-by=/etc/apt/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb $(lsb_release -cs) main" > /etc/apt/sources.list.d/adoptium.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends temurin-8-jdk && \
    rm -rf /var/lib/apt/lists/*

# 2. Dynamic Java Path Logic
# Instead of hardcoding 'amd64', we find where it was installed
RUN JAVA_PATH=$(update-java-alternatives -l | grep "8" | awk '{print $3}') && \
    ln -s "${JAVA_PATH}" /usr/lib/jvm/java-8-openjdk

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
    PYSPARK_PYTHON=/usr/bin/python3 \
    PYSPARK_DRIVER_PYTHON=/usr/bin/python3 \
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
    for user in yarn hdfs mapred spark hive; do useradd -m -g hadoop $user && echo "$user:$user" | chpasswd; done && \
    mkdir -p /var/lib/krb5kdc/logs /var/data/hadoop/keytabs /var/data/hadoop/hdfs/nn \
             /var/data/hadoop/hdfs/snn /var/data/hadoop/hdfs/dn /var/data/hadoop/logs \
             /var/data/hadoop/pid /var/data/hadoop/tmp /var/data/hadoop/hive/local \
             /var/data/hadoop/hive/resources /var/data/hadoop/hive/operationlog \
             /var/data/hadoop/hive/logs /workspace && \
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
    echo "export PYSPARK_PYTHON=/usr/bin/python3"; \
    echo "export PYSPARK_DRIVER_PYTHON=/usr/bin/python3"; \
    echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:$PATH' >> /etc/profile

WORKDIR /workspace