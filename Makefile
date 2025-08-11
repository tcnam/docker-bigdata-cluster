create_dir:
	mkdir .\hadoop\namenode .\hadoop\secondarynamenode .\hadoop\resourcemanager .\hadoop\worker1 .\hadoop\worker2 .\hadoop\worker3 .\hadoop\historyserver

delete_dir:
	del -r ./hadoop/namenode ./hadoop/secondarynamenode ./hadoop/resourcemanager ./hadoop/worker1 ./hadoop/worker2 ./hadoop/worker3 ./hadoop/historyserver

rebuild_new_image:
	docker image rm hadoop_base:1.0
	docker buildx build --file ./baseimage/Dockerfile --no-cache --platform linux/amd64 --build-arg ARCHITECTURE=amd64 -t hadoop_base:1.0 .

rebuild_image:
	docker buildx build --file ./baseimage/Dockerfile --no-cache --platform linux/amd64 --build-arg ARCHITECTURE=amd64 -t hadoop_base:1.0 .

start_cluster:
	docker compose up 

stop_cluster:
	docker compose down -v