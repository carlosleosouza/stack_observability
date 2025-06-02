# MicroK8s Edge Lab (Rede privada 192.168.56.0)

## Requisitos
- Vagrant
- VirtualBox

## Subir o cluster
```bash
vagrant up
```

## Acessar cada VM
```bash
vagrant ssh node1
```

## Formar cluster
No `node1`:
```bash
microk8s enable ha-cluster
microk8s add-node
```
Execute o comando resultante nos outros nós.

## Deploy das apps
```bash
microk8s kubectl apply -f /vagrant/manifests/
```

## Testar
Adicione em `/etc/hosts` do host:
```
192.168.56.10 frontend.local backend.local
```

Acesse:
- http://frontend.local
- http://backend.local
