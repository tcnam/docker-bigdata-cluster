# --- STAGE 1: Extraction Builder ---
FROM --platform=$BUILDPLATFORM almalinux:9-minimal AS builder

# Re-declare your ARGs exactly as before
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG HIVE_VERSION
ARG KYUUBI_VERSION
ARG AIRFLOW_VERSION
ARG JAVA_VERSION
ARG PYTHON_VERSION

RUN microdnf install -y tar gzip

# Copy your local source files
COPY baseimage/files/ /opt/
COPY baseimage/3rdjars/ /opt/3rdjars/
COPY baseimage/krb5/ /opt/krb5/
COPY baseimage/requirements.txt /opt/airflow/requirements.txt

# Extract and move to generic paths in one layer
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    tar -zxvf /opt/spark-${SPARK_VERSION}-bin-hadoop3.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3 /opt/spark && \
    tar -xvzf /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-${HIVE_VERSION}-bin /opt/hive && \
    tar -xvzf /opt/apache-kyuubi-${KYUUBI_VERSION}-bin.tgz -C /opt && \
    mv /opt/apache-kyuubi-${KYUUBI_VERSION}-bin /opt/kyuubi && \
    # Logic: Move shuffle jar and 3rd party jars here
    cp /opt/spark/yarn/spark-${SPARK_VERSION}-yarn-shuffle.jar /opt/hadoop/share/hadoop/yarn/lib/ && \
    if [ -d /opt/3rdjars/spark ]; then mv /opt/3rdjars/spark/*.jar /opt/spark/jars/; fi && \
    rm -rf /opt/hadoop/share/doc \
           /opt/spark/examples \
           /opt/spark/data \
           /opt/spark/kubernetes \
           /opt/hive/docs && \
    find /opt/hadoop -name "*.cmd" -delete && \
    find /opt/spark -name "*.cmd" -delete && \
    find /opt/spark -name "*.exe" -delete


# --- STAGE 2: Final Slim Image ---
FROM almalinux:9-minimal

ARG TARGETARCH
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG HIVE_VERSION
ARG KYUUBI_VERSION
ARG AIRFLOW_VERSION
ARG JAVA_VERSION
ARG PYTHON_VERSION

# 1. Install Base Tools, Python 3.11, and Adoptium Java 8
RUN microdnf install -y \
    wget ca-certificates ncurses\
    net-tools nc snappy \
    procps-ng psmisc ${JAVA_VERSION}\
    krb5-server krb5-workstation krb5-libs \
    python${PYTHON_VERSION} python${PYTHON_VERSION}-devel\
    shadow-utils sudo tar\
    # airlfow Required Libraries
    yum-utils make gcc openssl-devel bzip2-devel libffi-devel zlib-devel libpq-devel sqlite-devel \
    && \
    microdnf clean all && \
    curl https://mise.run | MISE_INSTALL_PATH=/usr/local/bin/mise sh && \
    curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=/usr/local/bin sh && \
    rm -rf /var/cache/yum /tmp/*

RUN ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python3 && \
    ln -sf /usr/bin/python${PYTHON_VERSION} /usr/bin/python

# 2. Dynamic Java Path Logic
# Instead of hardcoding 'amd64', we find where it was installed
RUN JAVA_PATH=$(ls -d /usr/lib/jvm/${JAVA_VERSION}*) && \
    ln -s "${JAVA_PATH}" /usr/lib/jvm/java-jdk

ENV JAVA_HOME=/usr/lib/jvm/java-jdk/jre \
    JRE_HOME=/usr/lib/jvm/java-jdk/jre
ENV PATH=${JAVA_HOME}/bin:${JRE_HOME}/bin:$PATH

# 3. Copy extracted folders from Builder (The .tar.gz files stay behind)
COPY --from=builder /opt/hadoop /opt/hadoop
COPY --from=builder /opt/spark /opt/spark
COPY --from=builder /opt/hive /opt/hive
COPY --from=builder /opt/kyuubi /opt/kyuubi
COPY --from=builder /opt/krb5/* /var/kerberos/krb5kdc/
COPY --from=builder /opt/airflow/requirements.txt /opt/airflow/requirements.txt



# 4. Consolidate Environment Variables
ENV HADOOP_HOME=/opt/hadoop \
    SPARK_HOME=/opt/spark \
    HIVE_HOME=/opt/hive \
    AIRFLOW_HOME=/opt/airflow \
    AIRFLOW_CONFIG=/opt/airflow/config/airflow.cfg \
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
    KYUUBI_HOME=/opt/kyuubi \
    KYUUBI_CONF_DIR=/opt/kyuubi/conf \
    PATH=/opt/hadoop/bin:/opt/hadoop/sbin:/opt/spark/bin:/opt/spark/sbin:/opt/hive/bin:/opt/kyuubi/bin:/opt/airflow/venv/bin:$PATH

# 5. Consolidated User & Directory Logic
RUN groupadd hadoop && \
    usermod -aG hadoop root && echo "root:root" | chpasswd && \
    for user in yarn hdfs mapred spark hive airflow; do \
        useradd -m -g hadoop $user && \
        echo "$user:$user" | chpasswd && \
        usermod -aG wheel $user; \
    done && \
    # Ensure the wheel group (sudoers) requires a password for security
    echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers && \
    mkdir -p /var/kerberos/logs /var/data/hadoop/keytabs /var/data/hadoop/hdfs/nn \
             /var/data/hadoop/hdfs/snn /var/data/hadoop/hdfs/dn /var/data/hadoop/logs \
             /var/data/hadoop/pid /var/data/hadoop/work /var/data/hadoop/tmp /var/data/hadoop/hive/local \
             /var/data/hadoop/hive/resources /var/data/hadoop/hive/operationlog \
             /var/data/hadoop/hive/logs /workspace \
             /opt/airflow/{logs,dags,plugins,config} && \
    chown root:hadoop /var/data/hadoop/keytabs && chmod 750 /var/data/hadoop/keytabs && \
    chown -R hdfs:hadoop /var/data/hadoop/hdfs && \
    chown -R yarn:hadoop /var/data/hadoop/logs /var/data/hadoop/pid /var/data/hadoop/work /var/data/hadoop/tmp && \
    chmod -R 775 /var/data/hadoop/logs /var/data/hadoop/pid /var/data/hadoop/work /var/data/hadoop/tmp && \
    chown -R hive:hadoop /var/data/hadoop/hive /opt/hive && \
    chmod -R 775 /var/data/hadoop/hive && \
    chown -R spark:hadoop /opt/kyuubi && \
    chmod -R 775 /opt/airflow && \
    chown -R airflow:hadoop /opt/airflow


# 6. Final Profile setup (Exact strings from original)
RUN echo 'export HADOOP_HOME=/opt/hadoop' >> /etc/profile && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /etc/profile && \
    echo 'export SPARK_HOME=/opt/spark' >> /etc/profile && \
    echo 'export AIRFLOW_HOME=/opt/airflow' >> /etc/profile && \
    echo 'export AIRFLOW_CONFIG=/opt/airflow/config/airflow.cfg' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-jdk/jre' >> /etc/profile && \
    echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native' >> /etc/profile && \
    echo 'export HIVE_HOME=/opt/hive' >> /etc/profile && \
    echo 'export HIVE_CONF_DIR=$HIVE_HOME/conf' >> /etc/profile && \
    echo 'export POSTGRES_HOST=metastore' >> /etc/profile && \
    echo 'export POSTGRES_DB=metastore' >> /etc/profile && \
    echo 'export POSTGRES_USER=hive' >> /etc/profile && \
    echo 'export POSTGRES_PASSWORD=hive' >> /etc/profile && \
    echo 'export KRB5_CONFIG=/etc/krb5.conf' >> /etc/profile && \
    echo 'export KYUUBI_HOME=/opt/kyuubi' >> /etc/profile && \
    echo 'export KYUUBI_CONF_DIR=/opt/kyuubi/conf' >> /etc/profile && \
    echo "export PYSPARK_PYTHON=/usr/bin/python3">> /etc/profile && \
    echo "export PYSPARK_DRIVER_PYTHON=/usr/bin/python3">> /etc/profile && \
    echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:$KYUUBI_HOME/bin:$AIRFLOW_HOME/venv/bin:$PATH:/usr/local/bin' >> /etc/profile

# 7. Secure Airflow Installation with Constraints
# Switch to airflow user so the venv is owned by the correct user, not root.
USER airflow
WORKDIR /opt/airflow

RUN python3 -m venv venv && \
    venv/bin/pip install --upgrade pip wheel && \
    CONSTRAINT_URL="https://raw.githubusercontent.com/apache/airflow/constraints-${AIRFLOW_VERSION}/constraints-${PYTHON_VERSION}.txt" && \
    # venv/bin/pip install "apache-airflow==${AIRFLOW_VERSION}" --constraint "${CONSTRAINT_URL}" && \
    venv/bin/pip install -r /opt/airflow/requirements.txt --constraint "${CONSTRAINT_URL}"

USER spark

RUN mise use -g python@3.11

WORKDIR /workspace