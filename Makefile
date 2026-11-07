TARGET := iphone:clang:16.5:15.0
export ARCHS = arm64 arm64e

# Для rootless-джейлбрейков (Dopamine, Palera1n rootless) раскомментируй:
# export THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = chargeclock
chargeclock_FILES = Tweak.x
chargeclock_CFLAGS = -fobjc-arc
include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = ChargeClockSettings
ChargeClockSettings_FILES = ChargeClockSettings/ChargeClockSettings.m
ChargeClockSettings_INSTALL_PATH = /Library/PreferenceBundles
ChargeClockSettings_FRAMEWORKS = UIKit
include $(THEOS_MAKE_PATH)/bundle.mk

after-stage::
	mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences
	cp ChargeClock.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/ChargeClock.plist