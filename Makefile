# Ninjasaurus build helpers. The Xcode project is generated from project.yml.
#
#   make project    generate Ninjasaurus.xcodeproj (needs `brew install xcodegen`)
#   make test       unit tests on the simulator
#   make run        build, install and launch on the simulator
#   make shot       screenshot of the booted simulator into .build/
#   make icon       regenerate the app icon PNG from the game's sprite art
#   make archive    Release archive (needs the Apple Distribution cert + profile)
#   make upload     upload the archive to TestFlight (needs API_KEY, API_KEY_ID, API_ISSUER)
#   make lsp        buildServer.json so Zed, VS Code and Neovim resolve types across files

SCHEME     := Ninjasaurus
PROJECT    := Ninjasaurus.xcodeproj
BUNDLE_ID  := dev.rbstp.ninjasaurus
SIM        ?= iPhone 17 Pro Max
DEST       := platform=iOS Simulator,name=$(SIM)
BUILD      := .build
DERIVED    := $(BUILD)/DerivedData
APP        := $(DERIVED)/Build/Products/Debug-iphonesimulator/Ninjasaurus.app
ARCHIVE    := $(BUILD)/Ninjasaurus.xcarchive
ICON       := Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
VERSION    ?= 0.1.0
BUILD_NUM  ?= 1

XCB := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -derivedDataPath $(DERIVED)

.PHONY: all project build test run shot icon archive upload lsp clean

all: test

project: $(PROJECT)

$(PROJECT): project.yml
	xcodegen generate

build: project
	$(XCB) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO build

test: project
	$(XCB) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO test

run: build
	xcrun simctl boot "$(SIM)" 2>/dev/null || true
	open -a Simulator
	xcrun simctl install booted "$(APP)"
	xcrun simctl launch booted $(BUNDLE_ID)

shot:
	@mkdir -p $(BUILD)
	xcrun simctl io booted screenshot "$(BUILD)/shot-$$(date +%H%M%S).png"

ICON_SOURCES := scripts/icon/main.swift \
	Sources/Ninjasaurus/Core/Geometry.swift Sources/Ninjasaurus/Core/GameConstants.swift Sources/Ninjasaurus/Core/SeededRandom.swift \
	Sources/Ninjasaurus/Core/GameEvent.swift Sources/Ninjasaurus/Levels/Tile.swift \
	Sources/Ninjasaurus/Rendering/PixelColor.swift Sources/Ninjasaurus/Rendering/PixelSprite.swift Sources/Ninjasaurus/Rendering/PixelCanvas.swift \
	Sources/Ninjasaurus/Rendering/PixelPainter.swift Sources/Ninjasaurus/Rendering/PixelFont.swift Sources/Ninjasaurus/Rendering/SpriteArt.swift \
	Sources/Ninjasaurus/Rendering/SpriteArt+Ninja.swift Sources/Ninjasaurus/Rendering/SpriteArt+Dinos.swift Sources/Ninjasaurus/Rendering/SpriteArt+Tiles.swift

icon:
	@mkdir -p $(BUILD)
	swiftc -O -o $(BUILD)/generate-icon $(ICON_SOURCES)
	$(BUILD)/generate-icon "$(ICON)"

archive: project
	$(XCB) -destination 'generic/platform=iOS' -configuration Release \
		-archivePath "$(ARCHIVE)" \
		MARKETING_VERSION="$(VERSION)" CURRENT_PROJECT_VERSION="$(BUILD_NUM)" archive

# API_KEY is the path to the App Store Connect .p8 file.
upload:
	@test -n "$(API_KEY)" -a -n "$(API_KEY_ID)" -a -n "$(API_ISSUER)" || { \
		echo "usage: make upload API_KEY=path/to/AuthKey.p8 API_KEY_ID=XXXX API_ISSUER=uuid"; exit 1; }
	xcodebuild -exportArchive -archivePath "$(ARCHIVE)" \
		-exportOptionsPlist scripts/ExportOptions.plist -exportPath "$(BUILD)/export" \
		-authenticationKeyPath "$(API_KEY)" -authenticationKeyID "$(API_KEY_ID)" \
		-authenticationKeyIssuerID "$(API_ISSUER)"

lsp: project
	@command -v xcode-build-server >/dev/null || { echo "brew install xcode-build-server"; exit 1; }
	xcode-build-server config -project $(PROJECT) -scheme $(SCHEME)
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -configuration Debug CODE_SIGNING_ALLOWED=NO build-for-testing

clean:
	rm -rf $(BUILD) $(PROJECT) buildServer.json
