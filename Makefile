IMAGE_NAME="bitprepared/blackbox-builder"
VERSION=bookworm
PACKER_BASE_FILE=bitprepared.pkr.hcl
PACKER_FILE=game.pkr.hcl

# `make` senza argomenti continua a fare la build base (FASE 1)
.DEFAULT_GOAL := build

build: ## FASE 1 - crea l'immagine base Raspberry Pi (bitprepared.pkr.hcl)
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build ${PACKER_BASE_FILE}

init: ## Setup ambiente una tantum: packer-builder-arm + immagine docker + plugin ansible
	./init_packer.sh
	docker image build --build-arg BUILDKIT_INLINE_CACHE=1 --progress=plain -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) init /root/.packerconfig.pkr.hcl

docker: ## Ricrea solo l'immagine docker di build (bitprepared/blackbox-builder)
	docker image build --build-arg BUILDKIT_INLINE_CACHE=1 --progress=plain -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

build-first: ## FASE 2 - immagine della prima squadra (blid=1, sqname=oro)
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=1' -var 'sqname=oro' ${PACKER_FILE}

build-all: ## FASE 2 - immagini di tutte le squadre (oro, arancio, blu, rosso)
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=1' -var 'sqname=oro' 	${PACKER_FILE}
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=2' -var 'sqname=arancio' ${PACKER_FILE}
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=3' -var 'sqname=blu' 	${PACKER_FILE}
	docker run --rm -it --privileged -v /dev:/dev -v ${PWD}/build_dir:/build $(IMAGE_NAME):$(VERSION) build -var 'blid=4' -var 'sqname=rosso' 	${PACKER_FILE}

copy: ## Scrive l'immagine su scheda SD (/dev/sdb - verificare il dispositivo!)
	dd bs=4M if=./build_dir/raspberry-pi-1.img of=/dev/sdb status=progress conv=fsync

connect-otg: ## SSH via cavo USB OTG (pi@192.168.42.42)
	ssh pi@192.168.42.42

clean: ## Rimuove l'immagine base generata (build_dir/raspberry-pi.img)
	rm build_dir/raspberry-pi.img

clean-docker: ## Pulisce le immagini docker di build (buildx prune + rmi)
	docker buildx prune
#	docker builder prune
	docker rmi $(IMAGE_NAME)
	docker rmi $(IMAGE_NAME):$(VERSION)

qrcode: ## QR-code di connessione WiFi (SSID blackbox-1)
	qrencode "WIFI:T:WPA;S:blackbox-1;P:blackbox;;" -t ansiutf8

qrcode-site: ## QR-code dell'URL del sito blackbox
	qrencode "http://blackbox.costigiola.net" -t ansiutf8

qrcode-game: ## QR-code del gioco di esempio (rosso.costigiola.net/SpaceShooter)
	qrencode "http://rosso.costigiola.net/SpaceShooter" -t ansiutf8

test: ## Test emulato dell'immagine con dockerpi:vm
	docker run --rm -it -v ${PWD}/build_dir/raspberry-pi.img:/sdcard/filesystem.img lukechilds/dockerpi:vm

device-test: ## Apre il sito blackbox nel browser di un device Android (ADB)
	adb shell am start -a android.intent.action.VIEW -d http://blackbox.costigiola.net

device-remote-test: ## Apre il progetto AppLab su un device Android (ADB)
	adb shell am start -a android.intent.action.VIEW -d https://studio.code.org/projects/applab/mvBTE2WOywkQMKwWo6VLPeyx8PbS4esR_nLF4f2NIec


install-firefox: ## Scarica Firefox su un device Android (ADB)
	adb shell am start -a android.intent.action.VIEW -d https://download.mozilla.org/?product=fennec-latest&os=android&lang=multi

site: ## Apre il sito blackbox nel browser locale
	open http://blackbox.costigiola.net

base-image-view: ## Mostra l'immagine RaspiOS di base (URL, Debian, release) letta da bitprepared.pkr.hcl
	@url=$$(grep -o 'default = "[^"]*"' build_dir/bitprepared.pkr.hcl | head -1 | sed 's/default = "//; s/"//'); \
	echo "Immagine di base (raspios_url in build_dir/bitprepared.pkr.hcl):"; \
	echo "  URL    : $$url"; \
	echo "  Debian : $$(echo "$$url" | grep -o 'raspios-[a-z]*' | head -1 | sed 's/raspios-//') (12 = bookworm, 13 = trixie)"; \
	echo "  release: $$(echo "$$url" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' | head -1)"

help: ## Mostra questo aiuto (elenco di tutti i comandi disponibili)
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .
