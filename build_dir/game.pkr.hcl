# reuse this long string
variable "blid" {
    type = string
}

variable "raspios_url" {
  type    = string
  default = "file:///build/raspberry-pi.img.zip"
}

source "arm" "pi" {
  file_urls             = ["${var.raspios_url}"]
  file_target_extension = "zip"
  file_checksum_type    = "none"
  image_build_method    = "reuse"
  image_path            = "raspberry-pi-${var.blid}.img"
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
    source = "/build/blackbox/files/sites/"
    destination = "/usr/share/nginx/"
  }

  provisioner "ansible" {
    extra_arguments = [
      "--connection=chroot",
      "-e ansible_host=/tmp/rpi_chroot",
      "-e ssid=blackbox-${var.blid}",
      "-e hostname=blackbox-${var.blid}",
      "-vvv"
      ]
    playbook_file   = "blackbox/playbook_game.yml"
  }

}

