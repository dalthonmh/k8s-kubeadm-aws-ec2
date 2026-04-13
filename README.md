# terragrunt-aws-ec2

Infraestructura AWS EC2 con Terragrunt para levantar un cluster de Kubernetes con kubeadm. Preparada para dos entornos: **LocalStack** (desarrollo local) y **AWS Producción**.

## Estructura del proyecto

```
terragrunt-aws-ec2/
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
└── *.tf                              # Archivos Terraform originales (referencia)
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

## Después del apply: setup kubeadm

```bash
# Ver IPs y comandos SSH de todos los nodos
cd environments/production/linux
terragrunt output ssh_commands
terragrunt output eip_public_ips

# Conectar al master
ssh -i ~/.ssh/postula-prod-linux-us-east-1.pem admin@<MASTER_IP>

# En el master: inicializar el cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configurar kubectl
mkdir -p $HOME/.kube
sudo cp /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instalar CNI (Flannel)
kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# En cada worker: unirse al cluster (usar el comando que dio kubeadm init)
sudo kubeadm join <MASTER_IP>:6443 --token <TOKEN> --discovery-token-ca-cert-hash sha256:<HASH>
```
