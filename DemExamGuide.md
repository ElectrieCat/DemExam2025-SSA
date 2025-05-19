# Топология
![](images/DemExamGuide_20250515120408769.png)
# Полезности
В процессе настройки нам понадобится скачивать пакеты, и временно до того как настроим собственный днс сервер будем использовать общедоступный, в этой методичке днс сервер колледжа:

```
echo 'nameserver 192.168.100.1' >> /etc/resolv.conf
```

Это временная настройка, после перезапуска сети или устройства она сотрется.

Если преднсатройка днс понадобится, то в параграфе будет об этом сказано

Так-же везде следует сразу же выполнить

```
apt-update
```

при получении доступа в интернет и после прикручивания временного днс сервера, если этого не сделать иногда не удастся поставить пакеты

Полезные команды Vim
```
По умолчанию после открытия файла vim находится в режиме команд

Переход в режим редактирования из режима команд
i режим редактирования

Клавиша ESC - переход в командный режим, перед выполнением команд в него нужно переходить из режима редактирования
Функции в режиме команд:

Клавиша DEL - удалить символ
:w Сохранить 
:q Закрыть файл 
:q! Закрыть файл без сохранения
:wq! Принудительно записать файл
/<слово> Поиск
n Следующее совпадение в поиске
N Предыдущее совпаденеи в поиске
dd удалить строку
v режим выделения
y скопировать выделенное
c вырезать выделенное
p вставить

Выплнить команду - Enter

В обоих режимах доступно управление курсором через стрелочки и клавиша DEL
```
# Порядок настройки
В каждом оглавлении есть номер задания, а так же номер его очереди настройки в формате [NUM], чем меньше номер тем раньше должен быть выполнен этот пункт

# Модуль 1 

## 1. [1] Произведите базовую настройку устройств
Настройте имена устройств согласно топологии. Используйте полное доменное имя.

На всех устройствах в соответствии с таблицей записей:

```
hostnamectl hostname hq-rtr.au-team.irpo; exec bash
```

IP-адрес должен быть из приватного диапазона, в случае, если сеть
локальная, согласно RFC1918

Локальная сеть в сторону HQ-SRV(VLAN100) должна вмещать не более 64 адресов
```
Address:        172.16.100.1
Network:        172.16.100.0/26
Netmask:        255.255.255.192 = 26
Broadcast:      172.16.100.63
HostMin:        172.16.200.1
HostMax:        172.16.200.14
```

Локальная сеть в сторону HQ-CLI(VLAN200) должна вмещать не
более 16 адресов
```
Address:        172.16.200.1
Network:        172.16.200.0/28
Netmask:        255.255.255.240 = 28
Broadcast:      172.16.200.15
HostMin:        172.16.200.1
HostMax:        172.16.200.14
```

Локальная сеть в сторону BR-SRV должна вмещать не более 32 адресов
```
Address:        172.16.0.1
Network:        172.16.0.0/27
Netmask:        255.255.255.224 = 27
Broadcast:      172.16.0.31
HostMin:        172.16.0.1
HostMax:        172.16.0.30
```

Локальная сеть для управления(VLAN999) должна вмещать не
более 8 адресов
```
Address:        172.16.99.1
Network:        172.16.99.0/29
Netmask:        255.255.255.248 = 29
Broadcast:      172.16.99.7
HostMin:        172.16.99.1
HostMax:        172.16.99.6
```

На всех устройствах необходимо сконфигурировать IPv4

Пример для HQ-SRV, на BR-SRV по аналогии c адресом 172.16.0.2/27 и шлюзом 172.16.0.1
```
mkdir /etc/net/ifaces/eth0
cd /etc/net/ifaces/eth0
echo "172.16.100.2/26" > ipv4address
echo "default via 172.16.100.1" > ipv4route
vim options
```
Вставить конфиг:
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=static
```
Применим настройки сети
```
systemctl restart network
```

Настройка внешнего интерфейса к **ISP** на **HQ-RTR**, на **BR-RTR** так же но с адресом 172.16.5.2/28 и шлюзом 172.16.5.1
```
mkdir /etc/net/ifaces/eth0
cd /etc/net/ifaces/eth0
echo "172.16.4.2/28" > ipv4address
echo "default via 172.16.4.1" > ipv4route
vim options
```
Вставить конфиг:
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=static
```
Так-же в файле /etc/net/sysctl.conf на обоих роутерах должна быть следующая настройка чтобы разрешить пересылку пакетов
```
net.ipv4.ip_forward = 1
```
Применим настройки сети
```
systemctl restart network
```
## 2. [2] Настройка ISP
Настроим верхний интерфейс с dhcp
```
mkdir /etc/net/ifaces/eth0
vim /etc/net/ifaces/eth0/options
```
Вставить конфиг:
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=dhcp
```
Настроим интерфейс к **HQ-RTR**
```
mkdir /etc/net/ifaces/eth1
cd /etc/net/ifaces/eth1
echo "172.16.4.1/28" > ipv4address 
vim options
```
Вставить конфиг:
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=static
```
Настроим интерфейс к **BR-RTR**
```
mkdir /etc/net/ifaces/eth2
cd /etc/net/ifaces/eth2
echo "172.16.5.1/28" > ipv4address 
vim options
```
Вставить конфиг:
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=static
```
Так-же на **BR-RTR** настроим адрес на eth1
```
mkdir /etc/net/ifaces/eth1
cd /etc/net/ifaces/eth1
echo "172.16.0.1/27" > ipv4address
vim options
```
Вставим конфиг
```
DISABLED=no
ONBOOT=yes
TYPE=eth
BOOTPROTO=static
```
Перезагрузим сеть
```
systemctl restart network
```
На **ISP** настройте динамическую сетевую трансляцию в сторону
HQ-RTR и BR-RTR для доступа к сети Интернет
```
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
```
Так-же в файле /etc/net/sysctl.conf должна быть следующая настройка чтобы разрешить пересылку пакетов

```
net.ipv4.ip_forward = 1
```

После всей настройки перезагрузим сеть:
```
systemctl restart network
```
Проверим работоспособность с **ISP**,**HQ-RTR**,**BR-RTR**
```
ping 1.1.1.1
```
## 3. [9] Создание локальных учетных записей
**На HQ-SRV и BR-SRV**
```
apt-get install sudo -y
useradd -u 1010 sshuser
usermod -aG wheel sshuser
passwd sshuser
# Дважды вводим P@ssw0rd
vim /etc/sudoers
В файле /etc/sudoers раскомментить строку WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
Примечание: при редактировании через что либо кроме visudo этот файл - ro, чтобы его записать в виме введите :wq!
```

Проверка
```
id sshuser
sudo -i
```
**На HQ-RTR и BR-RTR**
```
apt-get install sudo -y
useradd net_admin
usermod -aG wheel net_admin
passwd net_admin
# Дважды вводим P@ssword
vim /etc/sudoers
В файле /etc/sudoers раскомментить строку WHEEL_USERS ALL=(ALL:ALL) NOPASSWD: ALL
```
Проверка
```
sudo -i
```
## 4. [3] Настройте на интерфейсе HQ-RTR в сторону офиса HQ виртуальный коммутатор:
Создаем папки интерфейсов
```
cd /etc/net/ifaces
mkdir eth1.100
mkdir eth1.200
mkdir eth1.999
```
В каждой папке файл options с соответствующим VID (100,200,999)
```
TYPE=ovsport
BRIDGE=HQ-SW
VID=100
BOOTPROTO=static
```
В каждой папке файл ipv4address, с соответствующим адресом для влана
```
172.16.100.1/26 #  eth1.100
172.16.200.1/28 #  eth1.200
172.16.99.1/29 #  eth1.999
```
Настроим так наш бридж HQ-SW
```
mkdir eth1
mkdir HQ-SW
vim HQ-SW/options
```
Вставим конфиг
```
TYPE=ovsbr
HOST='eth1'
```
В файле default/options отключим затирание при перезагрузке
```
OVS_REMOVE=no
```
Применим все настройки
```
systemctl enable --now openvswitch
systemctl restart network openvswitch
```
Проверим работоспособность маршрутизации между сетями вланов и настройку бриджа
```
ovs-vsctl show
```
Должно вывести:
```
    Bridge HQ-SW
        Port eth1
            trunks: [100, 200]
            Interface eth1
        Port eth1.100
            tag: 100
            Interface eth1.100
                type: internal
        Port HQ-SW
            Interface HQ-SW
                type: internal
        Port eth1.999
            tag: 999
            Interface eth1.999
                type: internal
        Port eth1.200
            tag: 200
            Interface eth1.200
                type: internal
