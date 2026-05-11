DARKSTAR := darkstar

deploy:
	rsync -av --exclude='.git' . $(DARKSTAR):~/bread/
	ssh $(DARKSTAR) "cd ~/bread && docker compose up -d --build"
