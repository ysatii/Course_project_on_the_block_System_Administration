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
- name: Configure elasticsearch
  tags: elasticsearch
  hosts: elasticsearch
  gather_facts: no
  become: yes
  tasks:
    - name: copy elasticsearch
      copy:
        src: packages/{{ pkg_elastic }}
        dest: /tmp/

    - name: Install elasticsearch deb
      apt:
        deb: "/tmp/{{ pkg_elastic }}"
        state: present
    
    - name: Copy elasticsearch.yml
      copy:
        src: templates/elasticsearch.yml
        mode: 0640
        dest: /etc/elasticsearch/elasticsearch.yml

    - name: restart elasticsearch
      service:
        name: elasticsearch
        state: restarted
        enabled: true

- name: Configure kibana
  tags: kibana
  hosts: kibana
  gather_facts: no
  become: yes
  tasks:
    - name: copy kibana
      copy:
        src: packages/{{ pkg_kibana }}
        dest: /tmp/

    - name: Install kibana deb
      apt:
        deb: "/tmp/{{ pkg_kibana }}"
        state: present

    - name: Copy kibana.yml
      template:
        src: templates/kibana.yml.j2
        mode: 0640
        dest: /etc/kibana/kibana.yml

    - name: restart kibana
      systemd:
        name: kibana
        state: restarted
        enabled: true

```
</details>
Скрипт  скопирует утановит и настроет elasticsearch, kibana на elastic.ru-central1.internal и kibana-server.ru-central1.internal соостветственно!


## 2_web.yml - Скрипт установливает П.О. на WEB сервера
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
---
- name: Configure web server
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Update cache
      apt:
        update_cache: yes

    - name: Install nginx
      apt:
        name: nginx
        state: present

    - name: Copy index.html
      copy:
        src: templates/index.html
        dest: /var/www/html/
    
    - name: Restart nginx
      service:
        name: nginx
        state: restarted
    
    - name: copy filebeat
      copy:
        src: packages/{{ pkg_name }}
        dest: /var/www/html/
    
    - name: Install filebeat deb
      apt:
        deb: "/tmp/{{ pkg_name }}"
        state: present

    - name: Configure nginx module
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
     
    - name: Enable system nginx module in filebeat
      shell:
        cmd:  filebeat setup --dashboards && filebeat modules enable system nginx
        
    - name: Reload systemd daemon
      shell:
        cmd: systemctl daemon-reload
    
    - name: restart Filebeat
      systemd:
        name: filebeat.service
        state: restarted
        enabled: true
...
    

- name: Configure web server 2
  hosts: webserver2.ru-central1.internal
  gather_facts: no
  become: yes
  tasks:
    - name: Copy index.html server2 
      copy:
        src: templates2/index.html
        dest: /var/www/html/
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
- name: Configure zabbix server
  hosts: zabbix_server
  gather_facts: no
  become: yes
  tasks:
  #- name: Update cache
  #  apt:
  #    update_cache: yes

  - name: Обновление системы и установка зависимостей
    apt:
      update_cache: yes
      name: ['wget', 'curl', 'nginx', 'postgresql', 'postgresql-contrib', 'php-fpm', 'php-pgsql', 'php-bcmath', 'php-mbstring', 'php-gd', 'php-xml', 'mc']
      state: present
  #- name: Install postgresql
  #  apt:
  #    name: postgresql
  #    state: present

  
  #- name: Copy zabbix package
  #  copy:
  #    src: packages/{{ pkg_zabbix }}
  #    dest: /tmp/

  #- name: Install zabbix repository
  #  command: dpkg -i /tmp/{{ pkg_zabbix }}

  #- name: Установка Zabbix 6.0
  #  apt:
  #    name: "{{ item }}"
  #    state: present
  #    update_cache: yes
  #  loop: ["zabbix-server-pgsql", "zabbix-frontend-php", "php8.1-pgsql", "zabbix-nginx-conf", "zabbix-sql-scripts", "zabbix-agent"]
  
  # Установка репозитория Zabbix
  
  - name: Install postgresql
    apt:
      name: postgresql
      state: present

  - name: Copy zabbix package
    copy:
      src: packages/{{ pkg_zabbix }}
      dest: /tmp/

  - name: Install zabbix repository
    command: dpkg -i /tmp/{{ pkg_zabbix }}

  - name: Update cache
    apt:
      update_cache: yes

  # Установка Zabbix Server, агент и веб-интерфейс
  - name: Установить Zabbix Server и компоненты
    become: yes
    apt:
      name: ['zabbix-server-pgsql', 'zabbix-frontend-php', 'zabbix-nginx-conf', 'zabbix-agent', 'zabbix-sql-scripts']
      state: present

  - name: Create user and DB
    shell:
      cmd: |
        su - postgres -c "psql --command \"CREATE USER {{ zabbix_user }} WITH PASSWORD '{{ zabbix_password }}';\"" && \
        su - postgres -c "psql --command \"CREATE DATABASE zabbix OWNER {{ zabbix_user }};\""          
        
  # Импорт схемы базы данных Zabbix
  - name: Импортировать начальную структуру базы данных
    shell: |
      zcat /usr/share/zabbix-sql-scripts/postgresql/server.sql.gz | sudo -u {{ zabbix_user }} -p {{ zabbix_password }} psql zabbix  | sudo -u {{ zabbix_user }} -p {{ zabbix_password }} psql zabbix
  

  # Настройка Zabbix Server
  - name: Настройка Zabbix Server для использования PostgreSQL
    lineinfile:
       dest: /etc/zabbix/zabbix_server.conf
       regexp: '^# DBPassword='
       line: 'DBPassword={{ zabbix_password }}' 
  
   # Настройка PHP для Zabbix
  - name: Настроить PHP для Zabbix
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

  # Настройка Nginx для Zabbix
  - name: Настроить Nginx для Zabbix
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

  # Перезапуск сервисов Zabbix и Nginx
  - name: Перезапустить сервисы Zabbix и Nginx
    become: yes
    systemd:
        name: "{{ item }}"
        state: restarted
    with_items:
        - zabbix-server
        - zabbix-agent
        - nginx
        - php8.1-fpm

  #- name: Copy zabbix_server.conf
  #  template:
  #    src: templates/zabbix_server.conf.j2
  #    mode: 0644
  #    dest: /etc/zabbix/zabbix_server.conf

  #- name: Copy nginx.conf
  #  template:
  #    src: templates/nginx.conf.j2
  #    mode: 0644
  #    dest: /etc/zabbix/nginx.conf

  #- name: Restart services
  #  systemd:
  #    name: "{{ item }}"
  #    state: restarted
  #    enabled: true
  #  loop: ["zabbix-server", "zabbix-agent", "nginx", "php8.1-fpm"]



- name: Configure zabbix agent
  hosts: internal_servers
  gather_facts: no
  become: yes
  tasks:
    - name: Copy zabbix package
      copy:
        src: packages/{{ pkg_zabbix }}
        dest: /tmp/

    - name: Install zabbix repository
      command: dpkg -i /tmp/{{ pkg_zabbix }}

    - name: Install zabbix-agent
      apt:
        name: zabbix-agent
        state: present
        update_cache: yes

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'Server=127.0.0.1'
        replace: 'Server={{ zabbix_server }}'

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'ServerActive=127.0.0.1'
        replace: 'ServerActive={{ zabbix_server }}'

    - name: Restart zabbix agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: true   

```
</details>
 Скрипт подготовит и настроет zabbix_server для работы, установит postgresql
 установит zabbix агент на веб сервера


