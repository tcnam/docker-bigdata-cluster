# Hadoop framework components:

## 1.Hadoop common

Overview:
    - Common packages cho các components khác

## 2.HDFS

Overview:
    - Distributed file system

## 3.Hadoop Yarn

Overview:
    - Framework phụ trách việc schedule jobs và manage resources

## 4.Hadoop MapReduce

Overview:
    - Framework sử lý song song


# Công việc của một Hadoop admin

## 1. Quản lý storage

## 2. Allocate resource for jobs

Thuật toán Fair Scheduler

Thuật toán Dominant Resource Fairness

Thuật toán Capacity Scheduler

## 3. Bảo vệ data

Authentication:
    - Kerberos

Authorization:
    - Apache Sentry
    - Apache Ranger
    - Apache Knox

# Kiến trúc của Hadoop

Data Storage (HDFS):

Data Processing (YARN):


# Cài đặt hadoop

## 1. Các thư mục cần nắm:


### 1.1 Các thư mục 

3rd jars:
- delta-spark_2.12-3.3.2
- delta-storage-3.3.2
- spark-connect_2.12-3.5.5
- spark-connect-common_2.12-3.5.5

### Kerberos

2 main config files:
-  krb5.conf: 
    - client config
    - /etc/krb5.conf
- kdc.conf :
    - server config
    -  /var/Kerberos/krb5kdc/kdc.conf
- kadm5.acl:
    - /var/krb5kdc

Resource Config Values:
- Docker compose:
    - namenode: 1536M
    - 