```
На **HQ-SRV**
```
ping 172.16.200.1 # Должно сработать
```
## 5. [10] Настройка безопасного удаленного доступа на серверах HQ-SRV и BR-SRV
```
vim /etc/openssh/sshd_config
```
Настроим
```
Port 2024
AllowUsers sshuser
MaxAuthTries 2
Banner /etc/motd
```
Запишем баннер и включим sshd
```
echo "Authorized access only" > /etc/motd
systemctl enable --now sshd
```

Проверим с тех же HQ-SRV,BR-SRV с помощью `ssh sshuser@localhost -p 2024` и паролем P@ssw0rd
## 6. [4] Между офисами HQ и BR необходимо сконфигурировать ip туннель
На **HQ-RTR**
```
mkdir /etc/net/ifaces/tunnel
cd /etc/net/ifaces/tunnel
echo "10.0.0.1/30" > ipv4address
vim options
```
Вставим настройки:
```
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=172.16.4.2
TUNREMOTE=172.16.5.2
TUNOPTIONS="ttl 64"
HOST=eth0
ONBOOT=yes
DISABLED=no
BOOTPROTO=static
```
Перезагрузим сеть
```
systemctl restart network
```

На **BR-RTR**
```
mkdir /etc/net/ifaces/tunnel
cd /etc/net/ifaces/tunnel
echo "10.0.0.2/30" > ipv4address
vim options
```
Вставим настройки:
```
TYPE=iptun
TUNTYPE=gre
TUNLOCAL=172.16.5.2
TUNREMOTE=172.16.4.2
TUNOPTIONS="ttl 64"
HOST=eth0
ONBOOT=yes
DISABLED=no
BOOTPROTO=static
```
Перезагрузим сеть
```
systemctl restart network
```
Проверим работоспособность
```
ping 10.0.0.1
```
## 7. [6] Обеспечьте динамическую маршрутизацию

Поставим временный днс на обоих роутерах
```
echo "nameserver 192.168.100.1" > /etc/resolv.conf
```
Будем использовать OSPF, приступим к настройке и установке для HQ-RTR и по аналогии ставим так-же на BR-RTR:
```
apt-get install frr -y 
vim /etc/frr/daemons
Настроим ospfd=yes
systemctl enable frr --now
```

**Переходим в консоль конфигурации frr**

Тут настройка по порядку:
```
vtysh

conf t
router ospf
network X.X.X.X/X area 0 (Все кроме wan)
passive-interface default
ex

interface tunnel
no ip ospf passive
ip ospf authentication
ip ospf authentication-key P@ssw0rd
do write
#CTRL+C чтобы выйти или ex чтобы выйти в предыдущее меню
```
По аналогии делаем со вторым роутером, проверить через `show ip ospf neighbor` и если сосед появился то всё ок.
Так же с **HQ-SRV** пинганём **BR-SRV**
```
ping 172.16.0.2
```

Если что-то не работает, можно проверить что нет настройки
`no ip forwarding`
И что есть настройка в интерфейсе tunnel
`ip ospf network broadcast`
А так же что включена пересылка пакетов
```
sysctl -a | grep "net.ipv4.ip_forward" # должно быть 1
```
## 8. [5] Настройка динамической трансляции адресов.
Настройте динамическую трансляцию адресов для обоих офисов.
На **HQ-RTR, BR-RTR** сделать nat через iptables
```
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
iptables-save > /etc/sysconfig/iptables
systemctl enable --now iptables
```
Проверим содержание таблицы nat в iptables
```
iptables -L -t nat
```
## 9. [8] Настройка протокола динамической конфигурации хостов.
На **HQ-RTR**
Установим и настроим dhcp сервер
```
apt-get install dhcp-server -y
cd /etc/dhcp/
mv dhcpd.conf.sample dhcpd.conf
vim dhcpd.conf
```
Вставим конфиг:
```
ddns-update-style none;