## 4_zabbix_copy_all.yml - установка zabbix агента на все оставшиеся машины кроме машины bastion
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Configure zabbix agent
  hosts: all-servers
  gather_facts: no
  become: yes
  tasks:
    - name: Copy zabbix package
      copy:
        src: packages/{{ pkg_zabbix }}
        dest: /tmp/

    - name: Install zabbix repository
      command: dpkg -i /tmp/{{ pkg_zabbix }}

    - name: Install zabbix-agent
      apt:
        name: zabbix-agent
        state: present
        update_cache: yes

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'Server=127.0.0.1'
        replace: 'Server={{ zabbix_server }}'

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'ServerActive=127.0.0.1'
        replace: 'ServerActive={{ zabbix_server }}'

    - name: Restart zabbix agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: true   

```
</details>

## 5_zabbix_bastion.yml - установка zabbix агента на машину bastion 
 
<details>
<summary>Нажмите для просмотра листинга скрипта</summary>

```
- name: Configure zabbix agent to bastion
  hosts: bastion
  gather_facts: no
  become: yes
  tasks:
    - name: Copy zabbix package
      copy:
        src: packages/{{ pkg_zabbix }}
        dest: /tmp/

    - name: Install zabbix repository
      command: dpkg -i /tmp/{{ pkg_zabbix }}

    - name: Install zabbix-agent
      apt:
        name: zabbix-agent
        state: present
        update_cache: yes

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'Server=127.0.0.1'
        replace: 'Server={{ zabbix_server }}'

    - name: Add server IP
      replace:
        path: /etc/zabbix/zabbix_agentd.conf
        regexp: 'ServerActive=127.0.0.1'
        replace: 'ServerActive={{ zabbix_server }}'

    - name: Restart zabbix agent
      systemd:
        name: zabbix-agent
        state: restarted
        enabled: true   

```
</details>

* [Файл инвентаризации](https://github.com/ysatii/Course_project_on_the_block_System_Administration/blob/main/ansible/inventory.ini)
 Файл ansible/inventory.ini  Содержит необходимые настройки 

секция all:vars  
bastion_host= указать адрес машины бастион  
zabbix_server_ip= указать адрес машины с забикс сервером  

секция bastion  
51.250.70.234 - изменить на адрес машины бастион  
