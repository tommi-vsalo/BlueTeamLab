terraform {
  required_providers {
    virtualbox = {
      source = "ccll/virtualbox"
    }
  }
}

variable "name" {}
variable "image" {}
variable "cpus" {}
variable "memory" {}

resource "virtualbox_vm" "vm" {
  name   = var.name
  image  = var.image
  cpus   = var.cpus
  memory = var.memory

  # NAT adapter (internet)
  network_adapter {
    type = "nat"
  }

  # Host-only adapter (lab network)
  network_adapter {
    type = "hostonly"
  }
}