# Blackbox — Bitprepared RPi Image Creator

Set di strumenti per generare **immagini Raspberry Pi autonome** destinate al
"grande gioco" a squadre di Costigliola. Ogni Raspberry diventa una
**postazione (`blackbox-N`)** che, una volta accesa, crea la propria rete WiFi e
serve ai giocatori (connessi col telefono) i siti/giochi della propria squadra,
il tutto **senza alcuna connessione internet**.

Il build usa **Packer** (+ `packer-builder-arm`) dentro un container **Docker**,
con provisioning **Ansible** in modalità `chroot` e binari ARM eseguiti tramite
**QEMU**.

> Repository: `BitPrepared/rpi-image-creator`

---

## Come funziona (panoramica)

La creazione delle immagini avviene in **due fasi**:

```
                    FASE 1 (base)                         FASE 2 (gioco)
        ┌────────────────────────────────┐    ┌──────────────────────────────────┐
        │  bitprepared.pkr.hcl           │    │  game.pkr.hcl                    │
        │  playbook_base.yml             │    │  playbook_game.yml               │
        │                                │    │                                  │
        │  RaspiOS Bookworm  ──►  base   │    │  base (final)  ──►  per squadra  │
        │  hostapd, dnsmasq, udhcpd,     │    │  SSID blackbox-N, gioco squadra, │
        │  nginx, iptables, esp. rootfs  │    │  siti web della sq. specifica    │
        │                                │    │                                  │
        │  output: raspberry-pi.img.zip  │    │  output: raspberry-pi-N-<sq>.img │
        └────────────────────────────────┘    └──────────────────────────────────┘
                     `make`                            `make build-first` / `build-all`
```

1. **Fase base** — a partire da una RaspiOS Bookworm ufficiale installa e
   configura tutta l'infrastruttura di rete e i servizi (hotspot WiFi, DHCP/DNS,
   web server, firewall). Si produce **una sola volta** l'immagine base
   `raspberry-pi.img.zip`.
2. **Fase gioco** — a partire dall'immagine base genera le immagini
   **specializzate per ogni squadra** (personalizzando SSID, hostname e i siti
   serviti). Ripetibile per ogni postazione.

> ⚠️ **Passaggio manuale tra le fasi**: la fase gioco legge
> `build_dir/raspberry-pi-final.img.zip`, mentre la fase base produce
> `build_dir/raspberry-pi.img.zip`. Per collegarle, rinomina/copia il file
> generato:
> ```bash
> cp build_dir/raspberry-pi.img.zip build_dir/raspberry-pi-final.img.zip
> ```

### Terminologia

| Termine | Significato |
|---------|-------------|
| **postazione / blackbox** | Un singolo Raspberry Pi che ospita una rete e i giochi |
| **`blid`** | *Box ID* — numero della postazione (`1`..`4`), usato in SSID e hostname (`blackbox-<blid>`) |
| **`sqname`** | Nome della **squadra** legata alla postazione: `oro`, `arancio`, `blu`, `rosso` |

Mappatura postazione ↔ squadra (definita nel `Makefile`, target `build-all`):

| `blid` | `sqname` | SSID        |
|:------:|:--------:|:------------|
| 1      | oro      | `blackbox-1` |
| 2      | arancio  | `blackbox-2` |
| 3      | blu      | `blackbox-3` |
| 4      | rosso    | `blackbox-4` |

---

## Requirements

- **packer**
- **docker**
- **python**
- **bash**
- **zip**

---

## Setup ambiente

Il comando unico per preparare tutto:

```bash
make init
```

In questa fase vengono:

1. clonati e compilati `packer-builder-arm` (immagine Docker `packer-builder-arm:local`);
2. costruita l'immagine Docker di build `bitprepared/blackbox-builder:bookworm`
   (che aggiunge Ansible sopra `packer-builder-arm`);
3. inizializzato il plugin Packer ansible.

Target correlati:

| Target | Descrizione |
|--------|-------------|
| `make docker`     | Ricrea solo l'immagine Docker di build `bitprepared/blackbox-builder` |
| `make clean-docker` | Pulisce la build Docker (`buildx prune` + rimozione immagini) |
| `./clean.sh`      | Rimuove `packer-builder-arm` e le cache Packer locali |

---

## Build delle immagini