subnet 172.16.200.0 netmask 255.255.255.240 {
        option routers                  172.16.200.1;
        option subnet-mask              255.255.255.240;

        option domain-name              "au-team.irpo";
        option domain-name-servers      172.16.100.2;

        range 172.16.200.2 172.16.200.14;
        default-lease-time 21600;
        max-lease-time 43200;
}

```
Настроим dhcp на интерфейсе
```
vim /etc/sysconfig/dhcpd
Отредактировать строку: DHSPDARGS=eth1.200
systemtctl enable --now dhcpd.service
```

**На HQ-CLI**
```
systemctl restart NetworkManager # Чтоб наверняка
```
Проверка 
```
ip a
cat /etc/resolv.conf 
```

Клиент должен получить айпи адрес т.к. стоит NetworkManager который по умолчанию включает dhcp клиент на интерфейсе
![](images/МетодичкаДемоэкзамен_20250327173234603.png)

## 10. [7] Настройка DNS для офисов HQ и BR.
**На HQ-SRV**
Установим временный днс сервер
```
echo "nameserver 192.168.100.1" > /etc/resolv.conf
```
Начнём установку bind
```
apt-get install bind bind-utils -y
vim /etc/bind/options.conf
```

В этом файле вносим изменения и раскомментируем параметры или пишем их сами:
```
options {
        version "unknown";
        directory "/etc/bind/zone";
        dump-file "/var/run/named/named_dump.db";
        statistics-file "/var/run/named/named.stats";
        recursing-file "/var/run/named/named.recursing";
        secroots-file "/var/run/named/named.secroots";

        pid-file none;

        dnssec-validation no;
        listen-on { any; };
        listen-on-v6 { ::1; };
        forwarders {  192.168.100.1; };
        allow-query { any; };
        allow-query-cache { any; };
        allow-recursion { any; };
};

```

Добавляем зоны в конце файла:
```
zone "au-team.irpo" {
  type master;
  file "/etc/bind/zone/au-team.irpo";
};
zone "16.172.in-addr.arpa" {
  type master;
  file "/etc/bind/zone/16.172.in-addr.arpa";
};
```
Создаем файлы зон и конфигурируем их:
```
cd /etc/bind/zone
cp localhost au-team.irpo
cp localhost 16.172.in-addr.arpa
chown root:named au-team.irpo 16.172.in-addr.arpa
```

Файл 16.172.in-addr.arpa
```
$TTL    1D
@       IN      SOA     hq-srv.au-team.irpo. root.au-team.irpo. (
                                2025020600      ; serial
                                12H             ; refresh
                                1H              ; retry
                                1W              ; expire
                                1H              ; ncache
                        )
@       IN      NS      hq-srv.au-team.irpo.
1.99    IN      PTR     hq-rtr
2.100   IN      PTR     hq-srv
2.200   IN      PTR     hq-cli
```
Файл au-team.irpo
```
$TTL    1D
@       IN      SOA     hq-srv.au-team.irpo. root.au-team.irpo. (
                                2025020600      ; serial
                                12H             ; refresh
                                1H              ; retry
                                1W              ; expire
                                1H              ; ncache
                        )
        IN      NS      hq-srv.au-team.irpo.
hq-rtr  IN      A       172.16.99.1
br-rtr  IN      A       172.16.0.1
hq-srv  IN      A       172.16.100.2
hq-cli  IN      A       172.16.200.2
br-srv  IN      A       172.16.0.2
moodle  IN      CNAME   hq-rtr.au-team.irpo.
wiki    IN      CNAME   hq-rtr.au-team.irpo.
```
Включим автозапуск dns сервера
```
systemctl enable --now bind
```

Теперь на всех машинах установим этот днс сервер как основной а так же добавим наш домен для автодополнения запросов по коротким именам.
Не забудьте, на **HQ-CLI** по заданию dns должен быть выдан через dhcp!
При применении этого на **HQ-SRV** так же после нужно перезагрузить bind
```
echo -e "nameserver 172.16.100.2\ndomain au-team.irpo" > /etc/net/ifaces/lo/resolv.conf && systemctl restart network
```
Проверка
```
ping hq-rtr
```
Примечание: 
- Eсли презагружали сеть, то требуется перезагрузить и bind тоже
- Eсли возникают ошибки с интерфейсом или ip адресом, то перезагрузить машину
- Для отладки и проверки работы днс можно использовать nslookup и dig
## 11. [11] Настройте часовой пояс на всех устройствах, согласно месту проведения экзамена.
```
apt-get install tzdata -y
timedatectl set-timezone Europe/Moscow
```
Проверим
```
timedatectl
```
# Модуль 2
## 1. Настройте доменный контроллер Samba на машине BR-SRV.
Параметры установки домена, которые не указаны ниже оставляем по умолчанию - нажимаем "Enter".
```
apt-get install samba-dc -y
rm -f /etc/samba/smb.conf
rm -f /etc/krb5.conf
samba-tool domain provision
DNS backend: BIND9_FLATFILE
Пароль администратора и пользователей - P@ssw0rd
samba-tool group add hq
samba-tool user add user<1-5>.hq P@ssw0rd
samba-tool group addmembers hq user<1-5>.hq
scp -P 2024 /var/lib/samba/bind-dns/dns/au-team.irpo.zone sshuser@172.16.100.2:/home/sshuser/bind9_flatfile
systemctl enable --now samba
```

Импорт пользователей:
Если на момент подготовки не будет файла "users.csv", его можно создать вручную
```
vim /opt/users.csv

usr1,long!pass1
usr2,long!pass2
usr3,long!pass3
usr4,long!pass4
```
Напишем скрипт:
```
cd /opt
vim import.sh
```

Содержание import.sh
```
#!/bin/bash

CSVFILE="users.csv"
while IFS=',' read -r UN PW; do
    UN=$(echo $UN | xargs)
    PW=$(echo $PW | xargs)
    echo "Adding user: $UN with password: $PW"
    samba-tool user add "$UN" "$PW"
