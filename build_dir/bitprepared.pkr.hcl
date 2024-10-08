# reuse this long string
variable "raspios_url" {
  type    = string
  default = "https://downloads.raspberrypi.org/raspios_armhf/images/raspios_armhf-2024-07-04/2024-07-04-raspios-bookworm-armhf.img.xz"
}

source "arm" "pi" {
  file_checksum_type    = "sha256"
  file_checksum_url     = "${var.raspios_url}.sha256"
  file_target_extension = "xz"
  file_unarchive_cmd    = ["xz", "--decompress", "$ARCHIVE_PATH"]
  file_urls             = ["${var.raspios_url}"]
  image_build_method    = "resize"
  image_path            = "raspberry-pi.img"
  image_size            = "6G"
  image_type            = "dos"
  image_chroot_env      = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  image_mount_path      = "/tmp/rpi_chroot"
  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "8192"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "532480"
    type         = "83"
  }
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
}

build {
  sources = ["source.arm.pi"]

  provisioner "file" {
    source = "/build/blackbox/files/sites/studio.code.org"
    destination = "/usr/share/nginx/"
  }

  provisioner "file" {
    source = "/build/blackbox/files/sites/www.bitprepared.it"
    destination = "/usr/share/nginx/"
  }

  provisioner "ansible" {
    extra_arguments = [
      "--connection=chroot",
      "-e ansible_host=/tmp/rpi_chroot",
      "-vvv"
      ]
    playbook_file   = "blackbox/playbook_base.yml"
  }

  post-processor "compress" {
    compression_level = 1
    output = "raspberry-pi.img.zip"
  }

  // non funziona come vogliamo crea lo sha del file prima di essere zippato
  // post-processor "checksum" {
  //   checksum_types = ["sha256"]
  //   output = "raspberry-pi.img.zip.{{.ChecksumType}}"
  // }

}

