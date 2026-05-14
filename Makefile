APP_NAME := Screen Cursor
EXECUTABLE_NAME := ScreenCursor
BUILD_DIR := build
DIST_DIR := dist
APP_BUNDLE := $(BUILD_DIR)/$(APP_NAME).app
EXECUTABLE := $(APP_BUNDLE)/Contents/MacOS/$(EXECUTABLE_NAME)
SOURCES := Sources/ScreenCursor/main.swift
INFO_PLIST := Resources/Info.plist
VERSION := $(shell /usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$(INFO_PLIST)")
ZIP_NAME := Screen-Cursor-$(VERSION).zip
ZIP_PATH := $(DIST_DIR)/$(ZIP_NAME)

.PHONY: all clean dist run icon

all: $(SOURCES) $(INFO_PLIST)
	mkdir -p "$(APP_BUNDLE)/Contents/MacOS" "$(APP_BUNDLE)/Contents/Resources"
	swiftc -O -target arm64-apple-macos13.0 -framework Cocoa -framework Carbon "$(SOURCES)" -o "$(EXECUTABLE)"
	cp "$(INFO_PLIST)" "$(APP_BUNDLE)/Contents/Info.plist"
	cp "Resources/AppIcon.icns" "$(APP_BUNDLE)/Contents/Resources/"

dist: clean all
	mkdir -p "$(DIST_DIR)"
	ditto -c -k --keepParent "$(APP_BUNDLE)" "$(ZIP_PATH)"
	shasum -a 256 "$(ZIP_PATH)"

run: all
	open "$(APP_BUNDLE)"

icon:
	swift scripts/generate_icon.swift
	iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns
	rm -rf Resources/AppIcon.iconset

clean:
	rm -rf "$(BUILD_DIR)" "$(DIST_DIR)"
