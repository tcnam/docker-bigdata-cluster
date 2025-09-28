create_dir:
	mkdir .\services\namenode .\services\secondarynamenode .\services\resourcemanager .\services\worker1 .\services\worker2 .\services\worker3 .\services\historyserver .\services\metastore .\services\hiveserver2 

delete_dir:
	rmdir /S /Q .\services\namenode .\services\secondarynamenode .\services\resourcemanager .\services\worker1 .\services\worker2 .\services\worker3 .\services\historyserver .\services\metastore .\services\hiveserver2

gen_jks:
	keytool -genkeypair \
		-alias hiveserver2 \
		-keyalg RSA \
		-storetype JKS \
		-keysize 2048 \
		-validity 365 \
		-keystore ./conf/hive/hiveserver2.jks \
		-storepass hiveserver2 \
		-keypass hiveserver2 \
		-ext SAN=IP:100.84.28.115,DNS:hiveserver2 \
		-dname "CN=hive.local, OU=Data, O=MyOrg, L=HCM, ST=VN, C=VN"
	
	keytool -export \
			-alias hiveserver2 \
			-keystore ./conf/hive/hiveserver2.jks \
			-file ./conf/hive/server.crt \
			-storepass hiveserver2

	keytool -import \
			-alias hiveserver2 \
			-file ./conf/hive/server.crt \
			-keystore ./conf/hive/truststore.jks \
			-storepass hiveserver2

		
rebuild_new_image:
	docker image rm hadoop_base:1.0
	docker buildx build --file ./baseimage/Dockerfile --no-cache --platform linux/amd64 --build-arg ARCHITECTURE=amd64 -t hadoop_base:1.0 .

rebuild_image:
	docker buildx build --file ./baseimage/Dockerfile --no-cache --platform linux/amd64 --build-arg ARCHITECTURE=amd64 -t hadoop_base:1.0 .

start_cluster:
	docker compose -f docker-compose-cluster.yml -p cluster up

start_cluster_d:
	docker compose -f docker-compose-cluster.yml -p cluster up -d

stop_cluster:
	docker compose -p cluster down -v

start_client:
	docker compose -f docker-compose-client.yml -p client up

stop_client:
	docker compose -p client down -v