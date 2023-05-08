#!/usr/bin/make -f

.PHONY: deploy
deploy: deploy-candb deploy-backend deploy-frontend

.PHONY: deploy-candb
deploy-candb:
	cd hello-candb && dfx deploy index --network http://localhost:8000

.PHONY: deploy-backend
deploy-backend:
	dfx deploy backend

.PHONY: deploy-frontend
deploy-frontend:
	dfx deploy frontend