done < "$CSVFILE"
```

Запуск:
```
sh import.sh
```

Пример успешного выполнения:

![](images/DemExamGuide_20250331193909284.png)

На **HQ-SRV**

Удалить все строки сверху в файле /home/sshuser/bind9_flatfile до красной линии
![](images/DemExamGuide_20250330160424331.png)

И затем сделать 
```
cat /home/sshuser/bind9_flatfile >> /etc/bind/zone/au-team.irpo
systemctl restart bind
```

На **HQ-CLI**

Меню > Центр управления > Центр управления системой > Ввести пароль для root > Аутентификация > Домен Active Directory
Нажать "Применить" и ввести пароль для Administrator (P@ssw0rd)
Перезагрузить компьютер и попробовать войти под одним из пользователей домена

Реализуем повышение привелегий для пользоваталей группы hq, выполнять из-под root
```
apt-get install sudo
echo "%hq  ALL=(ALL) NOPASSWD: /bin/grep,/usr/bin/id,/bin/cat" >> /etc/sudoers
chmod 4755 /usr/bin/sudo
```

Проверка: зайти под одним из пользователей домена и прописать `sudo id`, в начале вывода строки должно показать uid=0(root)

## 2. Сконфигурируйте файловое хранилище
На **HQ-SRV**
Введем `lsblk` чтобы посмотреть диски в системе
```
Используем свободные диски по 1 гигу.
mdadm --create /dev/md0 --level=0 --raid-devices=3 /dev/vdb /dev/vdc /dev/vdd
mkfs.ext4 /dev/md0
mkdir /raid0
cat /proc/mdstat - Ждём пока завершится сборка
mdadm --detail --scan >> /etc/mdadm.conf
vim /etc/fstab
```

Между элементов - табы
```
/dev/md0	/raid0	ext4	defaults	0	0
```
Попробуем смонтировать raid
```
mount -a
```
Настроим nfs
```
apt-get install rpcbind nfs-server -y
mkdir /raid0/nfs
systemctl enable --now nfs
vim /etc/exports
```

```
/raid0/nfs 172.16.200.0/28(no_root_squash,subtree_check,rw)
```

```
exportfs -ra
```

На **HQ-CLI**
От root
```
mkdir /mnt/nfs
vim /etc/fstab
```


Между элементами - табы
```
hq-srv:/raid0/nfs	/mnt/nfs	nfs	defaults	0	0
```
Для проверки - от root
```
mount -a
mount | grep nfs
touch /mnt/nfs/icanwrite
```

Вывод команды: раздел должен быть в выдаче grep как примонтированный и должна быть возможность записи на него
## 3. Настройте службу сетевого времени на базе сервиса chrony
На **HQ-RTR**
```
apt-get install chrony -y
vim /etc/chrony.conf
```

Закомментируем строчку с пулом и пропишем под ней следующие настройки:
```
#pool pool.ntp.org iburst
server 127.0.0.1 iburst
allow 0.0.0.0/0
local stratum 5
```

```
systemctl restart chronyd
```

На **HQ-SRV, HQ-CLI, BR-RTR, BR-SRV**
```
apt-get install chrony -y
vim /etc/chrony.conf
```
В случае, если в файле есть данные строчки - их надо закомментировать
```
pool pool.ntp.org iburst
server 192.168.100.1
pool AU-TEAM.IRPO iburst
```
Пропишем следующие настройки:
```
server 172.16.99.1 iburst
```

```
systemctl restart chronyd
chronyc makestep
chronyc sources
```

Stratum должен быть 5, и статус нашего NTP сервера - 200
## 4. Сконфигурируйте ansible на сервере BR-SRV
Преднастройка машин от root:
На **HQ-RTR, BR-RTR, CLI-HQ**
```
systemctl enable --now sshd
```

На **HQ-SRV**
```
apt-get install -y python3
```

Настройка Ansible на **BR-SRV**
```
apt-get install -y ansible
cd /etc/ansible
```
```
vim ansible.cfg
```
В файле ansible.cfg раскоментируем строку `host_key_checking = False`
Отредактируем файл hosts:
```
vim hosts
```
Файл должен иметь следующее содержание:
```
[servers]
HQ-SRV ansible_host=hq-srv

[clients]
HQ-CLI ansible_host=hq-cli

[routers]
HQ-RTR ansible_host=hq-rtr
BR-RTR ansible_host=br-rtr

[all:vars]
ansible_ssh_pass=P@ssw0rd
ansible_python_interpreter=/usr/bin/python3

[servers:vars]
ansible_ssh_port=2024
ansible_ssh_user=sshuser

[clients:vars]
ansible_ssh_user=user
ansible_ssh_pass=resu

[routers:vars]
ansible_ssh_user=net_admin
```

Проверка:
```
ansible -m ping all
```

Должно вывести:

![](images/DemExamGuide_20250331212012678.png)
## 5. Развертывание приложений в Docker на сервере BR-SRV.
```
apt-get install -y docker-engine docker-compose
ln /usr/lib/docker/cli-plugins/docker-compose /bin/
systemctl enable --now docker
cd /root
vim wiki.yml
```

Запишем в файл следующее:
```
version: '3'
services:
  wiki:
    image: mediawiki
    restart: always
    ports:
      - 8080:80
    volumes:
      - images:/var/www/html/images
      #- ./LocalSettings.php:/var/www/html/LocalSettings.php
    links:
      - mariadb
  mariadb:
    image: mariadb
    restart: always
    container_name: mariadb
    environment:
      MARIADB_ROOT_PASSWORD: toor
      MARIADB_DATABASE: mediawiki
      MARIADB_USER: wiki
      MARIADB_PASSWORD: WikiP@ssw0rd
    volumes:
      - dbvolume:/var/lib/mysql
volumes:
  images:
  dbvolume:
