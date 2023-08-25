#!/bin/bash
# Я постарался реализовать идемпотентный скрипт установки, 
# чтобы он развертывал инфраструктуру прям с нуля, на "чистой" машине при условии что стоит ОС Ubuntu 20.04.
# Установка происходит от начала до конца. Когда скрипт отработает можно зайти на мастер ноду и под портами 30080 30030 проверить работоспособность приложения и кластера.

set -e


echo "Копируем ssh ключик для доступа"
cp /home/vagrant/.ssh/id_rsa.pub /home/vagrant/diplom_netology/terraform/
echo "Скачиваем репозиторий kubespray, если его нет, для дальнейшего развертывания."
if [ ! -d "kubespray" ]; then
    echo "Репозиторий kubespray не найден. Скачиваем..."
    git clone https://github.com/kubernetes-sigs/kubespray.git
fi

echo "Проверяем и устанавливаем python 3.9"
if ! command -v python3.9 &> /dev/null; then
    echo "Python 3.9 не установлен. Установка..."
    sudo apt update
    sudo apt install -y software-properties-common
    sudo add-apt-repository ppa:deadsnakes/ppa
    sudo apt-get install -y python3.9
fi

echo "Проверяем и устанавливаем pip для python3.9"
if ! command -v pip3.9 &> /dev/null; then
    echo "Pip для Python 3.9 не установлен. Установка..."
    alias python3=python3.9
    sudo apt-get install python3-pip
fi
echo "Устанавливаем Ansible 2.14.6"
python3.9 -m pip install --user ansible-core==2.14.6
export PATH="$PATH:/home/vagrant/.local/bin"

echo "Проверяем и устанавливаем дополнительные утилиты, для успешного развертывания kubespray"
if ! command -v jq &> /dev/null; then
    echo "JQ не установлен. Установка..."
    sudo apt install jq
fi
if ! command -v netaddr &> /dev/null; then
    echo "netaddr не установлен. Установка..."
    sudo -H pip install  netaddr
    /usr/bin/python3.9 -m pip install netaddr

fi
if ! command -v jmespath &> /dev/null; then
    echo "jmespath не установлен. Установка..."
    sudo pip install jmespath
fi
if ! command -v kubectl &> /dev/null; then
    echo "kubectl не установлена. Установка..."
    sudo apt update && sudo snap install kubectl --classic
fi

echo "Проверяем наличие Terraform и устанавливаем его при необходимости"
if ! command -v terraform &> /dev/null; then
    echo "Terraform не установлен. Установка..."
    sudo snap install terraform --classic
fi

echo "---------------------------------------------------------------"
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
scp /home/vagrant/.ssh/id_rsa* ubuntu@$IP_MASTER:~/.ssh/
scp /home/vagrant/.ssh/id_rsa* ubuntu@$IP_WORKER0:~/.ssh/
scp /home/vagrant/.ssh/id_rsa* ubuntu@$IP_WORKER1:~/.ssh/

echo "---------------------------------------------------------------"
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
PORT_30030=30030
PORT_30080=30080

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

echo "---------------------------------------------------------------"
echo "Адрес для подключения к Grafana: $MASTER_IP:$PORT_30030"
echo "Адрес для подключения к приложению: $MASTER_IP:$PORT_30080"
