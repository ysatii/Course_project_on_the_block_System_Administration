# Курсовой проект по блоку "Системное администрирование"

## Скрипты ansible

[Главная страница](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/README.md)

  * 1_elk.yml - Скрипт дя установки стэка ELK
  * 2_web.yml - Скрипт установливает скрпиты на WEB сервера
  * 3_conf_zabbix_copy.yml - установка пакета zabbix на машину zabbix-server
  * 4_zabbix_copy_all.yml - установка zabbix агента на все оставшиеся машины кроме машины bastion
  * 5_zabbix_bastion.yml - установка zabbix агента на машину bastion 
  
```sh
ansible-playbook 1_elk.yml
```


## 1_elk.yml - Скрипт дя установки стэка ELK
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Настройка и установка elasticsearch
  tags: elasticsearch
  hosts: elasticsearch
  gather_facts: no
  become: yes
  tasks:
    - name: Копирование пакета elastics
      copy:
        src: packages/{{ pkg_elastic }}
        dest: /tmp/

    - name: Установка пакета elasticsearch .deb
      apt:
        deb: "/tmp/{{ pkg_elastic }}"
        state: present
    
    - name: Копирование файла конфигурации elasticsearch.yml
      copy:
        src: templates/elasticsearch.yml
        mode: 0640
        dest: /etc/elasticsearch/elasticsearch.yml

    - name: переззапуск elasticsearch
      service:
        name: elasticsearch
        state: restarted
        enabled: true

- name: Настройка и установка kibana
  tags: kibana
  hosts: kibana
  gather_facts: no
  become: yes
  tasks:
    - name: Копирование пакета kibana
      copy:
        src: packages/{{ pkg_kibana }}
        dest: /tmp/

    - name: Установка пакета kibana .deb
      apt:
        deb: "/tmp/{{ pkg_kibana }}"
        state: present

    - name: Копирование файла конфигурации kibana.yml
      template:
        src: templates/kibana.yml.j2
        mode: 0640
        dest: /etc/kibana/kibana.yml

    - name: перезапуск kibana
      systemd:
        name: kibana
        state: restarted
        enabled: true
...

```
</details>
Скрипт  скопирует утановит и настроет elasticsearch, kibana на elastic.ru-central1.internal и kibana-server.ru-central1.internal соостветственно!


## 2_web.yml - Скрипт установливает П.О. на WEB сервера
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Установка пакетов на web сервера
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Обновление кеш
      apt:
        update_cache: yes

    - name: Установка nginx
      apt:
        name: nginx
        state: present

    - name: Копирование страницы index.html на сервера 
      copy:
        src: templates/index.html
        dest: /var/www/html/
    
    - name: перзапуск nginx
      service:
        name: nginx
        state: restarted
    
    - name: Копирование filebeat
      copy:
        src: packages/{{ pkg_name }}
        dest: /tmp/
    
    - name: Установка filebeat .deb
      apt:
        deb: "/tmp/{{ pkg_name }}"
        state: present

    - name: Копирование файла настроек filebeat.yml
      template:
        src: templates/filebeat.yml.j2
        mode: 0644
        dest: /etc/filebeat/filebeat.yml

    - name: Конфигурирование nginx модуля
      copy:
        dest: /etc/filebeat/modules.d/nginx.yml.disabled
        content: |
          - module: nginx
            # Access logs
            access:
              enabled: true

            # Error logs
            error:
              enabled: true
        mode: 0644
     
    - name: Активируе nginx модуль для filebeat
      shell:
        cmd:  filebeat setup --dashboards && filebeat modules enable system nginx
        
    - name: перезапуск демона systemd
      shell:
        cmd: systemctl daemon-reload
    
    - name: Перезапускаемм Filebeat
      systemd:
        name: filebeat.service
        state: restarted
        enabled: true

 
- name: Мониторинг сервера nginx в zabbix
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Копируем файл конфигурации stub_status.conf
      template:
        src: templates2/stub_status.conf
        mode: 0644
        dest:  /etc/nginx/conf.d/stub_status.conf

    - name:  Добавляем настройки в /etc/nginx/nginx.conf
      blockinfile:
        path: /etc/nginx/nginx.conf
        marker: "access_log /var/log/nginx/access.log;"
        insertafter: "access_log /var/log/nginx/access.log;"
        block: "{{ lookup('file', 'templates2/nginx.conf') }}"
    
    - name: Убираем строку из error.log
      lineinfile:
        path: /etc/nginx/nginx.conf
        state: absent
        regexp: '^% error_log /var/log/nginx/error.log;'

    - name: Убираем строку из  access.log
      lineinfile:
        path: /etc/nginx/nginx.conf
        state: absent
        regexp: '^%access_log /var/log/nginx/access.log;'

    - name: Перезапускаем nginx
      systemd:
        name: nginx.service
        state: restarted
        enabled: true
     

...
```
</details>

