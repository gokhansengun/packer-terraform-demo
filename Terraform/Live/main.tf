provider "digitalocean" {
}

data "digitalocean_image" "worker-snapshot" {
  name = "packer-devops-turkey-0.0.1"
}

resource "digitalocean_ssh_key" "default-ssh" {
  name       = "devops-turkey-default-ssh"
  public_key = "${file("../ssh/id_rsa.pub")}"
}

resource "digitalocean_droplet" "manager" {
  image  = "${data.digitalocean_image.worker-snapshot.image}"
  name   = "manager-node"
  region = "ams2"
  size   = "2gb"

  ssh_keys = [ "${digitalocean_ssh_key.default-ssh.id}" ]

  connection {
    user        = "root"
    private_key = "${file("../ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm init --advertise-addr ${digitalocean_droplet.manager.ipv4_address}"
    ]
  }
}

resource "digitalocean_droplet" "worker" {
  count  = 3

  image  = "${data.digitalocean_image.worker-snapshot.image}"
  name   = "${format("worker-node-%02d", count.index + 1)}"
  region = "ams2"
  size   = "2gb"

  ssh_keys = [ "${digitalocean_ssh_key.default-ssh.id}" ]

  connection {
    user        = "root"
    private_key = "${file("../ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "docker swarm join --token ${data.external.swarm_token.result.worker_join_token} ${digitalocean_droplet.manager.ipv4_address}:2377"
    ]
  }
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

resource "null_resource" "cluster" {
  # Changes to any instance of the cluster requires re-provisioning
  triggers {
    worker_droplet_ids = "${join(",", digitalocean_droplet.worker.*.id)}"
  }

  # Bootstrap script can run on any instance of the cluster
  # So we just choose the first in this case
  connection {
    host = "${digitalocean_droplet.manager.ipv4_address}"
    user        = "root"
    private_key = "${file("../ssh/id_rsa")}"
  }

  provisioner "remote-exec" {
    inline = [
      "curl -o voting-stack.yml 'https://raw.githubusercontent.com/dockersamples/example-voting-app/master/docker-stack.yml'",
      "docker stack deploy -c voting-stack.yml voting_app",
    ]
  }
}

data "external" "swarm_token" {
  program = [ "/bin/bash", "./scripts/worker-join-token.s h" ]
  query = {
    swarm_manager_ip = "${digitalocean_droplet.manager.ipv4_address}"
  }
}