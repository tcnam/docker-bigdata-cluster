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

# Install Hadoop
ARG HADOOP_VERSION=3.3.6
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    rm /opt/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH



#Setup Hadoop related environment variables
ENV HDFS_NAMENODE_USER=root
ENV HDFS_DATANODE_USER=root
ENV HDFS_SECONDARYNAMENODE_USER=root
ENV YARN_RESOURCEMANAGER_USER=root
ENV YARN_NODEMANAGER_USER=root

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


# # Install Hive
# ARG HIVE_VERSION=4.0.1
# RUN wget -q https://downloads.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz && \
#     tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz -C /opt && \
#     rm apache-hive-${HIVE_VERSION}-bin.tar.gz
# ENV HIVE_HOME=/opt/apache-hive-${HIVE_VERSION}-bin
# ENV PATH=$HIVE_HOME/bin:$PATH

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

RUN chmod u+x $SPARK_HOME/sbin/* && \
    chmod u+x $SPARK_HOME/bin/* && \
    chmod u+x $HADOOP_HOME/sbin/* && \
    chmod u+x $HADOOP_HOME/bin/*

# # Set working directory
# WORKDIR /workspace


