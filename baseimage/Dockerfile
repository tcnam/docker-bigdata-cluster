FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && \
    apt-get install -y openjdk-11-jdk && \
    apt-get install -y wget && \
    apt-get install -y curl && \
    apt-get install -y python3 && \
    apt-get install -y python3-dev && \
    apt-get install -y python3-pip && \
    apt-get install -y net-tools && \
    apt-get install -y netcat && \
    apt-get install -y gnupg && \
    apt-get install -y libsnappy-dev && \
    apt-get install -y zip && \
    apt-get install -y unzip && \
    apt-get install -y sudo && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

COPY ./files/ /opt/

# Create different user for different use case
RUN groupadd hadoop && \
    useradd -m -g hadoop yarn && \
    useradd -m -g hadoop hdfs && \
    useradd -m -g hadoop mapred && \
    useradd -m -g hadoop hive && \
    useradd -m -g hadoop spark

# Install Hadoop
ARG HADOOP_VERSION=3.3.6
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    rm /opt/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH



#Setup Hadoop related environment variables
ENV HDFS_NAMENODE_USER=hdfs
ENV HDFS_DATANODE_USER=hdfs
ENV HDFS_SECONDARYNAMENODE_USER=hdfs
ENV YARN_RESOURCEMANAGER_USER=yarn
ENV YARN_NODEMANAGER_USER=yarn

ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop

#Create necessary dir for hadoop
RUN mkdir -p ${HADOOP_HOME}/data/namenode && \
    mkdir -p ${HADOOP_HOME}/data/secondarynamenode && \
    mkdir -p ${HADOOP_HOME}/data/datanode && \
    mkdir -p ${HADOOP_HOME}/data/logs && \
    mkdir -p ${HADOOP_HOME}/data/tmp && \
    mkdir -p ${HADOOP_HOME}/yarn/logs

RUN chmod 755 ${HADOOP_HOME}/data && \
    chmod 755 ${HADOOP_HOME}/bin && \
    chmod 755 ${HADOOP_HOME}/sbin && \
    chown hdfs:hadoop ${HADOOP_HOME}/data && \
    chmod 755 ${HADOOP_HOME}/yarn/logs && \
    chown yarn:hadoop ${HADOOP_HOME}/yarn/logs
 

# # Install Spark
ARG SPARK_VERSION=3.4.4
RUN tar -zxvf /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz -C /opt && \
    mv /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13 /opt/spark && \
    rm /opt/spark-${SPARK_VERSION}-bin-hadoop3-scala2.13.tgz 
ENV SPARK_HOME=/opt/spark
ENV PATH=$SPARK_HOME/bin:$SPARK_HOME/sbin:$PATH

#Setup Spark related environment variables
ENV SPARK_MASTER="spark://spark-yarn-master:7077"
ENV SPARK_MASTER_HOST=master
ENV SPARK_MASTER_HOST=7077
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_PATH=/usr/bin/python3


# Add Hadoop native library path to the dynamic link library path
ENV LD_LIBRARY_PATH="$HADOOP_HOME/lib/native:${LD_LIBRARY_PATH}"

RUN mkdir -p $SPARK_HOME/spark_logs && \
    mkdir -p /workspace


# Install Hive
ARG HIVE_VERSION=3.1.3
RUN tar -xvzf /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-${HIVE_VERSION}-bin /opt/hive && \
    rm /opt/apache-hive-${HIVE_VERSION}-bin.tar.gz
ENV HIVE_HOME=/opt/hive
ENV PATH=$HIVE_HOME/bin:$PATH

# Install Livy
# ARG LIVY_VERSION=0.8.0
RUN unzip /opt/apache-livy-0.8.0-incubating_2.12-bin.zip -d /opt && \
    mv /opt/apache-livy-0.8.0-incubating_2.12-bin /opt/livy && \
    rm /opt/apache-livy-0.8.0-incubating_2.12-bin.zip
ENV LIVY_HOME=/opt/livy
ENV PATH=$LIVY_HOME/bin:$PATH

ENV LIVY_LOG_DIR=/var/log/livy
ENV LIVY_PID_DIR=/var/run/livy

RUN mkdir -p $LIVY_LOG_DIR && \
    mkdir -p $LIVY_PID_DIR

# Install Python libraries
COPY ./requirements.txt /requirements.txt
RUN pip install -r requirements.txt

# RUN chmod u+x $SPARK_HOME/sbin/* && \
#     chmod u+x $SPARK_HOME/bin/* && \
#     chmod u+x $HADOOP_HOME/sbin/* && \
#     chmod u+x $HADOOP_HOME/bin/*

RUN chmod u+rwx $SPARK_HOME/sbin/* && \
    chmod u+rwx $SPARK_HOME/bin/* && \
    chmod u+rwx $HADOOP_HOME/sbin/* && \
    chmod u+rwx $HADOOP_HOME/bin/* && \
    chmod u+rwx $HIVE_HOME/bin/* 

# # Set working directory
# WORKDIR /workspace


