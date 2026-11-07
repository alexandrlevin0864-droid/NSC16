TARGET := iphone:clang:16.5:15.0
export ARCHS = arm64 arm64e

# Для rootless-джейлбрейков (Dopamine, Palera1n rootless) раскомментируй:
# export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = nsc16
nsc16_FILES = Tweak.x
nsc16_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = NSC16Settings
NSC16Settings_FILES = NSC16Settings/NSC16Settings.m
NSC16Settings_INSTALL_PATH = /Library/PreferenceBundles
NSC16Settings_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/bundle.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp NSC16.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/NSC16.plist