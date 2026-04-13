# K8s Kubeadm on AWS EC2 — Terragrunt

Infraestructura AWS EC2 con Terragrunt para levantar un cluster de Kubernetes con kubeadm. Preparada para dos entornos: **LocalStack** (desarrollo local) y **AWS Producción**.

## Qué crea esta infraestructura

| Recurso            | Descripción                                                         |
| ------------------ | ------------------------------------------------------------------- |
| **VPC**            | Red privada virtual con subnet pública y acceso a internet          |
| **Security Group** | Reglas de firewall: SSH, API Server (6443), etcd, kubelet, NodePort |
| **Key Pair**       | Par de claves SSH generado automáticamente (guardado en `~/.ssh/`)  |
| **EC2 Instances**  | Nodos master/worker con Debian 13, containerd, kubeadm preinstalado |
| **Elastic IPs**    | IP fija para cada nodo (no cambia al reiniciar)                     |

## Estructura del proyecto

```
k8s-kubeadm-aws-ec2/
├── modules/                          # Módulos Terraform reutilizables
│   ├── network/                      # VPC, Subnet, IGW, Route Table
│   ├── security/                     # Security Group (k8s ports), Key Pair, SSH Key
│   └── linux/                        # EC2 Instances (for_each), EIP, kubeadm user-data
├── environments/
│   ├── localstack/                   # Entorno LocalStack
│   │   ├── root.hcl                  # Root config (provider LocalStack + backend)
│   │   ├── env.hcl                   # Variables de entorno
│   │   ├── network/terragrunt.hcl
│   │   ├── security/terragrunt.hcl
│   │   └── linux/terragrunt.hcl
│   └── production/                   # Entorno AWS Producción
│       ├── root.hcl                  # Root config (provider AWS + backend)
│       ├── env.hcl
│       ├── network/terragrunt.hcl
│       ├── security/terragrunt.hcl
│       └── linux/terragrunt.hcl
└── .gitignore
```

## Dependencias entre módulos

```
network  ──►  security  ──►  linux
   │                           ▲
   └───────────────────────────┘
```

- **network**: VPC + Subnet (sin dependencias)
- **security**: Security Group + Key Pair (depende de `network.vpc_id`)
- **linux**: EC2 + EIP (depende de `network.subnet_id`, `security.security_group_id`, `security.key_name`)

Terragrunt resuelve automáticamente el orden de despliegue.

## Requisitos

- [Terraform](https://www.terraform.io/downloads) >= 1.0
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 1.0
- Para LocalStack: [LocalStack](https://docs.localstack.cloud/getting-started/installation/) corriendo en `localhost:4566`
- Para Producción: Credenciales AWS configuradas (`~/.aws/credentials` o variables de entorno)

## Uso

### LocalStack (desarrollo local)

```bash
# 1. Iniciar LocalStack
localstack start -d

# 2. Desplegar toda la infraestructura
cd environments/localstack
terragrunt run --all init
terragrunt run --all apply

# 3. Destruir
terragrunt run --all destroy
```

### AWS Producción

```bash
# 1. Asegurarse de tener credenciales AWS configuradas
export AWS_PROFILE=production

# 2. Desplegar toda la infraestructura
cd environments/production
terragrunt run --all init
terragrunt run --all apply

# 3. Destruir
terragrunt run --all destroy
```

### Desplegar un módulo individual

```bash
cd environments/localstack/network
terragrunt init
terragrunt apply
```

### Ver el plan antes de aplicar

```bash
cd environments/production
terragrunt run --all plan
```

## Personalización

### Definir nodos del cluster

Edita el mapa `nodes` en `linux/terragrunt.hcl` de cada entorno:

```hcl
nodes = {
  "master-1" = { role = "master", instance_type = "t3.medium", root_volume_size = 30 }
  "worker-1" = { role = "worker" }
  "worker-2" = { role = "worker" }
  "worker-3" = { role = "worker", instance_type = "t3.large", data_volume_size = 50 }
}
```

Cada nodo hereda los valores por defecto (`linux_instance_type`, `linux_root_volume_size`, etc.) a menos que los sobreescriba.

### Variables por entorno

| Variable                 | LocalStack                         | Producción         |
| ------------------------ | ---------------------------------- | ------------------ |
| `app_environment`        | `local`                            | `prod`             |
| `linux_instance_type`    | `t2.micro`                         | `t3.small`         |
| `linux_root_volume_size` | 8 GB                               | 20 GB              |
| `linux_data_volume_size` | 8 GB                               | 10 GB              |
| `volume_type`            | `gp2`                              | `gp3`              |
| `ami_owners`             | `["136693071363", "000000000000"]` | `["136693071363"]` |

## Después del apply: inicializar el cluster con kubeadm

### Paso 1 — Obtener IPs y conectar

```bash
# Ver IPs y comandos SSH de todos los nodos
cd environments/production/linux
terragrunt output ssh_commands
terragrunt output eip_public_ips

# Conectar al master
ssh -i ~/.ssh/postula-prod-linux-us-east-1.pem admin@<MASTER_IP>
```

### Paso 2 — Inicializar el master

```bash
# En el master: inicializar el cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl para tu usuario
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verificar que el master esté funcionando
kubectl get nodes
```

### Paso 3 — Instalar un CNI (red de pods)

```bash
# Instalar Flannel (opción recomendada para empezar)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Verificar que los pods de sistema estén corriendo
kubectl get pods -n kube-system
```

### Paso 4 — Unir los workers al cluster

```bash
# En cada worker: ejecutar el comando que devolvió kubeadm init
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```

> **Tip:** Si perdiste el token, genera uno nuevo desde el master:
>
> ```bash
> kubeadm token create --print-join-command
> ```

### Paso 5 — Verificar el cluster

```bash
# Desde el master
kubectl get nodes -o wide
# Todos los nodos deben mostrar STATUS = Ready
```

## Puertos abiertos en el Security Group

| Puerto      | Protocolo | Origen      | Uso                     |
| ----------- | --------- | ----------- | ----------------------- |
| 22          | TCP       | 0.0.0.0/0   | SSH                     |
| 80, 443     | TCP       | 0.0.0.0/0   | HTTP / HTTPS            |
| 6443        | TCP       | 0.0.0.0/0   | Kubernetes API Server   |
| 2379-2380   | TCP       | VPC interna | etcd                    |
| 10250       | TCP       | VPC interna | Kubelet API             |
| 10257       | TCP       | VPC interna | kube-controller-manager |
| 10259       | TCP       | VPC interna | kube-scheduler          |
| 8472        | UDP       | VPC interna | Flannel VXLAN           |
| 30000-32767 | TCP       | 0.0.0.0/0   | NodePort Services       |

## Troubleshooting

```bash
# Ver logs del user-data (si algo falló en el arranque)
sudo cat /var/log/cloud-init-output.log

# Verificar que containerd está corriendo
sudo systemctl status containerd

# Verificar que kubelet está corriendo
sudo systemctl status kubelet
sudo journalctl -u kubelet -f

# Re-generar token de unión (si expiró)
kubeadm token create --print-join-command

# Reiniciar kubeadm si algo salió mal
sudo kubeadm reset -f
```
