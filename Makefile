.PHONY: serve build help

serve: ## Start Hugo in serve mode
	@hugo serve -D

build: ## Delete old build and make a new one
	@hugo --minify --cleanDestinationDir

help: ## Show this help
	@grep -Ei '^[a-z-]+\:\s##\s' Makefile | sort | awk 'BEGIN {FS = ": ## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'