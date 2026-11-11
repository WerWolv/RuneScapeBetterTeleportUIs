.DEFAULT_GOAL := all

PACKAGE_NAME    := BetterTeleportUIs
VERSION         := 1.0.0
PREVIEW         := 1

BASE_DIR    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SOURCE_DIR  := $(BASE_DIR)plugin
BUILD_DIR   := $(BASE_DIR)build
STAGE_DIR   := $(BUILD_DIR)/package

SOURCE_FILES := $(shell find $(SOURCE_DIR) -type f)
PACKAGE_DOCS := $(BASE_DIR)README.md $(BASE_DIR)LICENSE.md

ifeq ($(PREVIEW),1)
	VERSION_FULL := $(VERSION)-WIP
else
	VERSION_FULL := $(VERSION)
endif

OUTPUT_NAME  := $(PACKAGE_NAME)_$(VERSION_FULL).zip
ZIP_FILE     := $(BUILD_DIR)/$(OUTPUT_NAME)
STUBS_PATH   := $(BUILD_DIR)/stubs
LUACHECK     ?= luacheck

.PHONY: all package stubs check

all:
	@echo "Available goals: package, stubs, check"

$(BUILD_DIR):
	@mkdir -p "$@"

$(ZIP_FILE):$(SOURCE_FILES) $(PACKAGE_DOCS) $(BASE_DIR)/Makefile | $(BUILD_DIR)
	@rm -rf "$(STAGE_DIR)"
	@cp -a "$(SOURCE_DIR)/." "$(STAGE_DIR)/"

	@cd "$(STAGE_DIR)" && \
		zip -qr -FS "$@" .
	@echo "Packaged plugin into $(OUTPUT_NAME)"

package: $(ZIP_FILE)

stubs:
	@rm -rf $(STUBS_PATH)
	@git clone https://github.com/FriendlyDevelopment/runescape-api-stubs $(STUBS_PATH)
	@jq '."workspace.library" = [ "$(STUBS_PATH)/types.lua", "$(STUBS_PATH)/generated/" ]' $(STUBS_PATH)/.luarc.json > $(BASE_DIR)/.luarc.json

check:
	@$(LUACHECK) --config "$(BASE_DIR).luacheckrc" "$(SOURCE_DIR)"
