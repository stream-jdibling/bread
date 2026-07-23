
ifndef SERVER
$(error SERVER is not set)
endif

deploy:
	rsync -av --exclude='.git' . $(SERVER):~/bread/
	ssh $(SERVER) "cd ~/bread && docker compose up -d --build"
