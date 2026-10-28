.DEFAULT_GOAL := all

PACKAGE_NAME    := BetterTeleportUIs
VERSION         := 1.0.0

BASE_DIR    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SOURCE_DIR  := $(BASE_DIR)plugin
BUILD_DIR   := $(BASE_DIR)build

SOURCE_FILES := $(shell find $(SOURCE_DIR) -type f)
OUTPUT_NAME  := $(PACKAGE_NAME)_$(VERSION).zip
ZIP_FILE     := $(BUILD_DIR)/$(OUTPUT_NAME)

.PHONY: all package

all:
	@echo "Available goals: package"

$(BUILD_DIR):
	@mkdir -p "$@"

$(ZIP_FILE): $(SOURCE_FILES) | $(BUILD_DIR)
	@cd "$(SOURCE_DIR)" && \
		zip -qr -FS "$@" .
	@echo "Packaged plugin into $(OUTPUT_NAME)"

package: $(ZIP_FILE)
