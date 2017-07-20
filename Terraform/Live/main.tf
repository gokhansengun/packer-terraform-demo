provider "digitalocean" {
}

data "digitalocean_image" "worker-snapshot" {
  name = "packer-devops-turkey-0.0.1"
}

resource "digitalocean_ssh_key" "worker-ssh" {
  name       = "devops-turkey-worker-ssh"
  public_key = "${file("../ssh/id_rsa.pub")}"
}

resource "digitalocean_droplet" "worker" {
  count  = 3

  image  = "${data.digitalocean_image.worker-snapshot.image}"
  name   = "${format("worker-node-%02d", count.index + 1)}"
  region = "ams2"
  size   = "2gb"

  ssh_keys = [ "${digitalocean_ssh_key.worker-ssh.id}" ]
}

resource "digitalocean_loadbalancer" "worker-lb" {
  name = "devops-turkey-worker-lb"
  region = "ams2"

  forwarding_rule {
    entry_port = 80
    entry_protocol = "http"

    target_port = 5000
    target_protocol = "http"
  }

  healthcheck {
    port = 5000
    protocol = "http"
    path = "/"
    check_interval_seconds = 5
    response_timeout_seconds = 3
    unhealthy_threshold = 2
    healthy_threshold = 2 
  }

  droplet_ids = ["${digitalocean_droplet.worker.*.id}"]
}

// resource "digitalocean_domain" "default" {
//   name       = "digitalocean-demo.gokhansengun.com"
//   ip_address = "${digitalocean_loadbalancer.worker-lb.ip}"
// }