Скрипт установит и настроит nginx, filebeat произведет перзагрузку обоих сервисов.  
Также есть закоментированная часть кода для проверки корректности работы балансировщика! 
на второй веб серве будет загружен скрипт, что позвлит понимать с какого из веб серверов идет ответ!


## 3_conf_zabbix_copy.yml - установка пакета zabbix на машину zabbix-server
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
3_conf_zabbix_copy.yml

```
</details>
 Скрипт подготовит и настроет zabbix_server для работы, установит postgresql
 установит zabbix агент на веб сервера


## 4_zabbix_copy_all.yml - установка zabbix агента на все оставшиеся машины кроме zabbix сервер
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Установка Zabbix агента на сервера
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Копируем zabbix пакет
      copy:
        src: packages/{{ pkg_zabbix }}
        dest: /tmp/

    - name: Устанавливаем zabbix репозиторий
      command: dpkg -i /tmp/{{ pkg_zabbix }}

    - name: Устанавливаем zabbix-agent
      apt:
        name: zabbix-agent
        state: present
        update_cache: yes

    - name: Добавляем IP zabbix сервера
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'Server=127.0.0.1'
        replace: 'Server={{ zabbix_server }}'

    - name: Добавляем IP активного сервера
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'ServerActive=127.0.0.1'
        replace: 'ServerActive={{ zabbix_server }}'

    - name: Перезапускаем zabbix agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: true   

```
</details>

## requirements.yml - файл уставливает нужные для работы коллекции community.postgresql collection 
## необходимо для скрипта 3_pgsql_zabbix.yml, если у Вас нет коллекий запустите этот файл для установки коллекций
 
<detail>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
collections:
  # Установите коллекцию из Ansible Galaxy.
  - name:  community.postgresql collection 
    version: 3.5.0
    source: https://galaxy.ansible.com
