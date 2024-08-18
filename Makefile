IMAGE_NAME="bitprepared/blackbox-builder"
VERSION=bullseye
PACKER_FILE=bitprepared.pkr.hcl

# default - creazione immagine docker di supporto per la generazione delle immagini specializzate
build:
	docker image build --build-arg BUILDKIT_INLINE_CACHE=1 --progress=plain -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

# primo step del run
init:
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) init /root/.packerconfig.pkr.hcl

run:
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build ${PACKER_FILE}

run-game:
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=1' game.pkr.hcl

run-all:
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=1' game.pkr.hcl
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=2' game.pkr.hcl
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=3' game.pkr.hcl
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=4' game.pkr.hcl

copy:
	dd bs=4M if=./build_dir/raspberry-pi-1.img of=/dev/sdb status=progress conv=fsync

connect-otg:
	ssh pi@192.168.42.42

clean:
	rm build_dir/raspberry-pi.img

clean-docker:
	docker buildx prune
#	docker builder prune
	docker rmi $(IMAGE_NAME)
	docker rmi $(IMAGE_NAME):$(VERSION)

qrcode:
	qrencode "WIFI:T:WPA;S:blackbox-1;P:blackbox;;" -t ansiutf8

qrcode-site:
	qrencode "http://blackbox.costigiola.net" -t ansiutf8

qrcode-game:
	qrencode "http://rosso.costigiola.net/SpaceShooter" -t ansiutf8

test:
	docker run --rm -it -v ${PWD}/build_dir/raspberry-pi.img:/sdcard/filesystem.img lukechilds/dockerpi:vm

device-test:
	adb shell am start -a android.intent.action.VIEW -d http://blackbox.costigiola.net

device-remote-test:
	adb shell am start -a android.intent.action.VIEW -d https://studio.code.org/projects/applab/mvBTE2WOywkQMKwWo6VLPeyx8PbS4esR_nLF4f2NIec	

install-firefox:
	adb shell am start -a android.intent.action.VIEW -d https://download.mozilla.org/?product=fennec-latest&os=android&lang=multi

site:
	open http://blackbox.costigiola.net

# docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .


