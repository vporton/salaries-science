#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-candb deploy-us

.PHONY: deploy-candb
deploy-candb:
	cd hello-candb && dfx deploy index --network http://localhost:8000

.PHONY: deploy-us
deploy-us:
	dfx deploy