```
</details>


## 3_pgsql_zabbix.yml  - установка пакета zabbix на машину zabbix-server исползуем PGsql класте от yandex-Cloud
 
<detail>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Установка zabbix сервера с испольгованием pgsql кластера yandex cloud
  hosts: zabbix_server
  gather_facts: no
  vars:
    host: c-{{ pg_cluster_id }}.rw.mdb.yandexcloud.net # Укажите адрес хоста
    db_port: 6432                                           # Укажите порт PostgreSQL (по умолчанию 5432)
    db_name: "zabbix"                                       # Укажите имя базы данных
    db_user:  "{{ zabbix_user }}"                           # Укажите пользователя базы данных
    db_password: "{{ pg_admin_password }}"                  # Укажите пароль пользователя базы данных
  become: yes
  tasks:
 
  - name: Обновление системы и установка зависимостей
    apt:
      update_cache: yes
      name: ['wget', 'curl', 'nginx', 'postgresql', 'postgresql-contrib', 'php-fpm', 'php-pgsql', 'php-bcmath', 'php-mbstring', 'php-gd', 'php-xml', 'mc']
      state: present
   
 

  - name: Копируем zabbix пакет
    copy:
      src: packages/{{ pkg_zabbix }}
      dest: /tmp/

  - name: Устанавливаем zabbix репозиторий 
    command: dpkg -i /tmp/{{ pkg_zabbix }}

  - name: обновляем кеш системы
    apt:
      update_cache: yes

   
  - name: Установливаем Zabbix Server и компоненты
    become: yes
    apt:
      name: ['zabbix-server-pgsql', 'zabbix-frontend-php', 'zabbix-nginx-conf', 'zabbix-agent', 'zabbix-sql-scripts']
      state: present
 
  - name: Копируем файл внутри удаленной машины
    copy:
      src: /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz
      dest: /tmp/server.sql.gz


  - name : Распаковываем server.sql.gz 
    shell:
      cmd: |
        cd /tmp
        zcat server.sql.gz >  server.sql

  - name: Загружаем начальные данные в базу zabbix
    community.postgresql.postgresql_db:
        name: zabbix
        login_host: "{{ host }}"
        login_password: "{{ db_password }}"
        login_user: "{{ db_user }}"
        port: 6432
        state: restore
        target: /tmp/server.sql
    become: yes



  - name: Дамп базы данных поднят удачно
    ansible.builtin.debug:
        msg: "Database imported successfully!"

  - name: "Ansible | Print a variable"
    debug:
      msg: "Использован кластер зпыйд yandex-cloud со следующими настройками db_host = {{ host }}, \n db_name = {{ db_name }}, \n db_user = {{ db_user }}, \n db_password = {{ db_password }},\n db_port = {{db_port}}"

  - name: Копируем файл настроек zabbix сервера zabbix_server.conf
    template:
      src: templates/zabbix_server.conf2.j2
      mode: 0644
      dest: /etc/zabbix/zabbix_server.conf

  - name: Устанавливаем пароль базы данных PostgreSQL
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '^# DBPassword='
       line: 'DBPassword={{ db_password }}' 
 
 
  - name: Устанавливаем  адврес хоста кластера yandex cloud PostgreSQL
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '# DBHost='
       line: 'DBHost={{ host }}' 

  - name: Устанавливаем порт кластера yandex-cloud PostgreSQL 
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '# DBPort='
       line: 'DBPort={{ db_port }}' 

  - name : Очищаем файл настроек web интерйейса zabbix.conf.php
    shell:
      cmd: |
        echo -n > /etc/zabbix/web/zabbix.conf.php


  - name: Генеририуем соержимое йайла настроек web интерфейса /etc/zabbix/web/zabbix.conf.php
    become: yes
    blockinfile:
       path: /etc/zabbix/web/zabbix.conf.php
       block: |
         <?php
         // Zabbix GUI configuration file.

          $DB['TYPE']				= 'POSTGRESQL';
          $DB['SERVER']			= '{{ host }}';
          $DB['PORT']			= '{{ db_port }}';
          $DB['DATABASE']		= '{{ db_name }}';
          $DB['USER']			= '{{ db_user }}';
          $DB['PASSWORD']		= '{{ db_password }}';

          // Schema name. Used for PostgreSQL.
          $DB['SCHEMA']			= '';

          // Used for TLS connection.
          $DB['ENCRYPTION']		= false;
          $DB['KEY_FILE']			= '';
          $DB['CERT_FILE']		= '';
          $DB['CA_FILE']			= '';
          $DB['VERIFY_HOST']		= false;
          $DB['CIPHER_LIST']		= '';

          // Vault configuration. Used if database credentials are stored in Vault secrets manager.
          $DB['VAULT_URL']		= '';
          $DB['VAULT_DB_PATH']	= '';
          $DB['VAULT_TOKEN']		= '';

          // Use IEEE754 compatible value range for 64-bit Numeric (float) history values.
          // This option is enabled by default for new Zabbix installations.
          // For upgraded installations, please read database upgrade notes before enabling this option.
          $DB['DOUBLE_IEEE754']	= true;

          // Uncomment and set to desired values to override Zabbix hostname/IP and port.
          // $ZBX_SERVER			= '';
          // $ZBX_SERVER_PORT		= '';

          $ZBX_SERVER_NAME		= 'my-zabbix';

          $IMAGE_FORMAT_DEFAULT	= IMAGE_FORMAT_PNG;
 
  - name: Настраиваем PHP для работы Zabbix
    become: yes
    blockinfile:
       path: /etc/php/8.1/fpm/php.ini
       block: |
         post_max_size = 16M
         upload_max_filesize = 2M
         max_execution_time = 300
         max_input_time = 300
         memory_limit = 128M
         date.timezone = Europe/Moscow

 
  - name: Настроиваем  Nginx для работы с Zabbix
    blockinfile:
      path: /etc/nginx/conf.d/zabbix.conf
      block: |
          server {
              listen 80;
              server_name  {{ server_name }};

              root /usr/share/zabbix;

              index index.php index.html index.htm;

              location / {
                  try_files $uri $uri/ =404;
              }

              location ~ \.php$ {
                  fastcgi_pass unix:/var/run/php/php8.1-fpm.sock;
                  fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                  include fastcgi_params;
              }

              location ~ /\.ht {
                  deny all;
              }
          }

  - name: Перезапускаем сервисы Zabbix и Nginx
    become: yes
    systemd:
        name: "{{ item }}"
        state: restarted
        enabled: true  
    with_items:
        - zabbix-server
        - zabbix-agent
        - nginx
        - php8.1-fpm

  - name: Печать адреса сервера zabbix
    ansible.builtin.debug:
        msg: "Для работы с zabbix перейдите по адресу {{ zabbix_server_ip }} логин 'Admin' пароль 'zabbix'"

```
</details>

* [Файл инвентаризации](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/ansible/inventory.ini)
 Файл ansible/inventory.ini  Содержит необходимые настройки 

секция all:vars  
bastion_host= указать адрес машины бастион  
zabbix_server_ip= указать адрес машины с забикс сервером  

секция bastion  
51.250.70.234 - изменить на адрес машины бастион  