```

Поднимем контейнеры и настроим способ аутентификации для пользователя wiki:
```
docker-compose -f wiki.yml up -d
systemctl enable --now sshd
```

На **HQ-CLI**
Авторизируемся под пользователем "user"

Через браузер открываем 172.16.0.2:8080
![](images/DemExamGuide_20250402011827882.png)
Ставим русский язык
![](images/DemExamGuide_20250401224506430.png)
~~Внимательно читаем условия~~ Проматываем вниз и соглашаемся со всем
![](images/DemExamGuide_20250401224603147.png)
Заполняем данные для MariaDB
![](images/DemExamGuide_20250402012447235.png)
Жмём далее
![](images/DemExamGuide_20250402012536867.png)
Почти готово, вводим оставшиеся данные
![](images/DemExamGuide_20250402013919320.png)
![](images/DemExamGuide_20250402013952486.png)
![](images/DemExamGuide_20250402020941021.png)
Вас перебросит на эту страницу и автоматичеки скачается файл с настройками, если он не скачался нажмите `Загрузить`
![](images/DemExamGuide_20250402021137986.png)

Теперь необходимо отправить этот файл на BR-SRV.
Зайдем в консоль и перейдем под root:
```
cd /home/user/Загрузки
scp -P 2024 LocalSettings.php sshuser@br-srv:/home/sshuser/
```

На **BR-SRV**
```
mv /home/sshuser/LocalSettings.php /root/
docker-compose -f wiki.yml down
vim wiki.yml
```

Раскомментируем строку (убрать символ #)
```
#- ./LocalSettings.php:/var/www/html/LocalSettings.php
```
Поднимем контейнер
```
docker-compose -f wiki.yml up -d
```

На **HQ-CLI**
Немного ждём и обновляем страницу, видим что вики теперь работает
![](images/DemExamGuide_20250402025529000.png)

На **BR-SRV**
Если вы что-то настроили не так и нужно сбросить контейнеры, используйте:
```
docker-compose -f wiki.yml down -v
```

## 6. На маршрутизаторах сконфигурируйте статическую трансляцию портов
На **BR-RTR**
```
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 2024 -j DNAT --to-destination 172.16.0.2:2024
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 80 -j DNAT --to-destination 172.16.0.2:8080
iptables-save -f /etc/sysconfig/iptables
```

Проверяем работу Wiki с HQ-CLI
В браузере открываем 172.16.5.2:80

Проверяем работу ssh с HQ-RTR
```
ssh sshuser@172.16.5.2 -p 2024
```

На **HQ-RTR**
```
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 2024 -j DNAT --to-destination 172.16.100.2:2024
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 80 -j DNAT --to-destination 172.16.100.2:80
iptables-save -f /etc/sysconfig/iptables
```

Проверяем с BR-RTR
```
ssh sshuser@172.16.4.2 -p 2024
```

## 7. Запустите сервис moodle на сервере HQ-SRV
```
apt-get install -y moodle-local-mysql moodle moodle-apache2 mariadb-server
systemctl enable --now httpd2.service mysqld.service
mariadb -u root
CREATE DATABASE moodledb DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'moodle'@'localhost' IDENTIFIED VIA mysql_native_password USING PASSWORD('P@ssw0rd');
GRANT ALL PRIVILEGES ON moodledb.* TO 'moodle'@'localhost';
FLUSH PRIVILEGES;
exit
vim /etc/php/8.2/apache2-mod_php/php.ini
```

Раскомментируем и приводим к нужному виду:
```
max_input_vars = 5000
```

```
systemctl restart httpd2.service
```

На **CLI-HQ**
В браузере откроем http://172.16.100.2/moodle
![](images/DemExamGuide_20250402222028021.png)
![](images/DemExamGuide_20250402222100250.png)
![](images/DemExamGuide_20250402222149141.png)
![](images/DemExamGuide_20250402222239660.png)
![](images/DemExamGuide_20250402222321308.png)
![](images/DemExamGuide_20250402222353993.png)
Ждём и проматываем вниз
![](images/DemExamGuide_20250402222524917.png)
Заполняем данные
![](images/DemExamGuide_20250402222946539.png)
![](images/DemExamGuide_20250402223216611.png)
![](images/DemExamGuide_20250402223355860.png)
![](images/DemExamGuide_20250402223455768.png)
![](images/DemExamGuide_20250402223521747.png)
![](images/DemExamGuide_20250402223549258.png)
![](images/DemExamGuide_20250402223808191.png)
![](images/DemExamGuide_20250402223948916.png)
Проматываем вниз
![](images/DemExamGuide_20250402224020499.png)
Ставим такие параметры если они не установились сами
![](images/DemExamGuide_20250402224223247.png)
Проматываем вниз
![](images/DemExamGuide_20250402224302360.png)
Выключаем режим редактирования
![](images/DemExamGuide_20250402224532920.png)
Нажимаем везде "В начало"
![](images/DemExamGuide_20250402224649769.png)
Настройка завершена

## 8. Настройте веб-сервер nginx как обратный прокси-сервер на ISP
```
apt-get install nginx -y
vim /etc/nginx/sites-available.d/proxy.conf
```

Заполняем так:
```
server {
 listen 80;
 server_name moodle.au-team.irpo;
 location / {
  proxy_pass http://172.16.4.2:80;
 }
}
server {
 listen 80;
 server_name wiki.au-team.irpo;
 location / {
  proxy_pass http://172.16.5.2:80;
 }
}
```
Добавим сайт во включенные и добавим nginx в автозагрузку
```
ln /etc/nginx/sites-available.d/proxy.conf /etc/nginx/sites-enabled.d/
systemctl enable --now nginx.service
```
На **HQ-SRV**

Изменим конфигурацию config.php 
```
$CFG->wwwroot   = 'http://moodle.au-team.irpo/moodle';
```
После на следующей строчке добавим новый параметр 
```
$CFG->reverseproxy  =  true;
```
Перезагрузим службу 
```
systemctl restart httpd2
```

Проверяем с HQ-CLI

В браузере открываем страницы

```
http://moodle.au-team.irpo/moodle
http://wiki.au-team.irpo
```
## 9. Удобным способом установите приложение Яндекс Браузере для организаций на HQ-CLI
Из-под root
```
apt-get install -y yandex-browser-stable
```

# Модуль 3
## 1. Выполните миграцию на новый контроллер домена BR-SRV с BR-DC, являющийся наследием
### !!!Доделать!!!

* Скрипты искать в папке `scripts`

На **BR-DC**
Настроить подключение к сети и использование HQ-SRV для DNS
![](images/DemExamGuide_20250425005904215.png)
![](images/DemExamGuide_20250425005950122.png)
![](images/DemExamGuide_20250425010056054.png)
![](images/DemExamGuide_20250425010132469.png)
Заполнить всё как показано
![](images/DemExamGuide_20250425010157530.png)
Сохранить и завершить настройку сети, возможно потребуется подождать подключения

Рекомендуется установить WinSCP, Putty

Выполнить export.ps1
![](images/DemExamGuide_20250425010431514.png)

## 2. Выполните настройку центра сертификации на базе HQ-SRV

```
apt-get install -y openssl openssl-gost-engine
control openssl-gost enabled
cd
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:TCB -out ca.key
openssl req -new -x509 -md_gost12_256 -days 365 -key ca.key -out ca.cer -subj "/CN=AU-Team-CA"
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out web.key
openssl req -new  -md_gost12_256 -key web.key -out web.csr -subj "/CN=*.au-team.irpo"
openssl x509 -req -in web.csr -CA ca.cer -CAkey ca.key -CAcreateserial -out web.cer -days 365
```
Преднастройка для создания CRL
```
touch index.txt
echo 00 > crlnumber
vim /var/lib/ssl/openssl.cnf
```

Настроим следующие строки в файле
```
[ ca ]
default_ca      = CA_default            # The default ca section

