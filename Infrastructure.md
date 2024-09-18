# Курсовой проект по блоку "Системное администрирование"

 ## Инфраструктура

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

## Развертывание инфраструктуры:
из папки terraform
```sh
terraform init
terraform apply -target=module.vpc_up --auto-approve
```
-----------------------------------------------------------------


из папки terraform
```sh
cd vpc_up
terraform init  
terraform apply --auto-approve
```

## Развертывание инфраструктуры:
из папки terraform
```sh
cd image_backup
terraform init  
terraform apply --auto-approve
```


Запускаем плейбук web.yml из директории ansible.
```sh
ansible-playbook web.yml
```
В результате работы плейбука будет настроено:
- веб сервер nginx
- веб страница index.html и index.html  на webserver2
- 

ssh -o ProxyCommand="ssh -i /home/lamer/.ssh/test -W %h:%p test@89.169.152.12" test@zabbix-server.ru-central1.internal  

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

### Виртуальные машины
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_13.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_14.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_15.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_16.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_17.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_18.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_1.jpg)