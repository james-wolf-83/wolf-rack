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

resource "lxd_instance" "oracle_node" {
  name  = "wolf-oracle"
  image = "images:oracle/9"
  type  = "container"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu    = "1"
    memory = "512MB"
  }
}

resource "lxd_instance" "fedora_node" {
  name  = "wolf-fedora"
  image = "images:fedora/43"
  type  = "container"

  config = {
    "boot.autostart" = true
  }

  limits = {
    cpu    = "1"
    memory = "512MB"
  }
}
