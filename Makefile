.DEFAULT_GOAL := all

PACKAGE_NAME    := BetterTeleportUIs
VERSION         := 1.0.0

BASE_DIR    := $(dir $(abspath $(firstword $(MAKEFILE_LIST))))
SOURCE_DIR  := $(BASE_DIR)plugin
BUILD_DIR   := $(BASE_DIR)build

ZIP_FILE    := $(BUILD_DIR)/$(PACKAGE_NAME)_$(VERSION).zip

.PHONY: all package

all:
	@echo "Available goals: package"

$(BUILD_DIR):
	@mkdir -p "$@"

$(ZIP_FILE): | $(BUILD_DIR)
	@cd "$(SOURCE_DIR)" && \
		zip -qr -FS "$@" .

package: $(ZIP_FILE)
