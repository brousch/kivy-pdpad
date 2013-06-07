# Project settings
WD := $(shell pwd)
PROJECT_DIR := $(WD)/pdpad
VENV := $(WD)/venv
PY := $(VENV)/bin/python
PIP := $(VENV)/bin/pip

# Python for Android settings
PYTHON_FOR_ANDROID := $(WD)/python-for-android
PYTHON_FOR_ANDROID_PACKAGE := $(PYTHON_FOR_ANDROID)/dist/default
PY4A_MODULES := "pylibpd audiostream kivy"

# Android settings
APK_PACKAGE := net.clusterbleep.pdpad
APP_NAME := "Kivy Pd Pad"
APK_NAME := KivyPdPad
APK_VERSION := 0.1
APK_ORIENTATION := sensor
APK_ICON := $(PROJECT_DIR)/resources/icon.png
APK_PRESPLASH := $(PROJECT_DIR)/resources/presplash.jpg
APK_DEBUG := $(PYTHON_FOR_ANDROID_PACKAGE)/bin/$(APK_NAME)-$(APK_VERSION)-debug.apk
APK_RELEASE := $(PYTHON_FOR_ANDROID_PACKAGE)/bin/$(APK_NAME)-$(APK_VERSION)-release-unsigned.apk
APK_FINAL := $(PYTHON_FOR_ANDROID_PACKAGE)/bin/$(APK_NAME).apk
APK_KEYSTORE := ~/Dropbox/Secure/net-clusterbleep-pdtest-release.keystore
APK_ALIAS := cb-pdtest
PERMISSION1 := "RECORD_AUDIO"

# Dropbox settings
DROPBOX := /home/brousch/Dropbox/Files/APKs/


# Run
.PHONY: run
run:
	cd $(PROJECT_DIR); \
	$(PY) main.py

.PHONY: inspect
inspect:
	cd $(PROJECT_DIR); \
	$(PY) main.py -m inspector


# Setup
.PHONY: install
install: install_system_packages create_virtualenv initialize_virtualenv install_cython install_kivy_dev install_python_for_android create_python_for_android_distribution

.PHONY: install_system_packages
install_system_packages:
	sudo apt-get update
	cat system-packages-kivy.txt | xargs sudo apt-get -y install

.PHONY: create_virtualenv
create_virtualenv:
	rm -rf $(VENV)
	virtualenv -p python2.7 --system-site-packages $(VENV)

.PHONY: initialize_virtualenv
initialize_virtualenv: install_cython install_kivy_dev

.PHONY: install_cython
install_cython:
	$(PIP) install -U -r requirements-cython.txt

.PHONY: install_kivy_dev
install_kivy_dev:
	$(PIP) install -U -r requirements-kivy-dev.txt

.PHONY: install_python_for_android
install_python_for_android:
	rm -rf $(PYTHON_FOR_ANDROID)
	git clone https://github.com/brousch/python-for-android.git

.PHONY: create_python_for_android_distribution
create_python_for_android_distribution:
	rm -rf $(PYTHON_FOR_ANDROID)/dist
	. $(VENV)/bin/activate; \
	cd $(PYTHON_FOR_ANDROID); \
	./distribute.sh -m $(PY4A_MODULES)


# Refresh and update
.PHONY: refresh
refresh: install_cython install_kivy_dev refresh_python_for_android

.PHONY: refresh_python_for_android
refresh_python_for_android: update_python_for_android create_python_for_android_distribution

.PHONY: update_python_for_android
update_python_for_android:
	cd $(PYTHON_FOR_ANDROID); \
	git clean -dxf; \
	git pull


# Android commands
.PHONY: package_android
package_android:
	rm -f $(PYTHON_FOR_ANDROID_PACKAGE)/bin/*.apk
	cd $(PYTHON_FOR_ANDROID_PACKAGE); \
	$(PY) ./build.py --package $(APK_PACKAGE) --name $(APP_NAME) --version $(APK_VERSION) --orientation $(APK_ORIENTATION) --icon $(APK_ICON) --presplash $(APK_PRESPLASH) --dir $(PROJECT_DIR) --permission $(PERMISSION1) debug;
	mkdir -p $(WD)/binaries
	cp $(APK_DEBUG) $(WD)/binaries/

.PHONY: package_android_release
package_android_release:
	cd $(PYTHON_FOR_ANDROID_PACKAGE); \
	$(PY) ./build.py --package $(APK_PACKAGE) --name $(APP_NAME) --version $(APK_VERSION) --orientation $(APK_ORIENTATION) --icon $(APK_ICON) --presplash $(APK_PRESPLASH) --dir $(PROJECT_DIR) --permission $(PERMISSION1) release;
	make sign_android
	mkdir -p $(WD)/binaries
	cp $(APK_FINAL) $(WD)/binaries/

.PHONY: sign_android
sign_android:
	rm -f $(APK_FINAL)
	jarsigner -verbose -sigalg MD5withRSA -digestalg SHA1 -keystore $(APK_KEYSTORE) $(APK_RELEASE) $(APK_ALIAS)
	zipalign -v 4 $(APK_RELEASE) $(APK_FINAL)


# Upload and install runables
.PHONY: install_android
install_android:
	adb install -r $(APK_DEBUG)

.PHONY: dropbox
dropbox:
	cp $(APK_DEBUG) $(DROPBOX)

