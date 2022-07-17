export UID_GID=$(shell id -u):$(shell id -g)

help:		## Show this help.
	@sed -ne '/@sed/!s/## //p' $(MAKEFILE_LIST)

up: 		## Up
	docker compose -f docker-compose.yaml up --force-recreate -d

down: 		## Down
	docker compose -f docker-compose.yaml down

logs:		## Show logs
	docker compose -f docker-compose.yaml logs -f

login:		## login db
	docker compose -f docker-compose.yaml exec db /bin/bash

clean: 		## clean
clean: down
	rm -rf mysql/data/*

mysql-client:	## connet mysql from mysql cli
	docker compose -f docker-compose.yaml exec db /bin/bash -c "mysql -u root -p -D db"



