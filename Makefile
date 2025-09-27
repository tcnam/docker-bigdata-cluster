gen_jks:
	keytool -genkeypair \
		-alias hiveserver2 \
		-keyalg RSA \
		-storetype JKS \
		-keysize 2048 \
		-validity 365 \
		-keystore ./edge/config_hive/hiveserver2.jks \
		-storepass hiveserver2 \
		-keypass hiveserver2 \
		-ext SAN=IP:100.84.28.115,DNS:hiveserver2 \
		-dname "CN=hive.local, OU=Data, O=MyOrg, L=HCM, ST=VN, C=VN"
		
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