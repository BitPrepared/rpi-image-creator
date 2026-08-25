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

copy: ## Scrive l'immagine su SD (scelta interattiva di immagine e dispositivo, con conferma)
	@echo "Immagini disponibili:"; \
	n=0; \
	for f in ./build_dir/*.img; do \
		[ -f "$$f" ] || continue; \
		n=$$((n+1)); \
		printf "  %s) %-50s %s\n" "$$n" "$$f" "$$(du -h "$$f" | cut -f1)"; \
	done; \
	[ "$$n" -gt 0 ] || { echo "ERRORE: nessuna immagine .img in build_dir/. Esegui prima 'make build-first'."; exit 1; }; \
	printf "Quale immagine scrivere? [1-%s]: " "$$n"; \
	read -r idx; \
	case "$$idx" in ''|*[!0-9]*) echo "Scelta non valida."; exit 1;; esac; \
	[ "$$idx" -ge 1 ] && [ "$$idx" -le "$$n" ] || { echo "Scelta fuori intervallo."; exit 1; }; \
	img=""; i=0; \
	for f in ./build_dir/*.img; do \
		i=$$((i+1)); \
		if [ "$$i" = "$$idx" ]; then img="$$f"; fi; \
	done; \
	echo; \
	echo "Candidati (dischi rimovibili / USB / SD):"; \
	cands=$$(lsblk -dno NAME,RM,TYPE,TRAN,SIZE,MODEL 2>/dev/null | awk '$$3=="disk" && ($$2==1 || $$4 ~ /^(usb|mmc|sdio)/)'); \
	if [ -n "$$cands" ]; then echo "$$cands"; else \
		echo "(nessun disco rimovibile trovato, ecco tutti i dischi:)"; \
		lsblk -dno NAME,RM,TYPE,TRAN,SIZE,MODEL | awk '$$3=="disk"'; fi; \
	printf "Su quale dispositivo scrivere? [solo il nome, es. sda - vuoto per annullare]: "; \
	read -r dev; \
	case "$$dev" in "") echo "Annullato."; exit 1;; */*) echo "Inserire solo il nome (es. sda), non il percorso completo."; exit 1;; esac; \
	target="/dev/$$dev"; \
	[ -b "$$target" ] || { echo "ERRORE: $$target non esiste o non e' un block device."; exit 1; }; \
	if lsblk -lno MOUNTPOINT "$$target" 2>/dev/null | grep -q .; then \
		echo "ERRORE: $$target ha partizioni montate, smontale prima (umount)."; exit 1; fi; \
	echo; \
	echo "Dispositivo scelto:"; lsblk -dno NAME,SIZE,TRAN,MODEL "$$target"; \
	echo; \
	echo "ATTENZIONE: '$$target' verra' COMPLETAMENTE SOVRASCRITTO con $$img, dati persi!"; \
	printf "Confermi? Scrivere YES per procedere: "; \
	read -r ok; \
	[ "$$ok" = "YES" ] || { echo "Annullato."; exit 1; }; \
	dd bs=4M if=$$img of=$$target status=progress conv=fsync

connect-otg: ## SSH via cavo USB OTG (trova l'interfaccia, assegna 192.168.42.1 e connette)
	@ifc=""; \
	for n in $$(ls /sys/class/net 2>/dev/null); do \
		drv=$$(basename $$(readlink -f /sys/class/net/$$n/device/driver 2>/dev/null) 2>/dev/null); \
		if [ "$$drv" = "cdc_subset" ]; then ifc="$$n"; break; fi; \
	done; \
	[ -n "$$ifc" ] || { echo "ERRORE: nessuna interfaccia OTG (cdc_subset) trovata. Cavo collegato e Pi avviata?"; exit 1; }; \
	echo "Interfaccia OTG: $$ifc"; \
	sudo ip link set "$$ifc" up; \
	ip -4 addr show dev "$$ifc" | grep -q 'inet 192\.168\.42\.' || sudo ip addr add 192.168.42.1/24 dev "$$ifc"; \
	ping -c 2 -W 2 192.168.42.42 || echo "ATTENZIONE: la Pi non risponde al ping, provo comunque l'ssh..."; \
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
