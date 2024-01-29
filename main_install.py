import os
import subprocess

def execute_command(command):
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    out, err = process.communicate()
    return out, err, process.returncode

def main():
    try:
        # Добавление ключа ssh
        os.system("(cd ~/.ssh && cp id_rsa.pub /home/vagrant/diplom_netology/terraform && cd ~ && cd diplom_netology)")

        # Скачивание репозитория kubespray, если его нет, для дальнейшего развертывания
        if not os.path.exists("kubespray"):
            print("Репозиторий kubespray не найден. Скачиваем...")
            os.system("git clone https://github.com/kubernetes-sigs/kubespray.git")

        # Проверка и установка python 3.9
        python_version_check = execute_command("command -v python3.9")
        if python_version_check[2] != 0:
            print("Python 3.9 не установлен. Установка...")
            os.system("sudo apt update && sudo apt install -y software-properties-common")
            os.system("sudo add-apt-repository ppa:deadsnakes/ppa")
            os.system("sudo apt-get install -y python3.9")

        # Проверка и установка pip для python 3.9
        pip_check = execute_command("command -v pip3.9")
        if pip_check[2] != 0:
            print("Pip для Python 3.9 не установлен. Установка...")
            os.system("alias python3=python3.9")
            os.system("sudo apt-get install python3-pip")

        # Установка Ansible 2.14.6
        os.system("python3.9 -m pip install --user ansible-core==2.14.6")
        os.environ["PATH"] = os.environ["PATH"] + ":/home/vagrant/.local/bin"

        # Проверка и установка дополнительных утилит
        utilities = ["jq", "netaddr", "jmespath", "kubectl"]
        for utility in utilities:
            utility_check = execute_command(f"command -v {utility}")
            if utility_check[2] != 0:
                print(f"{utility} не установлен. Установка...")
                if utility == "kubectl":
                    os.system("sudo apt update && sudo snap install kubectl --classic")
                elif utility == "netaddr":
                    os.system("sudo -H pip install netaddr")
                    os.system("/usr/bin/python3.9 -m pip install netaddr")
                else:
                    os.system(f"sudo pip install {utility}")

        # Проверка наличия и установка Terraform
        terraform_check = execute_command("command -v terraform")
        if terraform_check[2] != 0:
            print("Terraform не установлен. Установка...")
            os.system("sudo snap install terraform --classic")

        # Установка Helm
        os.system("sudo snap install helm --classic")

        print("---------------------------------------------------------------")
        print("Окружение готово, приступаем к развертыванию")

        os.chdir("terraform")
        os.system("terraform init")
        os.system("terraform apply -auto-approve")

        os.chdir("../")
        os.system("rm -rf kubespray/inventory/mycluster")
        os.system("cp -rfp kubespray/inventory/sample kubespray/inventory/mycluster")

        os.chdir("terraform")
        workspace = execute_command("terraform workspace show")[0].strip()
        os.system("bash generate_inventory.sh > ../kubespray/inventory/mycluster/hosts.ini")
        external_ip_master = execute_command("terraform output -json external_ip_address_vm_instance_master | jq -r '.[]'")[0].strip()

        print("---------------------------------------------------------------")
        print("Можно выключить VPN...")
        print("Ждем, пока инфраструктура оживет...")
        os.system("sleep 120")

        os.chdir("../kubespray")
        os.system("ansible-playbook -i ../kubespray/inventory/mycluster/hosts.ini ../kubespray/cluster.yml --become --ssh-common-args='-o StrictHostKeyChecking=no'")

        os.chdir("../")

        set +e
        k8s_conf_error_code = execute_command("ansible-playbook -i inv k8s_conf.yml --user ubuntu --ssh-common-args='-o StrictHostKeyChecking=no'")
        os.system("rm -rf inv")

        if k8s_conf_error_code[2] != 0:
            print("Произошла ошибка во время выполнения плейбука k8s_conf.yml.")
            exit(k8s_conf_error_code[2])

        jenkins_error_code = execute_command("ansible-playbook -i inv2 jenkins.yml --user ubuntu --ssh-common-args='-o StrictHostKeyChecking=no'")
        os.system("rm -rf inv2")

        if jenkins_error_code[2] != 0:
            print("Произошла ошибка во время выполнения плейбука jenkins.yml.")
            exit(jenkins_error_code[2])
        set -e

        print("Настройка переменной KUBECONFIG на", f"{os.path.expanduser('~')}/.kube/{workspace}/config")

        print("Создание пространств имён")
        os.system("kubectl create namespace monitoring")
        os.system("kubectl create namespace myapp")

        print("Установка прав доступа для конфигурации Kubernetes")
        os.system(f"chmod 600 {os.path.expanduser('~')}/.kube/{workspace}/config")

        print("Добавление репозитория Helm для Prometheus")
        os.system("helm repo add prometheus-community https://prometheus-community.github.io/helm-charts")

        print("Установка Prometheus")
        os.system("helm install prometheus --namespace monitoring prometheus-community/kube-prometheus-stack")

        print("Применение манифеста сервиса Grafana")
        os.system("kubectl apply -f ./manifests/grafana-service-nodeport.yaml")

        print("Установка Helm-чарта netology")
        os.system("helm install netology ./helm/myapp -n myapp")

        print("---------------------------------------------------------------")
        print("Инфраструктура развернута, используя мастер сервер можно подключится к Grafana и приложению.")

    except Exception as e:
        print(f"Произошла ошибка: {e}")

if __name__ == "__main__":
    main()