### Fase 1 — immagine base

```bash
make            # = build di bitprepared.pkr.hcl
```

- **Tempo indicativo:** ~15 min 46 s
- **Output:** `build_dir/raspberry-pi.img` (e `.img.zip`)
- **Pulizia:** `make clean`

> Ricorda di copiare il risultato in `raspberry-pi-final.img.zip` prima della
> fase 2 (vedi avviso sopra).

### Immagine di base (RaspiOS)

L'immagine di partenza della **Fase 1** è definita dalla variabile `raspios_url`
in `build_dir/bitprepared.pkr.hcl`:

- **Corrente:** RaspiOS **Bookworm** (Debian 12), **armhf** (32-bit), release **2025-05-13**
- URL: `https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2025-05-13/2025-05-13-raspios-bookworm-armhf.img.xz`
- SHA256: `7b2ffd34ce69dbc956c5171ffb367e9d4a1921f2525671919f2689225dfdedc8`

Per vederla senza aprire il file:

```bash
make base-image-view     # stampa URL, codename Debian e data di release estratti dall'hcl
```

#### Aggiornare l'immagine di base

**Sì, può essere aggiornata** modificando **una sola riga** — il `default` di
`raspios_url` in `build_dir/bitprepared.pkr.hcl`. Il checksum viene recuperato
automaticamente (`file_checksum_url = "${var.raspios_url}.sha256"`).

L'elenco delle release è su
<https://downloads.raspberrypi.org/raspios_armhf/images/>. Situazione a
agosto 2026:

| Release | Debian | Note |
|---------|:------:|------|
| `raspios_armhf-2025-05-13` | 12 bookworm | **Ultima bookworm** (in uso) |
| `raspios_armhf-2025-10-02` | 13 trixie | Prima trixie stabile |
| `raspios_armhf-2025-12-04` | 13 trixie | Ultima in assoluto |

> ⚠️ Il provisioning Ansible è scritto per **bookworm**: passare a **trixie**
> (Debian 13) non è solo un cambio di URL — cambia `raspi-config nonint`, il
> boot, Wayland di default e vari pacchetti — e richiede di ritestare i
> playbook. Restare su bookworm per aggiornamenti a basso rischio.

