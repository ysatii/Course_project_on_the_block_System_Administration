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


## Запускаем все плайбуки по очереди из директории ansible.  перед этим прописав в файле ansible/inventory.ini 
### Установка П.О. на машины! подробнее по ссылке

* [установка П.О.](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Ansible.md)


## При необходимости можем подлючиться к любой машине через SSH прокси 

ssh -o ProxyCommand="ssh -i /home/lamer/.ssh/test -W %h:%p test@89.169.152.12" test@zabbix-server.ru-central1.internal  
89.169.152.12- это ip адрес машины бастион,  
 zabbix-server.ru-central1.internal - внутренное доменное имя в сети  


## Виртуальные машины
![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_13.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_14.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_15.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_16.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_17.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_18.jpg)

![Скриншот 1](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/img/sait1_1.jpg)

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)