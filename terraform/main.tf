terraform {
  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 2.0"
    }
  }
}

provider "lxd" {}

resource "lxd_instance" "debian_node" {
  name  = "wolf-debian"
  image = "images:debian/12"
  type  = "container"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu    = "1"
    memory = "512MB"
  }
}

resource "lxd_instance" "alma_node" {
  name  = "wolf-alma"
  image = "images:almalinux/9"
  type  = "container"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu    = "1"
    memory = "512MB"
  }
}

resource "lxd_instance" "rocky_node" {
  name  = "wolf-rocky"
  image = "images:rockylinux/9"
  type  = "container"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu    = "1"
    memory = "512MB"
  }
}
