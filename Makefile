#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-us

# .PHONY: deploy-candb
# deploy-candb:
# 	cd hello-candb && dfx deploy index --network http://localhost:8080

.PHONY: deploy-us
deploy-us:
	dfx deploy
