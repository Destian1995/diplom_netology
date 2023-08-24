#!/bin/bash
# Я постарался реализровать идемпотентный скрипт установки, 
# чтобы он развертывал инфраструктуру прям с нуля, на "чистой" машине при условии что стоит ОС Ubuntu 20.04.

set -e

# Скачиваем репозиторий kubespray, если его нет, для дальнейшего развертывания.
if [ ! -d "kubespray" ]; then
    echo "Репозиторий kubespray не найден. Скачиваем..."
    git clone https://github.com/kubernetes-sigs/kubespray.git
fi

# Проверяем и устанавливаем python 3.9
if ! command -v python3.9 &> /dev/null; then
    echo "Python 3.9 не установлен. Установка..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get install -y python3.9
fi

# Проверяем и устанавливаем pip для python3.9 и Ansible
if ! command -v pip3.9 &> /dev/null; then
    echo "Pip для Python 3.9 не установлен. Установка..."
    sudo apt-get install -y python3.9-pip
fi
python3.9 -m pip install --user ansible-core==2.14.6


# Проверяем и устанавливаем дополнительные утилиты, для успешного развертывания kubespray
if ! command -v jq &> /dev/null; then
    echo "JQ не установлен. Установка..."
    sudo apt install -y jq
fi
if ! command -v netaddr &> /dev/null; then
    echo "netaddr не установлен. Установка..."
    sudo -H pip install -y netaddr
fi
if ! command -v jmespath &> /dev/null; then
    echo "jmespath не установлен. Установка..."
    sudo pip install jmespath
fi
if ! command -v kubectl &> /dev/null; then
    echo "kubectl не установлена. Установка..."
    sudo apt-get update && sudo apt-get install -y kubectl
fi

# Проверяем наличие Terraform и устанавливаем его при необходимости
if ! command -v terraform &> /dev/null; then
    echo "Terraform не установлен. Установка..."
    sudo snap install terraform --classic
fi

echo "Окружение готово, приступаем к развертыванию"

cd terraform
terraform init
terraform apply -auto-approve

cd ../
rm -rf kubespray/inventory/mycluster
cp -rfp kubespray/inventory/sample kubespray/inventory/mycluster

cd terraform
export WORKSPACE=$(terraform workspace show)
bash generate_inventory.sh > ../kubespray/inventory/mycluster/hosts.ini
terraform output -json external_ip_address_vm_instance_master | jq -r '.[]' > ../inv
terraform output -json external_ip_address_vm_instance_jenkins | jq -r '.[]' > ../inv2
export IP_MASTER=$(terraform output -json external_ip_address_vm_instance_master | jq -r '.[]')

echo "Ждем пока инфраструктура оживет..."
sleep 120

cd ../kubespray
ansible-playbook -i ../kubespray/inventory/mycluster/hosts.ini ../kubespray/cluster.yml --become --ssh-common-args='-o StrictHostKeyChecking=no'

cd ..

set +e
ansible-playbook -i inv k8s_conf.yml --user ubuntu --ssh-common-args='-o StrictHostKeyChecking=no'
error_code=$?
rm -rf inv

if [ $error_code -ne 0 ]; then
    echo "Произошла ошибка во время выполнения плейбука k8s_conf.yml."
    exit $error_code
fi

ansible-playbook -i inv2 jenkins.yml --user ubuntu --ssh-common-args='-o StrictHostKeyChecking=no'
error_code=$?
rm -rf inv2

if [ $error_code -ne 0 ]; then
    echo "Произошла ошибка во время выполнения плейбука jenkins.yml."
    exit $error_code
fi
set -e

echo "Настройка переменной KUBECONFIG на $KUBECONFIG"
export KUBECONFIG=~/.kube/$WORKSPACE/config

echo "Создание пространств имён"
kubectl create namespace monitoring
kubectl create namespace myapp

echo "Установка прав доступа для конфигурации Kubernetes"
chmod 600 /home/vagrant/.kube/$WORKSPACE/config

echo "Добавление репозитория Helm для Prometheus"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

echo "Установка Prometheus"
helm install prometheus --namespace monitoring prometheus-community/kube-prometheus-stack

echo "Применение манифеста сервиса Grafana"
kubectl apply -f ./manifests/grafana-service-nodeport.yaml

echo "Установка Helm-чарта netology"
helm install netology ./helm/myapp -n myapp

