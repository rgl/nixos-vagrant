packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-hyperv
    hyperv = {
      version = ">= 1.1.1"
      source  = "github.com/hashicorp/hyperv"
    }
  }
}

variable "disk_size" {
  type    = string
  default = 8 * 1024
}

variable "iso_url" {
  type    = string
  default = "https://channels.nixos.org/nixos-23.05/latest-nixos-minimal-x86_64-linux.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:539d9ee4a77f7285f020360d4f066e6130ca6681768b4d88179914c6d228b650"
}

variable "hyperv_switch_name" {
  type    = string
  default = env("HYPERV_SWITCH_NAME")
}

variable "hyperv_vlan_id" {
  type    = string
  default = env("HYPERV_VLAN_ID")
}

variable "vagrant_box" {
  type = string
}

locals {
  boot_command = [
    "<enter><wait30s>",
    "sudo -i<enter><wait>",
    "install -d /provision<enter><wait>",
    "mount -o ro /dev/disk/by-label/provision /provision<enter><wait>",
    "bash /provision/install.sh<enter><wait1m>",
    "vagrant<enter><wait>",
    "vagrant<enter><wait>",
  ]
}

source "hyperv-iso" "nixos-amd64" {
  cd_label = "provision"
  cd_files = [
    "install.sh",
    "configuration.nix",
  ]
  boot_command      = local.boot_command
  boot_wait         = "5s"
  boot_order        = ["SCSI:0:0"]
  first_boot_device = "DVD"
  cpus              = 2
  memory            = 2048
  disk_size         = var.disk_size
  generation        = 2
  headless          = true
  iso_checksum      = var.iso_checksum
  iso_url           = var.iso_url
  switch_name       = var.hyperv_switch_name
  temp_path         = "tmp"
  vlan_id           = var.hyperv_vlan_id
  ssh_username      = "root"
  ssh_password      = "vagrant"
  ssh_timeout       = "60m"
  shutdown_command  = "poweroff"
}

build {
  sources = [
    "source.hyperv-iso.nixos-amd64",
  ]

  provisioner "shell-local" {
    environment_vars = [
      "PACKER_VERSION=${packer.version}",
      "PACKER_VM_NAME=${build.ID}",
    ]
    only = [
      "hyperv-iso.nixos-amd64",
    ]
    scripts = ["provision-local-hyperv.cmd"]
  }

  post-processor "vagrant" {
    only = [
      "hyperv-iso.nixos-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }
}
