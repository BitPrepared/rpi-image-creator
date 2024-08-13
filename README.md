# Installazione
```
git clone https://github.com/mkaczanowski/packer-builder-arm

cd packer-builder-arm

docker build -t packer-builder-arm:local -f docker/Dockerfile .
```
Per semplicita' e' stato creato il file `init.sh`

# Preparazione
Il file di riferimento per creare l'immagine si trova qui `build_dir/bitprepared.pkr.hcl`

# Accesso 
L'immagine viene creata con un utente avente Username: `pi` , Password: `r3notaRE` , questa cosa 
e' definita di base nel file `build_dir/blackbox/provision-raspberry.sh` e poi sovrascritta a runtime 
con il comando ansible nel playbook `build_dir/blackbox/playbook.yml`

