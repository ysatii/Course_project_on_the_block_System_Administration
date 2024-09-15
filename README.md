# Курсовой проект по блоку "Системное администрирование"




В данный моент времени реализован terrafor скрпит для создания виртуальных машин 
## Развертывание инфраструктуры:
из папки terraform
```sh
terraform init
terraform apply -target=module.vpc_up --auto-approve
```

image_backup
```sh
cd image_backup
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


## Анализ работы
* [Анализ](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Analysis.md)

## Отчет по работе 

* [Сайт](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Sait.md)
* [Мониторинг](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Monitoring.md)
* [Логи](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Logs.md)
* [Сеть](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Network.md.)
* [Резервное копирование](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/Backup.md)
* Дополнительно


 


 