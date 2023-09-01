bin_PROGRAMS = iVKLegacy
iVKLegacy_SOURCES = \
		cVK.h oauth.c http.c \
		uuid4.c \
		cJSON.c \
		AppDelegate.h AppDelegate.m \
		RootViewController.h RootViewController.m \
		VKFeedViewController.h VKFeedViewController.m \
		VKConnect.h VKConnect.m \
		URLImageView.h URLImageView.m \
		UIImageView+Network.h UIImageView+Network.m \
		FTWCache.h FTWCache.m \
		main.m

iVKLegacy_CFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook -fobjc-arc

iVKLegacy_LDFLAGS = \
			-framework UIKit -framework Foundation -framework QuickLook

iVKLegacy_LDADD = \
			-lssl -lcurl -L../libs

bin_SCRIPTS = iVKLegacy.ipa
CLEANFILES = $(bin_SCRIPTS)
EXTRA_DIST  = iVKLegacy.ipa

_dir:
	mkdir -p iVKLegacy.app

_plist:
	sed -e 's/VERSION/${PACKAGE_VERSION}/g' Info.plist > iVKLegacy.app/Info.plist

_images:
	cp -f ../images/AppIcon*.png iVKLegacy.app/.
	cp -f ../images/menu*.png iVKLegacy.app/.

iVKLegacy.app: iVKLegacy _dir _plist _images
	cp -f iVKLegacy iVKLegacy.app/. 
	cp -r ../libs iVKLegacy.app/.
	cd iVKLegacy.app; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libssl.0.9.8.dylib @executable_path/libs/libssl.dylib iVKLegacy; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcurl.4.dylib @executable_path/libs/libcurl.dylib iVKLegacy; \
	cd libs; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libcrypto.0.9.8.dylib @executable_path/libs/libcrypto.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libssl.dylib; \
		$(INSTALL_NAME_TOOL) -change /usr/lib/libgcc_s.1.dylib @executable_path/libs/libgcc_s.1.dylib libcrypto.dylib;

iVKLegacy.ipa: iVKLegacy.app
	mkdir Payload
	cp -r iVKLegacy.app Payload/.
	${ZIP} -r iVKLegacy.ipa Payload iTunesArtwork iTunesMetadata.plist
	rm -rf Payload

clean-local:
	rm -r iVKLegacy.app
	rm -r iVKLegacy.ipa

install:
#do nothing