Esempio di cambio versione (es. all'ultima trixie):

```hcl
variable "raspios_url" {
  default = "https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2025-12-04/2025-12-04-raspios-trixie-armhf.img.xz"
}
```

> ⚠️ **Cose da tenere a mente dopo un aggiornamento:**
> - Bisogna **rifare la Fase 1** (`make`) e rigenerare `raspberry-pi-final.img.zip`.
> - Il build usa `qemu-arm-static` (emulazione **32-bit**): restare su `armhf`.
>   Per passare ad `arm64` occorrerebbe anche `qemu-aarch64-static` in entrambi i `.pkr.hcl`.
> - Una release più recente va **testata su un device reale** prima di rifare
>   tutte le immagini delle squadre (la Fase 2 dipende dalla base).

### Fase 2 — immagine del grande gioco (per squadra)

Una singola postazione:

```bash
make build-first    # blid=1, sqname=oro  →  raspberry-pi-1-oro.img
```

Tutte e 4 le postazioni in sequenza:

```bash
make build-all      # oro, arancio, blu, rosso
```

- **Tempo indicativo:** ~2 min 23 s (singola) / ~10 min 4 s (tutte)
- **Output:** `build_dir/raspberry-pi-<blid>-<sqname>.img`

### Scrittura su scheda SD

```bash
make copy      # dd su /dev/sdb (verificare il dispositivo!)
```

---

## Configurazione

### Variabili di build — `build_dir/blackbox/group_vars/all.yml`

File centrale del comportamento della postazione. Le sezioni principali:

- **Device / rete** — adattatori (`wifi_adapter`, `lan_adapter`, `otg_adapter`),
  IP statico opzionale sull'interfaccia LAN.
- **WiFi** — `ssid` (`blackbox-1`), `channel` (`6`), `security.psk`
  (la password della rete: `blackbox`), `wifi_country` (`IT`).
- **DHCP** — range `192.168.1.20–254`, gateway/DNS `192.168.1.1`, dominio
  `costigiola.net`, lease 10 giorni.
- **Boot / kernel** — `cmdline_options` (`zswap`, moduli OTG `dwc2,g_ether`),
  `boot_options` (`dtoverlay=dwc2`), `BOOTBEHAVIOUR` (`B1` = CLI senza autologin).

> Nota: all'esecuzione Packer alcuni valori vengono sovrascritti da variabili
> `-e` (vedi `game.pkr.hcl`): `ssid` e `hostname` diventano `blackbox-<blid>`,
> `sqname` viene iniettato.

### Siti serviti

Due elenchi nel file `group_vars`:

```yaml
webserver_static_sites:          # siti di base comuni a tutte le postazioni
  - studio.code.org
  - dsco.code.org
  - www.bitprepared.it

webserver_static_sites_with_game:  # siti con gioco, uno per squadra
  - name: blackbox.costigiola.net
    root:     /usr/share/nginx/2025/blackbox.costigiola.net
    rootGame: /usr/share/nginx/2025/blackbox.costigiola.net/StarQuiz
  - name: oro.costigiola.net
    rootGame: .../AppOro2025
  # ... rosso (AppRosso2025), blu (AppBlu2025)
```

Durante la fase gioco, per ogni postazione viene attivato **solo il sito della
squadra corrispondente** (filtro `selectattr('name','match','^' ~ sqname)`).

### Contenuto dei siti — `build_dir/blackbox/files/sites/`

- `sites/2025/` — **edizione 2025** dei siti a squadre:
  - `blackbox.costigiola.net/` → gioco **StarQuiz** (tema Star Wars)
  - `oro.costigiola.net/` → **AppOro2025**
  - `rosso.costigiola.net/` → **AppRosso2025**
  - `blu.costigiola.net/` → **AppBlu2025**
  Ogni cartella contiene `index.html` di presentazione + una sottocartella con
  il gioco (app AppLab di code.org esportata, con `index.html`, `code.js`,
  `style.css`, `applab/`, `assets/`).
- `sites/studio.code.org`, `sites/dsco.code.org` — mirror locale di code.org per
  far girare offline i giochi AppLab.
- `sites/www.bitprepared.it` — sito di presentazione del gruppo.

> **Attenzione:** nella cartella della squadra vanno `index.html` di
> presentazione **e** una sottocartella con il gioco.

### Adattamenti offline (automatici, in `playbook_game.yml`)

Poiché le postazioni non hanno internet, il playbook localizza le risorse:

- riscrittura di tutti gli URL `https://` → `http://` (in `index.html` e
  `applab-api.js`);
- `code.jquery.com` → asset locale (`assets/jquery-1.12.1.min.js`);
- `google.com/jsapi` → asset locale;
- configurazione di un **proxy APT** (`mirror.costigiola.bitprepared.it:3142`).

### Aggiungere una nuova squadra / gioco

1. Crea la cartella in `build_dir/blackbox/files/sites/2025/<nome>.costigiola.net/`
   con l'`index.html` e la sottocartella del gioco.
2. Aggiungi la voce a `webserver_static_sites_with_game` in `group_vars/all.yml`
   (`name`, `root`, `rootGame`).
3. Aggiungi un'entry `blid`/`sqname` nel target `build-all` del `Makefile`.

---

## Struttura del progetto

```
.
├── Makefile                         # target di build / utility
├── Dockerfile                       # immagine di build (Ansible + packer-builder-arm)
├── .packerconfig.pkr.hcl            # plugin Packer richiesto (ansible)
├── init_packer.sh / clean.sh        # setup / pulizia
├── packer-builder-arm/              # builder ARM (clonato da mkaczanowski)
├── 2023/                            # archivio storico edizione 2023 dei siti
└── build_dir/                       # area di build Packer + provisioning
    ├── bitprepared.pkr.hcl          # FASE 1 — immagine base
    ├── game.pkr.hcl                 # FASE 2 — immagine per squadra
    ├── raspberry-pi-final.img(.zip) # immagine base "di partenza" per la fase 2
    └── blackbox/                    # provisioning Ansible
        ├── playbook_base.yml        # provisioning fase 1
        ├── playbook_game.yml        # provisioning fase 2
        ├── provision-raspberry.sh   # pre-provisioning shell (password tmp, OTG)
        ├── group_vars/all.yml       # ⭐ configurazione centrale
        ├── files/                   # siti, chiavi SSH, config nginx, utility
        └── templates/               # template Jinja2 (hostapd, dnsmasq, hosts,
                                    #   nginx site.conf, interfaces, iptables…)
```

### Servizi configurati sulla postazione

| Servizio  | Ruolo |
|-----------|-------|
| **hostapd** | Crea l'hotspot WiFi `blackbox-N` (interfaccia `wlan0-ap`) |
| **udhcpd / dnsmasq** | DHCP (range `192.168.1.20–254`) + DNS locale (`costigiola.net`) |
| **nginx** | Serve i siti statici; un `server_name` per ogni dominio |
| **iptables** | Regole v4/v6 (NAT/firewall) |

Topologia di rete della postazione:

- `wlan0-ap` → `192.168.1.1` (AP + gateway/DNS per i client)
- `usb0` (OTG) → `192.168.42.42` (debug via cavo USB)
- Tutti i domini `*.costigiola.net`, `google.com`, `gstatic.com` risolvono su
  `192.168.1.1` (`templates/etc/hosts.j2`) → i browser dei client puntano
  sempre alla postazione.

---

## Accesso

### WiFi

- **SSID:** `blackbox-1` (`blackbox-2`, `blackbox-3`, `blackbox-4`)
- **Password:** `blackbox`

> Su Android verrà richiesto a ogni connessione se rimanere connessi (non c'è
> internet): spuntare "ricorda" e accettare di restare offline.
> Genera un QR-code di connessione con `make qrcode`.

### SSH

- **Username:** `pi`
- **Password:** `r3notaRE`

Definita di base in `build_dir/blackbox/provision-raspberry.sh` (password
temporanea) e poi finalizzata in `playbook_base.yml` (hash in `/boot/userconf.txt`).
Le chiavi pubbliche autorizzate sono in `build_dir/blackbox/files/keys/`.

### Setup OTG (debug locale via cavo USB)

```bash
dmesg | grep cdc_subset | grep rename      # ricava il nome dell'interfaccia host
# es. enp0s20f0u1i1
sudo ifconfig enp0s20f0u1i1 192.168.1.2 up
ping 192.168.42.42
```

Quindi `make connect-otg` → `ssh pi@192.168.42.42`.

---

## Debug / test

### Montare un'immagine generata

```bash
losetup -P /dev/loop0 build_dir/raspberry-pi-1-oro.img
mkdir /tmp/raspbian
mount /dev/loop0p2 /tmp/raspbian/
mount /dev/loop0p1 /tmp/raspbian/boot/
```

### Smontare

```bash
umount /tmp/raspbian/boot/
umount /tmp/raspbian
losetup -d /dev/loop0
rm -rf /tmp/raspbian
```

### Test emulato (senza Raspberry fisico)

```bash
make test       # dockerpi:vm sull'immagine generata
```

### Test su dispositivo Android (via ADB)

```bash
make device-test          # apre il sito blackbox nel browser
make device-remote-test   # apre direttamente il progetto AppLab
make install-firefox      # scarica Firefox sul device
```

---

## Altri target utili

> L'elenco completo e aggiornato di tutti i comandi è disponibile con **`make help`**
> (legge le descrizioni direttamente dal `Makefile`).

| Target | Descrizione |
|--------|-------------|
| `make help`           | Elenca tutti i target disponibili con descrizione |
| `make site`         | Apre `http://blackbox.costigiola.net` nel browser |
| `make base-image-view`   | Stampa l'immagine RaspiOS di base (URL, Debian, release) letta da `bitprepared.pkr.hcl` |
| `make qrcode-site`  | QR-code dell'URL del sito blackbox |
| `make qrcode-game`  | QR-code del gioco di esempio (`rosso.costigiola.net/SpaceShooter`) |
| `make qrcode`       | QR-code di connessione WiFi |

---

## Flusso di lavoro tipico (ricapitolo)

```bash
# 1. setup una tantum
make init

# 2. immagine base (una tantum / quando cambia l'infrastruttura)
make
cp build_dir/raspberry-pi.img.zip build_dir/raspberry-pi-final.img.zip

# 3. immagini delle squadre
make build-all        # oppure make build-first per una sola

# 4. scrittura su SD e accensione
make copy
```