####################################################################
[ CA_default ]

dir             = ./            # Where everything is kept
certs           = $dir          # Where the issued certs are kept
crl_dir         = $dir          # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
#unique_subject = no                    # Set to 'no' to allow creation of
                                        # several ctificates with same subject.
new_certs_dir   = $dir          # default place for new certs.

certificate     = $dir/ca.cer   # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
crl             = $dir/crl.pem          # The current CRL
private_key     = $dir/ca.key   # The private key

x509_extensions = usr_cert              # The extentions to add to the cert

# Comment out the following two lines for the "traditional"
# (and highly broken) format.
name_opt        = ca_default            # Subject Name options
cert_opt        = ca_default            # Certificate field options

# Extension copying option: use with caution.
# copy_extensions = copy

# Extensions to add to a CRL. Note: Netscape communicator chokes on V2 CRLs
# so this is commented out by default to leave a V1 CRL.
# crlnumber must also be commented out to leave a V1 CRL.
# crl_extensions        = crl_ext

default_days    = 365                   # how long to certify for
default_crl_days= 30                    # how long before next CRL
default_md      = md_gost12_256                 # which md to use.
preserve        = no                    # keep passed DN ordering
```
Создадим CRL
```
openssl ca -gencrl -out ca.crl dgst:gost
```

Перешлём нужные файлы на машины
```
scp ca.crl ca.cer user@hq-cli:/home/user
scp web.* net_admin@hq-rtr:/home/net_admin
```

На **HQ-RTR**
```
mkdir /etc/ssl/certs -p
mv /home/net_admin/web.* /etc/ssl/certs/
vim /etc/nginx/sites-available.d/default.conf
```
Настраиваем так
```
server {
        listen  443 ssl;
        server_name moodle.au-team.irpo;
        ssl_certificate /etc/ssl/certs/web.cer;
        ssl_certificate_key /etc/ssl/certs/web.key;
        ssl_ciphers GOST2012-GOST8912-GOST8912:HIGH:MEDIUM;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        location /moodle {
                proxy_pass http://hq-srv.au-team.irpo/moodle;
        }
        location / {
                proxy_pass http://br-srv.au-team.irpo:8080/;
        }
}
```

Перезагрузим nginx

```
systemctl restart nginx
```

На **HQ-CLI**
```
mv /home/user/ca.cer /etc/pki/ca-trust/source/anchors/
update-ca-trust
trust list | grep Team #Проверим что система доверяет нашему CA
apt-get install cryptopro-preinstall
tar -xf linux-amd64.tgz #Архив качаем с сайта КриптоПро после регистрации, нам нужен "Актуальный" для Linux RPM x64
cd linux-amd64
apt-get install cprocsp-curl* lsb-cprocsp-base* lsb-cprocsp-capilite* lsb-cprocsp-kc1-64* lsb-cprocsp-rdr-64*
./install.sh
ln /opt/cprocsp/bin/amd64/* /bin
certmgr -install -store -mRoot -file /etc/pki/ca-trust/source/anchors/ca.cer #Вводим "o"
certmgr -install -store mRoot -crl -file /home/user/ca.crl
```
Включим поддержку шифрования по ГОСТу в яндексе, для этого нажать "Три полоски" (сверху правее)> Настройки > Системные > Подключаться к сайтам использующим шифрование ГОСТ

Проверить открыв в яндекс браузере https://wiki.au-team.irpo, если нет предупреждений то всё сработало

## 3 Перенастройте ip-туннель с базового до уровня туннеля, обеспечивающего шифрование трафика
На **HQ-RTR, BR-RTR**
```
apt-get install -y strongswan
```
На **HQ-RTR**
```
vim /etc/strongswan/ipsec.conf
```

```
conn tungre
        left=172.16.4.2
        leftsubnet=0.0.0.0/0
        right=172.16.5.2
        rightsubnet=0.0.0.0/0
        ike=aes256-sha256-ecp256
        esp=aes256-sha256!
        leftprotoport=gre
        rightprotoport=gre
        authby=secret
        auto=start
        type=tunnel
```

```
vim /etc/strongswan/ipsec.secrets
```
Добавить строку
```
172.16.4.2 172.16.5.2 : PSK "P@ssw0rd"
```

На **BR-RTR**
```
vim /etc/strongswan/ipsec.conf
```

```
conn tungre
        left=172.16.5.2
        leftsubnet=0.0.0.0/0
        right=172.16.4.2
        rightsubnet=0.0.0.0/0
        ike=aes256-sha256-ecp256
        esp=aes256-sha256!
        leftprotoport=gre
        rightprotoport=gre
        authby=secret
        auto=start
        type=tunnel
```

```
vim /etc/strongswan/ipsec.secrets
```
Добавить строку
```
172.16.5.2 172.16.4.2 : PSK "P@ssw0rd"
```
На **HQ-RTR, BR-RTR**
```
systemctl enable --now ipsec.service
ipsec status # Должно появиться ESTABLISHED соединение
ip xfrm state # Появится правило для протокола gre и src,dst адресов тоннеля
```
## 4. Настройте межсетевой экран на маршрутизаторах HQ-RTR и BR-RTR на сеть в сторону ISP

На **HQ-RTR, BR-RTR**
```
# Запрещаем все подключения во внутреннюю сеть из интернета
iptables -A INPUT -i eth0 -j REJECT
iptables -A FORWARD -i eth0 -j REJECT
# Обеспечиваем работу протоколов
iptables -I FORWARD -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -I INPUT -i eth0 -p tcp --dport 443 -j ACCEPT
iptables -I FORWARD -i eth0 -p tcp --dport 443 -j ACCEPT
iptables -I FORWARD -i eth0 -p udp --dport 53 -j ACCEPT
iptables -I INPUT -i eth0 -p udp --dport 123 -j ACCEPT
iptables -I INPUT -i eth0 -p icmp -j ACCEPT
iptables -I FORWARD -i eth0 -p icmp -j ACCEPT
iptables -I INPUT -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# Чтобы работала ранее настроенная переадресация
iptables -I FORWARD -i eth0 -p tcp --dport 2024 -j ACCEPT
# Разрешаем доступ к роутеру из интернета по ssh
iptables -I INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
```
Отдельно на **BR-RTR**
```
iptables -I FORWARD -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables-save > /etc/sysconfig/iptables
```
Проверка с **HQ-RTR,BR-RTR**

Проверять нужно с роутера напротив и использовать внешние адреса, для проверки можно использовать nmap, ping или для наглядности wget, curl, nslookup:
```
apt-get install -y nmap curl wget bind-utils
```
Как пользоваться
```
nmap IP -p PORT # Для TCP
nmap IP -p PORT -sU # Для UDP
wget IP:PORT
curl IP:PORT
curl http[s]://IP[:PORT]
nslookup DOMAIN DNS_SRV_IP
ping IP
```
Проверяем что после применения поднимется ipsec на роутерах
```
ipsec restart
ipsec status
```

## 5. Настройте принт-сервер cups на сервере HQ-SRV.
```
apt-get install -y cups cups-pdf
cupsctl --remote-admin --remote-any --share-printers
```

На **HQ-CLI**
От root
```
lpadmin -p Cups-PDF -E -v ipp://hq-srv:631/printers/Cups-PDF -m everywhere
lpoptions -d Cups-PDF
echo "Test print job" | lp -d Cups-PDF
```

В браузере откроем
https://hq-srv.au-team.irpo:631/jobs
![](images/DemExamGuide_20250407180506222.png)
Если задание появилось, то всё настроено правильно.
## 6. Реализуйте логирование при помощи rsyslog на устройствах HQ-RTR, BR-RTR, BR-SRV

На **HQ-SRV**
```
apt-get install -y rsyslog-classic
vim /etc/rsyslog.d/00_common.conf
rm -f /etc/rsyslog.d/10_classic.conf
```

```
Раскомментировать строки
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")

module(load="imtcp") # needs to be done just once
input(type="imtcp" port="514")

Добавить в конец файла
$template RemoteLogs, "/opt/%HOSTNAME%/%HOSTNAME%.log"
*.* ?RemoteLogs
& ~
```

```
systemctl enable --now rsyslog
```

На **HQ-RTR, BR-RTR, BR-SRV**

```
apt-get install -y rsyslog-classic
vim /etc/rsyslog.d/00_common.conf
```

```
Раскомментировать
module(load="imjournal") # provides support for systemd-journald logging
module(load="imuxsock")  # provides support for local system logging (e.g. via logger command)
module(load="imklog")    # provides kernel logging support (previously done by rklogd)
module(load="immark")    # provides --MARK-- message capability

Добавить в конец файла
*.warning @@hq-srv:514
```
```
systemctl enable --now rsyslog
```

На **HQ-SRV**
Проверим что логи присылаются `ls /opt`

Настроим ротацию

```
vim /etc/logrotate.d/rsyslog
```
Вставим настройки
```
/opt/*/*.log {
    weekly
    size 10M
    compress
    delaycompress
    missingok
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        /sbin/systemctl reload rsyslog > /dev/null 2>&1 || true
    endscript
}
```
Выполним
```
EDITOR=vim crontab -e
Введите:
0 0 * * 0 /usr/sbin/logrotate -f /etc/logrotate.d/rsyslog
Выйти из vim :wq
```

Проверим работу:
```
logrotate -d /etc/logrotate.d/rsyslog
```

Должно быть выведено, что слишком рано для ротации т.к. логи не достигли нужного размера файла

## 7. На сервере HQ-SRV реализуйте мониторинг устройств с помощью открытого программного обеспечения.
```
apt-get install -y docker-engine docker-compose
systemctl enable --now docker
vim zabbix.yml
```

```
version: "3.9"

