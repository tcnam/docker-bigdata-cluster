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
    # apt-get install -y python3-dev && \
    # apt-get install -y python3-pip && \
    apt-get install -y net-tools && \
    apt-get install -y netcat && \
    apt-get install -y gnupg && \
    apt-get install -y libsnappy-dev && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME environment variable
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-arm64
ENV PATH=$JAVA_HOME/bin:$PATH

# Setup user for hadoop cluster
RUN groupadd hadoop
RUN useradd -g hadoop yarn
RUN useradd -g hadoop hdfs
RUN useradd -g hadoop mapred

# Create necessary dir
RUN mkdir -p /var/data/hadoop/hdfs/nn
RUN mkdir -p /var/data/hadoop/hdfs/snn
RUN mkdir -p /var/data/hadoop/hdfs/dn
RUN mkdir -p /var/data/hadoop/hdfs/logs

RUN chmod 777 /var/data/hadoop/hdfs/logs
RUN chown hdfs:hadoop /var/data/hadoop/hdfs

RUN mkdir -p /var/data/hadoop/logs
RUN chmod 755 /var/data/hadoop/logs
RUN chown yarn:hadoop /var/data/hadoop/logs

#Setup Hadoop related environment variables
ENV HDFS_NAMENODE_USER=hdfs
ENV HDFS_DATANODE_USER=hdfs
ENV HDFS_SECONDARYNAMENODE_USER=hdfs
ENV YARN_RESOURCEMANAGER_USER=yarn
ENV YARN_NODEMANAGER_USER=yarn

# Install Hadoop
COPY ./files/ /opt/
ARG HADOOP_VERSION=3.2.0
RUN tar -xvzf /opt/hadoop-${HADOOP_VERSION}.tar.gz -C /opt && \
    mv /opt/hadoop-${HADOOP_VERSION} /opt/hadoop && \
    rm /opt/hadoop-${HADOOP_VERSION}.tar.gz
ENV HADOOP_HOME=/opt/hadoop
ENV PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH

RUN echo 'export HADOOP_HOME=/opt/hadoop' >> /etc/profile && \
    echo 'export HADOOP_CONF_DIR=$HADOOP_HOME/etc/hadoop' >> /etc/profile && \
    echo 'export PATH=$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH' >> /etc/profile


# Install Python libraries
# COPY ./requirements.txt /requirements.txt
# RUN pip install -r requirements.txt


