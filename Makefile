ENV_FILE_PATH ?= .env
ifneq ($(wildcard ${ENV_FILE_PATH}),)
	include $(ENV_FILE_PATH)
endif

.PHONY: serve build optimize-photos platinum platinum-archive platinum-og help

serve: ## Start Hugo in serve mode
	@hugo serve -D

build: ## Delete old build and make a new one
	@$(MAKE) optimize-photos
	@$(MAKE) fetch-data-platinum
	@hugo --minify --cleanDestinationDir

optimize-photos: ## Optimize photos for web (resize, strip EXIF, rename to UUIDv7)
	@command -v exiftool >/dev/null 2>&1 || { echo "Error: exiftool not found. Install with: brew install exiftool"; exit 1; }
	@for f in static/photos/*.jpg static/photos/*.jpeg static/photos/*.JPG; do \
		[ -f "$$f" ] || continue; \
		width=$$(sips -g pixelWidth "$$f" | tail -1 | awk '{print $$2}'); \
		if [ "$$width" -gt 1600 ]; then \
			echo "Resizing: $$f ($${width}px -> 1600px)"; \
			sips --resampleWidth 1600 "$$f" >/dev/null 2>&1; \
		fi; \
		if exiftool -all= -overwrite_original "$$f" 2>/dev/null | grep -q "1 image files updated"; then \
			echo "Stripped EXIF: $$f"; \
		fi; \
	done
	@for f in static/photos/*.jpg static/photos/*.jpeg static/photos/*.JPG; do \
		[ -f "$$f" ] || continue; \
		base=$$(basename "$$f"); \
		name="$${base%.*}"; \
		ext="$${base##*.}"; \
		if echo "$$name" | grep -qE '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$$'; then \
			continue; \
		fi; \
		new_uuid=$$(python3 -c "import time,random;t=int(time.time()*1000);r=random.getrandbits(74);u=(t<<80)|(7<<76)|((r>>62)<<64)|(2<<62)|(r&((1<<62)-1));h=f'{u:032x}';print(f'{h[:8]}-{h[8:12]}-{h[12:16]}-{h[16:20]}-{h[20:]}')"); \
		new_file="$$new_uuid.$$(echo $$ext | tr 'A-Z' 'a-z')"; \
		echo "Renaming: $$base -> $$new_file"; \
		mv "static/photos/$$base" "static/photos/$$new_file"; \
		python3 -c "import json;p='data/photos.json';d=json.load(open(p));d['$$new_file']=d.pop('$$base',None);f=open(p,'w');json.dump(d,f,indent=2);f.write(chr(10));f.close()"; \
	done
	@echo "Done."

fetch-data-platinum: ## Fetch data and static related to platinum
	@cp $(PLATINUM_DATA_LOCATION)/platinum.json ./data/platinum.json
	@cp $(PLATINUM_DATA_LOCATION)/platinum_og.png ./static/platinum_og.png

help: ## Show this help
	@grep -Ei '^[a-z-]+\:\s##\s' Makefile | sort | awk 'BEGIN {FS = ": ## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'
