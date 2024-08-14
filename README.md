# Installazione

## Primo step
```
git clone https://github.com/mkaczanowski/packer-builder-arm

cd packer-builder-arm

docker build -t packer-builder-arm:local -f docker/Dockerfile .
```
Per semplicita' e' stato creato il file `init.sh`.

## Secondo step
Semplice comando `make` per creare l'immagine docker con cui lavoreremo, per ripulire la build `make clean-docker`

# Config
Il file di riferimento per creare l'immagine si trova qui `build_dir/bitprepared.pkr.hcl`; La parte invece che interessa di piu' per cambiare il comportamento e' la parte ansible dove le variabili di configurazione sono nel file `build_dir/blackbox/group_vars/all.yml`. In questo file va configurata opportunamente `webserver_static_sites_with_game` che contiene l'elenco dei giochi per postazione (1 postazione, 1 gioco).
la directory dei game e' `build_dir/blackbox/files/sites` e dentro andranno create le cartelle delle postazioni.
Es su `webserver_static_sites_with_game` abbiamo attualmente configurato:
 - arancio.costigiola.net
 - blu.costigiola.net
 - oro.costigiola.net
 - rosso.costigiola.net
Attenzione che per come e' l'export dei game, il nome del gioco e' da mettere nella variabile `webserver_static_sites_with_game` come percorso di ingresso del game.

# Build image raspberry
Per creare l'immagine raspberry basta dare `make run`
Per ripulire l'immagine generata `make clean`.

Indicative Time: 36 minutes 48 seconds.

# Accesso
## Wifi
La wifi della blackbox e' SSID: `blackbox-1` (`blackbox-2`,..), password: `blackbox`

## SSH
L'immagine viene creata con un utente avente Username: `pi` , Password: `r3notaRE` , questa cosa 
e' definita di base nel file `build_dir/blackbox/provision-raspberry.sh` e poi sovrascritta a runtime 
con il comando ansible nel playbook `build_dir/blackbox/playbook.yml`

# Local debug image

## Mount image
```
losetup -P /dev/loop0 raspberry-pi.img
mkdir /tmp/raspbian
mount /dev/loop0p2 /tmp/raspbian/
mount /dev/loop0p1 /tmp/raspbian/boot/
```

## Unmount image
```
umount /mnt/android/
umount /tmp/raspbian/boot/
umount /tmp/raspbian
losetup -d /dev/loop0
rm -rf /tmp/raspbian
```

