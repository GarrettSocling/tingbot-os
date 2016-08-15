.PHONY: build-img build-deb install build clean
.DELETE_ON_ERROR:

BASE_IMG_URL := http://downloads.raspberrypi.org/raspbian_lite/images/raspbian_lite-2016-03-18/2016-03-18-raspbian-jessie-lite.zip
BASE_IMG_NAME := $(basename $(notdir $(BASE_IMG_URL))).img
SPRINGBOARD := build/root/usr/share/tingbot/springboard.tingapp
SPRINGBOARD_COMMIT := 9c8d47


build/tingbot-os.deb: $(SPRINGBOARD) build/root
	# clean up .DS_Store files
	find build/root -name ".DS_Store" -delete
	mkdir -p build
	dpkg -b root/ build/tingbot-os.deb

build/root: $(shell find root ! -lname "*")
	cp -r root build/root

dl/springboard.tgz:
	wget http://github.com/tingbot/springboard/tarball/$(SPRINGBOARD_COMMIT) -O dl/springboard.tgz

$(SPRINGBOARD): dl/springboard.tgz
	# download springboard and install
	mkdir -p $(SPRINGBOARD)
	tar xzf dl/springboard.tgz -C $(SPRINGBOARD) --transform "s#.*/springboard.tingapp##" --wildcards "*/springboard.tingapp/"

build/disk.img: dl/$(BASE_IMG_NAME) build/tingbot-os.deb vm-setup.expect vm-build.expect vm-cleanup.expect
	mkdir -p build
	cp dl/$(BASE_IMG_NAME) build/disk.img
	
	# add 200M to the disk image (1,048,576 = 1m)
	dd if=/dev/zero count=200 bs=1048576 >> build/disk.img
	
	chmod 600 tingbot.key
	expect -f vm-setup.expect
	expect -f vm-build.expect
	expect -f vm-cleanup.expect

build/disk.img.zip: build/disk.img
	cd build; zip disk.img.zip disk.img

build-img: build/disk.img build/disk.img.zip

build-deb: build/tingbot-os.deb

build: build-img build-deb

install: build/tingbot-os.deb
	dpkg -i build/tingbot-os.deb

clean:
	rm -rf build
	rm -rf dl/springboard.tgz

dl/$(BASE_IMG_NAME):
	mkdir -p dl
	curl --location -o dl/$(BASE_IMG_NAME).zip $(BASE_IMG_URL)
	unzip dl/$(BASE_IMG_NAME).zip -d dl/zipfile
	mv dl/zipfile/*.img dl/$(BASE_IMG_NAME)
