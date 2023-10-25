BASE_PASTH=$(shell pwd)
FILE_NAME=$(shell date +%Y%m%d%H%M)

build-ui: clean
	git clone https://github.com/Joxit/docker-registry-ui.git ./source-ui
build-auth: clean
	git clone -b 1.11.0 https://github.com/cesanta/docker_auth ./source-auth
	docker run -it --rm --name build -v "${BASE_PASTH}/source-auth":/home -w /home/auth_server golang:1.21-alpine3.18 sh -c "apk add --no-cache ca-certificates make git gcc musl-dev binutils-gold openssl && make build"
	cp ./source-auth/auth_server/auth_server ./auth-server
publish: clean 
	zip -r w7_registry_${FILE_NAME}.zip ./Dockerfile nginx/default.conf start.sh
test:
	docker build -t cd-artifact:v1.0.0 .
	docker run -d -it --name cd-artifact-app -p 8081:80 -p 5001:5001 -p 5000:5000 -e ENABLE_PUBLIC_PULL=2 -e DOMAIN_URL=http://172.16.1.198:8081 cd-artifact:v1.0.0
	docker exec -it cd-artifact-app /bin/sh
test-clean:
	docker stop cd-artifact-app && docker rm cd-artifact-app && docker rmi cd-artifact:v1.0.0
clean:
	rm -rf ./source*