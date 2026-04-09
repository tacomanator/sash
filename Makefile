APP_NAME = Sash
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app

BUNDLE_ID = com.sash.app

.PHONY: build bundle install dist reset-permissions clean run

build:
	swift build -c release

bundle: build
	rm -rf $(APP_BUNDLE)
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp Resources/AppIcon.icns $(APP_BUNDLE)/Contents/Resources/
	codesign --force --sign - $(APP_BUNDLE)

install: bundle reset-permissions
	cp -r $(APP_BUNDLE) /Applications/

reset-permissions:
	-tccutil reset Accessibility $(BUNDLE_ID) 2>/dev/null

dist: bundle
	rm -f $(APP_NAME).zip
	ditto -c -k --keepParent $(APP_BUNDLE) $(APP_NAME).zip

clean:
	swift package clean
	rm -rf $(APP_BUNDLE) $(APP_NAME).zip

run: bundle
	open $(APP_BUNDLE)
