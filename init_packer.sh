
if [ -d packer-builder-arm ]; then
  echo "packer-builder-arm già presente, aggiorno..."
  git -C packer-builder-arm pull
else
  git clone https://github.com/mkaczanowski/packer-builder-arm
fi
cd packer-builder-arm
docker build -t packer-builder-arm:local -f docker/Dockerfile .
cd ..
