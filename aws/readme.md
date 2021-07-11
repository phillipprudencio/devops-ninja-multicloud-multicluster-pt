# Roteiro

O que iremos fazer?

## Parte 1
1. Criação de usuário do IAM e permissões
2. Criação da instância do RancherServer pela aws-cli
3. Configuração do Rancher.
4. Configuração do Cluster Kubernetes.
5. Deployment do cluster pela aws-cli.



## Parte 2
6. Configuração do Traefik
7. Configuração do Longhorn
8. Criação do certificado não válido
9. Configuração do ELB
10. Configuração do Route 53


Parabéns, com isso temos a primera parte da nossa infraestrutura. 
Estamos prontos para rodar nossa aplicação.


# Parte 1

## 1 - Criação de usuário do IAM e permissões e configuração da AWS-CLI

https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html


## 2 - Criação da instância do RancherServer pela aws-cli.

```sh 

# RANCHER SERVER

# --image-id              ami-0b9064170e32bde34
# --instance-type         t3.medium 
# --key-name              multicloud 
# --security-group-ids    sg-0337149a89509276b 
# --subnet-id             subnet-0e696344

$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 1 --instance-type t3.medium --key-name multicloud --security-group-ids sg-0337149a89509276b --subnet-id subnet-0e696344 --user-data file://rancher.sh --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=rancherserver}]' 'ResourceType=volume,Tags=[{Key=Name,Value=rancherserver}]' 

```


## 3 - Configuração do Rancher
Acessar o Rancher e configurar

https://18.217.196.140

## 4 - Configuração do Cluster Kubernetes.
Criar o cluster pelo Rancher e configurar.



## 5 - Deployment do cluster pela aws-cli

```sh
# --image-id ami-0b9064170e32bde34
# --count 3 
# --instance-type t3.large 
# --key-name multicloud 
# --security-group-ids sg-0337149a89509276b
# --subnet-id subnet-78e81f03 
# --user-data file://k8s.sh

$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 3 --instance-type t3.large --key-name multicloud --security-group-ids sg-0337149a89509276b --subnet-id subnet-78e81f03 --user-data file://k8s.sh   --block-device-mapping "[ { \"DeviceName\": \"/dev/sda1\", \"Ebs\": { \"VolumeSize\": 70 } } ]" --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s}]'     
```

$ aws ec2 run-instances --image-id ami-0b9064170e32bde34 --count 3 --instance-type t3.large --key-name multicloud --security-group-ids sg-0337149a89509276b --subnet-id subnet-78e81f03 --user-data file://k8s.sh   --block-device-mapping file://mapping.json --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=k8s}]' 'ResourceType=volume,Tags=[{Key=Name,Value=k8s}]'     
```
Instalar o kubectl 

https://kubernetes.io/docs/tasks/tools/


# Parte 2

## 6 - Configuração do Traefik

O Traefik é a aplicação que iremos usar como ingress. Ele irá ficar escutando pelas entradas de DNS que o cluster deve responder. Ele possui um dashboard de  monitoramento e com um resumo de todas as entradas que estão no cluster.
```sh
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-rbac.yaml
$ kubectl apply -f https://raw.githubusercontent.com/containous/traefik/v1.7/examples/k8s/traefik-ds.yaml
$ kubectl --namespace=kube-system get pods
```
Agora iremos configurar o DNS pelo qual o Traefik irá responder. No arquivo ui.yml, localizar a url, e fazer a alteração. Após a alteração feita, iremos rodar o comando abaixo para aplicar o deployment no cluster.
```sh
$ kubectl apply -f traefik.yaml
```


## 7 - Configuração do Longhorn
Pelo console do Rancher


## 8 - Criação do certificado
Criar certificado para nossos dominios:

 *.phildevopsaws.cloudns.ph

	arn:aws:acm:us-east-2:316303010240:certificate/29708c22-a02c-4ef8-bfc2-d302be33e6a1
```sh
> openssl req -new -x509 -keyout cert.pem -out cert.pem -days 365 -nodes
Country Name (2 letter code) [AU]:DE
State or Province Name (full name) [Some-State]:Germany
Locality Name (eg, city) []:nameOfYourCity
Organization Name (eg, company) [Internet Widgits Pty Ltd]:nameOfYourCompany
Organizational Unit Name (eg, section) []:nameOfYourDivision
Common Name (eg, YOUR name) []:*.example.com
Email Address []:webmaster@example.com
```

arn:aws:acm:us-east-2:316303010240:certificate/29708c22-a02c-4ef8-bfc2-d302be33e6a1


## 9 - Configuração do ELB


```sh
# LOAD BALANCER

# !! ESPECIFICAR O SECURITY GROUPS DO LOAD BALANCER

# --subnets subnet-78e81f03 subnet-0e696344

$ aws elbv2 create-load-balancer --name multicloud --type application --subnets subnet-78e81f03 subnet-0e696344
#	 "LoadBalancerArn": "arn:aws:elasticloadbalancing:us-east-2:316303010240:loadbalancer/app/multicloud/7e7165f8e181516a"

# --vpc-id vpc-d420f7bd

$ aws elbv2 create-target-group --name multicloud --protocol HTTP --port 80 --vpc-id vpc-d420f7bd --health-check-port 8080 --health-check-path /api/providers
#	 "TargetGroupArn": "arn:aws:elasticloadbalancing:us-east-2:316303010240:targetgroup/multicloud/6526ee8d1783c86e"
	
	
# REGISTRAR OS TARGETS  
$ aws elbv2 register-targets --target-group-arn arn:aws:elasticloadbalancing:us-east-2:316303010240:targetgroup/multicloud/6526ee8d1783c86e --targets Id=i-04a8295a2f6ab61b0 Id=i-032ad150508dc7beb Id=i-0fd37ab6d4572f753


i-04a8295a2f6ab61b0
i-032ad150508dc7beb
i-0fd37ab6d4572f753

# ARN DO Certificado - arn:aws:acm:us-east-2:316303010240:certificate/29708c22-a02c-4ef8-bfc2-d302be33e6a1
# HTTPS - CRIADO PRIMEIRO
# Linux
$ aws elbv2 create-listener \
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:316303010240:loadbalancer/app/multicloud/7e7165f8e181516a \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn=arn:aws:acm:us-east-2:316303010240:certificate/29708c22-a02c-4ef8-bfc2-d302be33e6a1 \
    --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-2:316303010240:targetgroup/multicloud/6526ee8d1783c86e
#Windows
aws elbv2 create-listener `
    --load-balancer-arn arn:aws:elasticloadbalancing:us-east-2:316303010240:loadbalancer/app/multicloud/7e7165f8e181516a `
    --protocol HTTPS `
    --port 443 `
    --certificates CertificateArn=arn:aws:acm:us-east-2:316303010240:certificate/29708c22-a02c-4ef8-bfc2-d302be33e6a1 `
    --ssl-policy ELBSecurityPolicy-2016-08 --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:us-east-2:316303010240:targetgroup/multicloud/6526ee8d1783c86e    
#  ListenerArn": "arn:aws:elasticloadbalancing:us-east-2:316303010240:listener/app/multicloud/7e7165f8e181516a/b224fca0e6706915


$ aws elbv2 describe-target-health --target-group-arn targetgroup-arn

# DESCRIBE NO LISTENER
$ aws elbv2 describe-listeners --listener-arns arn:aws:elasticloadbalancing:us-east-1:984102645395:listener/app/multicloud/0c7e036793bff35e/a7386cf3e0dc3c0e


```


## 10 - Configuração do Route 53
Pelo console da AWS



