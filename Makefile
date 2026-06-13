APP = SaunaBar.app
DMG = SaunaBar.dmg
BINARY = .build/release/SaunaBar
RESOURCES = $(APP)/Contents/Resources

# Code signing identity. Defaults to ad-hoc signing ("-") so anyone can build
# locally without an Apple Developer account. To produce a distributable,
# notarizable build, override with your Developer ID, e.g.:
#   make install SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)"
SIGN_IDENTITY ?= -

# notarytool keychain profile, created once with:
#   xcrun notarytool store-credentials <profile> --apple-id ... --team-id ... --password ...
NOTARY_PROFILE ?=

.PHONY: build test install run package dmg release clean

build:
	swift build -c release

test:
	swift test

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

# Package the already-built app into a compressed .dmg (no rebuild, so a
# stapled notarization ticket on the app is preserved).
package:
	rm -rf .dmg-staging "$(DMG)"
	mkdir -p .dmg-staging
	cp -R "$(APP)" .dmg-staging/
	ln -s /Applications .dmg-staging/Applications
	hdiutil create -volname SaunaBar -srcfolder .dmg-staging -ov -format UDZO "$(DMG)"
	rm -rf .dmg-staging

# Convenience: build + sign the app, then package it.
dmg: install package

# Full notarized release: build & sign the app, notarize and staple it,
# package it into a .dmg, then notarize and staple the .dmg.
# Requires a Developer ID signature and a notarytool keychain profile:
#   make release SIGN_IDENTITY="Developer ID Application: ... (TEAMID)" NOTARY_PROFILE=my-profile
release: install
	@test -n "$(NOTARY_PROFILE)" || { echo "error: set NOTARY_PROFILE=<notarytool keychain profile>"; exit 1; }
	ditto -c -k --keepParent "$(APP)" "$(APP).zip"
	xcrun notarytool submit "$(APP).zip" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(APP)"
	rm -f "$(APP).zip"
	$(MAKE) package
	codesign --force --timestamp --sign "$(SIGN_IDENTITY)" "$(DMG)"
	xcrun notarytool submit "$(DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	xcrun stapler staple "$(DMG)"

clean:
	swift package clean
	rm -rf .build .dmg-staging "$(DMG)"
