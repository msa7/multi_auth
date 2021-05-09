RUN := docker-compose run --rm
RUN_APP := $(RUN) app

help: ## This help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

setup: ## setup app
	docker-compose pull
	docker-compose build --force-rm app
	$(RUN_APP) shards install
l: ## linter
	$(RUN) -e MULTI_AUTH_ENV=test app bash -c "crystal tool format"
t: ## tests
	$(RUN) -e MULTI_AUTH_ENV=test app bash -c "crystal spec $(c)"
sh: ## shell into app container c="pwd"
	$(RUN_APP) $(or $(c),bash)
c: ## run console.cr
	$(RUN_APP) crystal run src/console.cr
update_dependency: ## update_dependency
	docker-compose build --force-rm --no-cache --pull
	$(RUN_APP) rm -rf /app/lib/*
	$(RUN_APP) shards update
