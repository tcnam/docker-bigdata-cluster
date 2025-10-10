FROM ubuntu:16.04

ENV DEBIAN_FRONTEND=noninteractive
# ENV JAVA_DEBIAN_VERSION=8u111-b14-2~bpo8+1

# Install dependencies
RUN apt-get update && \
    apt-get install -y openjdk-8-jdk && \
    apt-get install -y openjdk-8-jre && \
    apt-get install -y wget && \
    apt-get install -y curl && \
    # apt-get install -y python3 && \
    # apt-get install -y python3-dev &&\
    # apt-get install -y python3-pip && \
    apt-get install -y net-tools && \
    apt-get install -y netcat && \
    apt-get install -y gnupg && \
    apt-get install -y libsnappy-dev && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ARG ARCHITECTURE=amd64
ENV ARCHITECTURE=$ARCHITECTURE

COPY baseimage/files/ /opt/
# COPY baseimage/3rdjars/ /opt/3rdjars/

RUN mv /usr/lib/jvm/java-8-openjdk-${ARCHITECTURE} /usr/lib/jvm/java-8-openjdk
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk
ENV PATH=$JAVA_HOME/bin:$PATH

# Setup user for hadoop cluster
RUN groupadd hadoop && \
    useradd -m -g hadoop yarn    && echo "yarn:yarn"     | chpasswd && \
    useradd -m -g hadoop hdfs    && echo "hdfs:hdfs"     | chpasswd && \
    useradd -m -g hadoop mapred  && echo "mapred:mapred" | chpasswd && \
    useradd -m -g hadoop spark   && echo "spark:spark"   | chpasswd && \
    useradd -m -g hadoop hive    && echo "hive:hive"     | chpasswd && \
    useradd -m -g hadoop tez    && echo "tez:tez"     | chpasswd

# Create necessary dir
RUN mkdir -p /var/data/hadoop/hdfs/nn && \
    mkdir -p /var/data/hadoop/hdfs/snn && \
    mkdir -p /var/data/hadoop/hdfs/dn && \
    mkdir -p /var/data/hadoop/hdfs/logs && \
    chmod -R 775 /var/data/hadoop/hdfs/logs && \
    chown -R hdfs:hadoop /var/data/hadoop/hdfs
RUN mkdir -p /var/data/hadoop/hive/tmp/local && \
    mkdir -p /var/data/hadoop/hive/tmp/resources && \
    mkdir -p /var/data/hadoop/hive/tmp/querylog && \
    mkdir -p /var/data/hadoop/hive/tmp/operationlog && \
    mkdir -p /var/data/hadoop/hive/tmp/logs && \
    chmod -R 777 /var/data/hadoop/hive/tmp && \
    chown -R hive:hadoop /var/data/hadoop/hive/tmp


# RUN mkdir -p /var/data/hadoop/logs
# RUN chmod 775 /var/data/hadoop/logs
# RUN chown -R yarn:hadoop /var/data/hadoop/logs

#Setup Hadoop related environment variables
ENV HDFS_NAMENODE_USER=hdfs
ENV HDFS_DATANODE_USER=hdfs
ENV HDFS_SECONDARYNAMENODE_USER=hdfs
ENV YARN_RESOURCEMANAGER_USER=yarn
ENV YARN_NODEMANAGER_USER=yarn

# Install Hadoop
ARG HADOOP_VERSION=3.3.6
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    rm /opt/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH


# Install Spark
ARG SPARK_VERSION=3.3.4
RUN tar -zxvf /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13 /opt/spark && \
    rm /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz 

ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH
ENV LD_LIBRARY_PATH=$HADOOP_HOME/lib/native:$LD_LIBRARY_PATH
# ENV PYSPARK_PYTHON=python3
# ENV PYSPARK_PATH=usr/bin/python3
# ENV PATH=$PYSPARK_PATH/bin:$PATH

# Install Hive
ARG HIVE_VERSION=3.1.3
RUN tar -xvzf /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-${HIVE_VERSION}-bin /opt/hive && \
    rm /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
    chown -R hive:hadoop /opt/hive

ENV HIVE_HOME=/opt/hive
ENV HIVE_CONF_DIR=${HIVE_HOME}/conf

# RUN keytool -genkeypair -alias hiveserver2 -keyalg RSA -keysize 2048 -keystore $HIVE_CONF_DIR/hiveserver2.jks -validity 365

ENV POSTGRES_HOST=metastore
ENV POSTGRES_DB=metastore
ENV POSTGRES_USER=hive
ENV POSTGRES_PASSWORD=hive

ENV PATH=$HIVE_HOME/bin:$PATH

# Install Tez
ARG TEZ_VERSION=0.10.2
RUN tar -xvzf /opt/apache-tez-${TEZ_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-tez-${TEZ_VERSION}-bin /opt/tez && \
    rm /opt/apache-tez-${TEZ_VERSION}-bin.tar.gz && \
    # rm -f $TEZ_HOME/lib/hadoop-*.jar && \
    tar zcvf /opt/tez.tar.gz -C /opt tez && \
    chown -R tez:hadoop /opt/tez

ENV TEZ_HOME=/opt/tez
ENV TEZ_CONF_DIR=${TEZ_HOME}/conf
ENV TEZ_JARS=${TEZ_HOME}

ENV HADOOP_CLASSPATH="\
$HADOOP_HOME/share/hadoop/common/*:\
$HADOOP_HOME/share/hadoop/common/lib/*:\
$HADOOP_HOME/share/hadoop/hdfs/*:\
$HADOOP_HOME/share/hadoop/mapreduce/*:\
$HADOOP_HOME/share/hadoop/yarn/*:\
# $SPARK_HOME/jars/*:\
$HIVE_HOME/lib/*:\
${TEZ_HOME}/*:${TEZ_CONF_DIR}"

# ENV HADOOP_CLASSPATH=${HADOOP_CLASSPATH}:${TEZ_HOME}/*:${TEZ_CONF_DIR}


RUN echo 'export HADOOP_HOME=/opt/hadoop' >> /etc/profile && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /etc/profile && \
    echo 'export SPARK_HOME=/opt/spark' >> /etc/profile && \
    echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk' >> /etc/profile && \
    # echo 'export PYSPARK_PATH=usr/bin/python3' >> /etc/profile && \
    echo 'export LD_LIBRARY_PATH=$HADOOP_HOME/lib/native' >> /etc/profile && \
    echo 'export HIVE_HOME=/opt/hive' >> /etc/profile && \
    echo 'export HIVE_CONF_DIR=$HIVE_HOME/conf' >> /etc/profile && \
    echo 'export POSTGRES_HOST=metastore' >> /etc/profile && \
    echo 'export POSTGRES_DB=metastore' >> /etc/profile && \
    echo 'export POSTGRES_USER=hive' >> /etc/profile && \
    echo 'export POSTGRES_PASSWORD=hive' >> /etc/profile && \
    echo 'export TEZ_HOME=/opt/tez' >> /etc/profile && \
    echo 'export TEZ_CONF_DIR=$TEZ_HOME/conf' >> /etc/profile && \
    echo 'export TEZ_JARS=$TEZ_HOME' >> /etc/profile && \
    echo 'export HADOOP_CLASSPATH=$HADOOP_CLASSPATH' >> /etc/profile && \
    echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$SPARK_HOME/bin:$SPARK_HOME/sbin:$HIVE_HOME/bin:$PATH' >> /etc/profile


# Setup for edge node
RUN mkdir /workspace

# Install Python libraries
# COPY baseimage/requirements.txt /requirements.txt
# RUN pip install -r /requirements.txt


