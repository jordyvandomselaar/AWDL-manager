APP := build/AWDLManager.app
APP_BIN := $(APP)/Contents/MacOS/AWDLManager
HELPER := build/awdl-helper

all: $(APP_BIN) $(HELPER)

$(HELPER): helper/awdl-helper.c
	mkdir -p build
	clang -O2 -Wall -Wextra -o $@ $<

$(APP_BIN): app/main.swift app/Info.plist
	mkdir -p $(APP)/Contents/MacOS
	cp app/Info.plist $(APP)/Contents/Info.plist
	swiftc -O -o $@ app/main.swift
	codesign --force --sign - $(APP)

install: all
	sudo scripts/helper.sh install
	scripts/app.sh install

uninstall:
	scripts/app.sh uninstall
	sudo scripts/helper.sh uninstall

clean:
	rm -rf build

.PHONY: all install uninstall clean
