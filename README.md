## kubernetes-vagrant-kubeadm-rhel/oel/centos

Steps:
1. Install chocolatey windows package manager

	Link: [chocolatey](https://docs.chocolatey.org/en-us/choco/setup)


2. Install Vagrant

```shell
choco install vagrant
```	
	
3. Install a provider: virtualbox

```shell
choco install virtualbox
choco list
```

4. Vagrant IaaC workflow: 
    > Scope (Infra,folders) => vagrant init => vagrant up => vagrant ssh => vagrant halt => vagrant reload => vagrant destroy