services:
 
  zabbix-mariadb:
    image: mariadb
    container_name: zabbix-mariadb
    hostname: zabbix-mariadb
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"
      MYSQL_ROOT_USER: root
      MYSQL_ROOT_PASSWORD: secret
      MYSQL_DATABASE: zabbix
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbixpass
    networks:
      - default
    volumes:
      - /opt/zabbix/mariadb/data:/var/lib/mysql
 
  zabbix-server:
    image: zabbix/zabbix-server-mysql
    container_name: zabbix-server
    hostname: zabbix-server
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"
      DB_SERVER_HOST: zabbix-mariadb
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbixpass
      ZBX_ALLOWUNSUPPORTEDDBVERSIONS=1
    networks:
      default:
        ipv4_address: 172.28.0.254
    depends_on:
      - zabbix-mariadb
 
  zabbix-web:
    image: zabbix/zabbix-web-nginx-mysql
    container_name: zabbix-web
    hostname: zabbix-web
    restart: unless-stopped
    environment:
      TZ: "Europe/Moscow"
      DB_SERVER_HOST: zabbix-mariadb
      MYSQL_USER: zabbix
      MYSQL_PASSWORD: zabbixpass
      ZBX_SERVER_HOST: zabbix-server
      PHP_TZ: "Europe/Moscow"
    ports:
      - 8080:8080
      - 8443:8443
    networks:
      - default
    depends_on:
      - zabbix-mariadb
      - zabbix-server
 
