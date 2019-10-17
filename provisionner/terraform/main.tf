variable "do_api_token" {}
variable "do_sshkey_id" {}

provider "digitalocean" {
    token = "${var.do_api_token}"
}

locals {
  haproxy_balancer_count = 1
  app_node_count = 2
  awx_node_count = 1
}

resource "digitalocean_droplet" "balancers" {
  count = "${local.haproxy_balancer_count}"
  name = "balancer${count.index}"
  image = "centos-7-x64"
  size = "1gb"
  region = "ams3"
  ssh_keys = ["${var.do_sshkey_id}"]
}

resource "digitalocean_droplet" "appservers" {
  count = "${local.app_node_count}"
  name = "appserver${count.index}"
  image = "ubuntu-18-04-x64"
  size = "1gb"
  region = "ams3"
  ssh_keys = ["${var.do_sshkey_id}"]
}

resource "digitalocean_droplet" "awxservers" {
  count = "${local.awx_node_count}"
  name = "awx${count.index}"
  image = "ubuntu-18-04-x64"
  size = "4gb"
  region = "ams3"
  ssh_keys = ["${var.do_sshkey_id}"]
}


# # Ansible mirroring hosts section
# Using https://github.com/nbering/terraform-provider-ansible/ to be installed manually (third party provider)
# Copy binary to ~/.terraform.d/plugins/

resource "ansible_host" "ansible_balancers" {
  count = "${local.haproxy_balancer_count}"
  inventory_hostname = "balancer${count.index}"
  groups = ["balancers"]
  vars = {
    ansible_host = "${element(digitalocean_droplet.balancers.*.ipv4_address, count.index)}"
    ansible_python_interpreter = "/usr/bin/python"
  }
}

resource "ansible_host" "ansible_appservers" {
  count = "${local.app_node_count}"
  inventory_hostname = "app${count.index}"
  groups = ["appservers"]
  vars = {
    ansible_host = "${element(digitalocean_droplet.appservers.*.ipv4_address, count.index)}"
  }
}

resource "ansible_host" "ansible_awxservers" {
  count = "${local.awx_node_count}"
  inventory_hostname = "awx${count.index}"
  groups = ["awxservers"]
  vars = {
    ansible_host = "${element(digitalocean_droplet.awxservers.*.ipv4_address, count.index)}"
  }
}

resource "ansible_group" "all" {
  inventory_group_name = "all"
  vars = {
    ansible_user = "root"
  }
}