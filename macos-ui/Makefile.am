AUTOMAKE_OPTIONS = foreign

EXTRA_DIST = Docs \
             Installer \
             Moonshot \
             Moonshot.xcodeproj \
             moonshot_mac_util \
             MoonshotTests \
             MoonshotUITests \
             Uninstaller \
             filemanifest.txt

#  On macOS we use dbus_check.sh as the 'binary' for this package,
#  On Linux we just bundle it like the rest of the source

if !OS_MACOS
EXTRA_DIST += dbus_check.sh
else
bin_SCRIPTS = dbus_check.sh
endif

if OS_MACOS

installer: Installer/Moonshot.dmg
if WITH_APPLE_DEVELOPER_ID_APPLICATION
	codesign --sign "$(APPLE_DEVELOPER_ID_APPLICATION)" $<
endif
	cp $< ./

DMG_INPUTS = Installer/create-dmg.sh \
             Installer/moonshot-dmg-volumeicons.icns \
             Installer/moonshot-dmg-background-with-start.png \
             Installer/support/template.applescript

PKG_INPUTS = Installer/Moonshot.pkgproj \
             Installer/local.tar.gz \
             Installer/LatestBuild/Moonshot.app \
             Installer/LatestBuild/Uninstall\\ Moonshot.app

CLEAN_INPUTS = build \
               Uninstaller/build \
               Installer/Moonshot.dmg \
               Installer/Moonshot.pkg \
               Moonshot.dmg

Installer/Moonshot.dmg: $(DMG_INPUTS) Installer/Moonshot/Moonshot.pkg
	rm -f $@
	chmod +x $(abs_srcdir)/Installer/create-dmg.sh
	$(abs_srcdir)/Installer/create-dmg.sh --volname "Moonshot" \
		--volicon $(abs_srcdir)/Installer/moonshot-dmg-volumeicons.icns \
		--background $(abs_srcdir)/Installer/moonshot-dmg-background-with-start.png \
		--no-internet-enable --window-size 400 260 --icon-size 64 --text-size 14 \
		--icon "Moonshot.pkg" 160 48 --hide-extension "Moonshot.pkg" \
		$(abs_srcdir)/$@ $(abs_srcdir)/Installer/Moonshot/

Installer/Moonshot/Moonshot.pkg: $(PKG_INPUTS)
	mkdir -p $(abs_srcdir)/Installer/Moonshot
	cd $(abs_srcdir)/Installer && packagesbuild Moonshot.pkgproj
if WITH_APPLE_DEVELOPER_ID_INSTALLER
	productsign --sign "$(APPLE_DEVELOPER_ID_INSTALLER)" $(abs_srcdir)/Installer/Moonshot.pkg $(abs_srcdir)/$@
else
	cp $(abs_srcdir)/Installer/Moonshot.pkg $(abs_srcdir)/$@
endif

Installer/local.tar.gz: Installer/local filemanifest.txt
	sudo chown -R `whoami` $(abs_srcdir)/$<
	cd $(abs_srcdir)/$< && for i in $$(cat $(abs_srcdir)/filemanifest.txt); do srcfile="/usr/local/$$i"; echo "$$srcfile"; if test -d "$$srcfile"; then sudo install -d "$$i"; else sudo install "$$srcfile" "$$i"; fi; done
	cd $(abs_srcdir)/$< && tar -zcvf $(abs_srcdir)/$@ ./

Installer/LatestBuild/Moonshot.app: build/Release/Moonshot.app
	mkdir -p $(abs_srcdir)/Installer/LatestBuild/
	rm -rf "$(abs_srcdir)/$@"
	mv build/Release/*.app $(abs_srcdir)/Installer/LatestBuild/

Installer/LatestBuild/Uninstall\\ Moonshot.app: Uninstaller/build/Release/Uninstall\\ Moonshot.app
	mkdir -p $(abs_srcdir)/Installer/LatestBuild/
	rm -rf "$(abs_srcdir)/Installer/LatestBuild/Uninstall Moonshot.app"
	mv Uninstaller/build/Release/*.app $(abs_srcdir)/Installer/LatestBuild/

build/Release/Moonshot.app:
#if WITH_APPLE_DEVELOPER_ID_APPLICATION
#	cd Moonshot.xcodeproj; \
#	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = $(APPLE_DEVELOPER_TEAM_ID);/g' project.pbxproj;
#else
	cd Moonshot.xcodeproj; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = \"\";/g' project.pbxproj; \
	sed -i '' 's/CODE_SIGN_IDENTITY = "Developer ID Application";/CODE_SIGN_IDENTITY = "";/g' project.pbxproj
#endif
	$(XCODEBUILD)

Uninstaller/build/Release/Uninstall\\ Moonshot.app:
if WITH_APPLE_DEVELOPER_ID_APPLICATION
	cd "Uninstaller/Uninstall Moonshot.xcodeproj"; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = $(APPLE_DEVELOPER_TEAM_ID);/g' project.pbxproj;
else
	cd "Uninstaller/Uninstall Moonshot.xcodeproj"; \
	sed -i '' 's/ = APPLE_DEVELOPER_TEAM;/ = \"\";/g' project.pbxproj; \
	sed -i '' 's/CODE_SIGN_IDENTITY = "Developer ID Application";/CODE_SIGN_IDENTITY = "";/g' project.pbxproj
endif
	cd $(abs_srcdir)/Uninstaller && $(XCODEBUILD)

Installer/local:
	mkdir -p $@

clean:
	cd $(abs_srcdir) && rm -rff $(CLEAN_INPUTS) Installer/LatestBuild/* Installer/local* Installer/Moonshot/*

endif
