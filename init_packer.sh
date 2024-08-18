
git clone https://github.com/mkaczanowski/packer-builder-arm
cd packer-builder-arm
docker build -t packer-builder-arm:local -f docker/Dockerfile .
cd ..