networks:
  default:
    ipam:
      driver: default
      config:
        - subnet: 172.28.0.0/16
```

```
docker compose -f zabbix.yml up -d
```

```
vim /etc/bind/zone/au-team.irpo
```
Добавим строку в список записей (через табы)
```
mon	IN	CNAME	hq-rtr.au-team.irpo.
```
Пеперазпустим DNS сервер
```
systemctl restart bind
```
На **HQ-RTR**
```
vim /etc/nginx/sites-available.d/default.conf
```
Добавим следующий блок в конец файла
```
server {
        listen  443 ssl;
        server_name mon.au-team.irpo;
        ssl_certificate /etc/ssl/certs/web.cer;
        ssl_certificate_key /etc/ssl/certs/web.key;
        ssl_ciphers GOST2012-GOST8912-GOST8912:HIGH:MEDIUM;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_prefer_server_ciphers on;
        location / {
                proxy_pass http://hq-srv.au-team.irpo:8080/;
        }
}
```

```
vim /etc/nginx/nginx.conf
```
В начале блока http добавим строку
```
server_names_hash_bucket_size 64;
```
Перезагрузим nginx
```
systemctl restart nginx
```

На **HQ-CLI**
Откроем в браузере https://mon.au-team.irpo
Данные для входа после установки: 
```
Пользователь: Admin
пароль: zabbix
```

Отключим проверку на небезопасные пароли
![](images/DemExamGuide_20250409103918811.png)
Поставим пароль и имя пользователя
![](images/DemExamGuide_20250409104033282.png)
![](images/DemExamGuide_20250409105600350.png)
```
Текщий пароль: zabbix
Новый пароль два раза: P@ssw0rd
```

На **HQ-RTR, HQ-SRV, BR-RTR и BR-SRV**

От root
```
apt-get install -y zabbix-agent
vim /etc/zabbix/zabbix_agentd.conf
```
Ищем строки и настраиваем
```
Server=hq-srv #Для конфигурации на машине HQ-SRV в этой строке поставить "0.0.0.0/0"
ServerActive=hq-srv
```
Включаем агент
```
systemctl enable --now zabbix_agentd.service
```
На **CLI-HQ**
Добавим устройства в мониторинг, возможно придется уменьшить масштаб страницы чтобы увидеть кнопку добавления хоста, по аналогии с этим добавляем все устройства
![](images/DemExamGuide_20250409111424505.png)
Нажмем кнопку Add в пункте Interfaces и выберете Agent чтобы присвоить IP адрес машины
![](images/DemExamGuide_20250409111220186.png)

## 8. Реализуйте механизм инвентаризации машин HQ-SRV и HQ-CLI через Ansible на BR-SRV:
```
mkdir /etc/ansible/PC_INFO
vim /etc/ansible/PC_INFO/playbook.yml
```
Вставим конфиг
```
- name: PC-INFO
  hosts: servers, clients

  tasks:
  - name: Report hostname
    lineinfile:
      path: /etc/ansible/PC_INFO/{{ ansible_hostname }}.yml
      line: "PC Name: {{ ansible_hostname }} \n"
      create: true
    delegate_to: 127.0.0.1

  - name: Add IP to report
    lineinfile:
      path: /etc/ansible/PC_INFO/{{ ansible_hostname }}.yml
      line: "IP address: {{ ansible_default_ipv4.address }} \n"
      create: true
    delegate_to: 127.0.0.1
```

```
ansible-playbook /etc/ansible/PC_INFO/playbook.yml
```

Если всё успешно, в папке PC_INFO появятся два файла с отчетом о машинах

Дополнительно если что-то не так, для отладки синтаксиса плейбука можно установить пакет и использовать утилиту ansible-lint

## 9. Реализуйте механизм резервного копирования конфигурации для машин HQ-RTR и BR-RTR, через Ansible на BR-SRV

```
mkdir /etc/ansible/NETWORK_INFO
vim /etc/ansible/net.yml
```
Вставим конфиг
```
- name: Backup configs
  hosts: HQ-RTR, BR-RTR
  tasks:
    - name: Get OSPF confs
      fetch:
        src: /etc/frr/frr.conf
        dest: /etc/ansible/NETWORK_INFO/{{ inventory_hostname }}/frr.conf
        flat: yes
      ignore_errors: yes
    - name: Get firewall rules
      fetch:
        src: /etc/sysconfig/iptables
        dest: /etc/ansible/NETWORK_INFO/{{ inventory_hostname }}/iptables
        flat: yes
      ignore_errors: yes
    - name: Get network confs
      copy:
        remote_src: yes
        mode: preserve
        directory_mode: preserve
        src: /etc/net/ifaces
        dest: /etc/ansible/NETWORK_INFO/{{ inventory_hostname }}/
      delegate_to: localhost
      ignore_errors: no

- name: Backup for HQ-RTR
  hosts: HQ-RTR
  tasks:
    - name: Get DHCP conf
      fetch:
        src: /etc/dhcp/dhcpd.conf
        dest: /etc/ansible/NETWORK_INFO/{{ inventory_hostname }}/dhcpd.conf
        flat: yes
      ignore_errors: yes
    - name: Check NETWORK_INFO exists
      delegate_to: 127.0.0.1
      file:
        path: /etc/ansible/NETWORK_INFO/{{ inventory_hostname }}
        state: directory

```

На **BR-RTR, HQ-RTR**
```
chmod -R 777 /etc/frr
chmod o+r /etc/sysconfig /etc/sysconfig/iptables 
chmod -R o+r /etc/net/ifaces/
```

На **HQ-RTR**
```
chmod -R 777 /etc/dhcp
```

На **BR-SRV**
```
ansible-playbook /etc/ansible/net/yml
```

Для проверки смотрим папку /etc/ansible/NETWORK_INFO
