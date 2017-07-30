output "manager-ips" {
    value = "${digitalocean_droplet.manager.*.ipv4_address}"
}

output "worker-ips" {
    value = "${digitalocean_droplet.worker.*.ipv4_address}"
}

output "worker-lb-ip" {
    value = "${digitalocean_loadbalancer.worker-lb.ip}"
}
