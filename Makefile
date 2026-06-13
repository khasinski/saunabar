APP = SaunaBar.app
BINARY = .build/release/SaunaBar
RESOURCES = $(APP)/Contents/Resources

# Code signing identity. Defaults to ad-hoc signing ("-") so anyone can build
# locally without an Apple Developer account. To produce a distributable,
# notarizable build, override with your Developer ID, e.g.:
#   make install SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
SIGN_IDENTITY ?= -

.PHONY: build install run clean

build:
	swift build -c release

install: build
	mkdir -p $(RESOURCES) $(APP)/Contents/MacOS
	cp $(BINARY) $(APP)/Contents/MacOS/SaunaBar
	cp Assets/SaunaBar.icns $(RESOURCES)/SaunaBar.icns
	codesign --force --deep \
		--sign "$(SIGN_IDENTITY)" \
		--options runtime \
		--entitlements SaunaBar.entitlements \
		$(APP)

run: install
	pkill -x SaunaBar 2>/dev/null || true
	sleep 0.5
	open $(APP)

clean:
	swift package clean
	rm -rf .build
