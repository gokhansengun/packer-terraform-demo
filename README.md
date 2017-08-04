## Introduction

This repo includes 

- A Packer configuration to create a virtual machine image (with Docker installed)
- A Terraform configuration to create virtual machines, ssh keys, load balancer in DigitalOcean to run Swarm Cluster

## Instructions for DigitalOcean

### Prerequisite

`jq`, `packer` and `terraform` must be installed in the user machine following below instructions.

### Create a Snapshot in DigitalOcean with Packer

- Using DigitalOcean dashboard, create an API token and add it to a local file named like `~/.digitalocean_api_token`

    Its contents may look like below

    ```bash
    $ export DIGITALOCEAN_TOKEN=ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789
    ```

- Open a shell, go to `Packer` folder and source the file that includes the token, this will add token to the environment variables

    ```bash
    $ cd Packer
    $ source ~/.digitalocean_api_token
    ```

- Run `packer` for only provider `digitalocean`.

    ```bash
    $ packer build -only=digitalocean devops-turkey-ubuntu1604.json
    ```

### Create the infrastructure in DigitalOcean with Terraform

- In the shell, go to `Terraform/Live` folder and run below command to create the infrastructure.

    ```bash
    $ (sudo) chmod 400 ../ssh/id_rsa # properly set the private key's permissions
    $ terraform plan # to confirm the infrastructure
    $ terraform apply
    ```

- `Terraform` will output the load balancer ip address, take a note of it.

- Wait for all services to become `running`, use command below.

    ```bash
    $ ssh -i ../ssh/id_rsa -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null root@$(terraform output -json worker-ips | jq -r '.value[0]')
    root@worker-node-01:~# docker stack ps voting_app
    ```

- Enter the ip address of the load balancer from the browser and see the sample app.

    http://<load_balancer_ip>
