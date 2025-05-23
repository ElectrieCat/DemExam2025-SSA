# Топология
![](images/DemExamGuide_20250515120408769.png)
# Полезности
Пароли по умолчанию для пользователей на машинах
```
root/toor
user/resu
```
Если съехало отображение строк в окне терминала
```
setterm --resize
```
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
N Предыдущее совпадение в поиске
dd удалить строку
v режим выделения
y скопировать выделенное
c вырезать выделенное
p вставить

Выплнить команду - Enter

В обоих режимах доступно управление курсором через стрелочки и клавиша DEL
```
# Порядок настройки
В каждом оглавлении есть номер задания, а так же номер его очереди настройки в формате [NUM].

Первым всегда должен выполняться пункт с наименьшим номером, для не пронумерованных пунктов порядок настройки не имеет значения.

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
ВНИМАНИЕ!!! Его мы не настраиваем вручную, HQ-CLI будет получать адрес полностью автоматически после включения когда мы настроим DHCP
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
Так-же в файле /etc/net/sysctl.conf на **HQ-RTR**,**BR-RTR** должна быть следующая настройка чтобы разрешить пересылку пакетов
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
Ранее мы должны были это настроить, но на всякий случай проверим что включена пересылка пакетов, иначе её запрет будет записан в конфиг frr при запуске и придется его отключать даже после того как включим пересылку в системе. Команда должна выдать "1" для этого параметра
```
sysctl -a | grep "net.ipv4.ip_forward"
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
```
no ip forwarding
```
Если же она присутствует то прописать
```
ip forwarding
```
И что есть настройка в интерфейсе tunnel
```
ip ospf network broadcast
```
Когда починили что-то, нужно не забыть сохранить конфигурацию, выполнив
```
write
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
## Вариатив: Измерьте пропускную способность сети между двумя офисами посредством утилиты iperf 3.
На **HQ-RTR** и **BR-RTR**
```
apt-get update
apt-get install -y iperf3
```
На **BR-RTR**
```
iperf3 -s
```
На **HQ-RTR**
```
iperf3 -c br-rtr
```
На обоих машинах начнётся процесс измерения пропускной способности, должно выдать примерно это:
```
Connecting to host br-rtr, port 5201
[  5] local 10.0.0.1 port 37936 connected to 172.16.0.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   539 MBytes  4.52 Gbits/sec    1   1.68 MBytes       
[  5]   1.00-2.00   sec   532 MBytes  4.46 Gbits/sec  889   1.54 MBytes       
[  5]   2.00-3.00   sec   477 MBytes  4.00 Gbits/sec    1   1.28 MBytes       
[  5]   3.00-4.00   sec   434 MBytes  3.64 Gbits/sec    0   1.50 MBytes       
[  5]   4.00-5.00   sec   453 MBytes  3.80 Gbits/sec    0   1.70 MBytes       
[  5]   5.00-6.00   sec   444 MBytes  3.72 Gbits/sec    0   1.88 MBytes       
[  5]   6.00-7.00   sec   431 MBytes  3.61 Gbits/sec  176   1.45 MBytes       
[  5]   7.00-8.00   sec   487 MBytes  4.08 Gbits/sec    0   1.65 MBytes       
[  5]   8.00-9.00   sec   424 MBytes  3.55 Gbits/sec   56   1.36 MBytes       
[  5]   9.00-10.00  sec   425 MBytes  3.57 Gbits/sec    0   1.54 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  4.54 GBytes  3.90 Gbits/sec  1123            sender
[  5]   0.00-10.00  sec  4.54 GBytes  3.89 Gbits/sec                  receiver

iperf Done.
[root@hq-rtr 
```
# Модуль 2
## Проверка стенда перед работой
На все машины можно зайти с пользователем/паролем `root/toor` и `user/resu` для **HQ-CLI**)

На всех машинах должно быть настроено подключение к интернету и локальный сервер dns, который так же может перенаправлять запросы в публичному серверу
```
ping 1.1.1.1
ping ya.ru
ping hq-rtr
```
Так-же между офисами должна быть связь
C **HQ-SRV**
```
ping br-srv
```
Примечание:
Адрес **HQ-CL** может измениться и обращение по имени hq-cli может перестать работать, т.к. он получает его через DHCP, вместо этого придется использовать его ipv4 адрес

На всех машинах должны быть созданы пользователи, проверим можно ли в них зайти
Проверим **HQ-SRV, BR-SRV**
Пароль - P@ssw0rd
```
ssh sshuser@hq-srv -p PORT
ssh sshuser@br-srv -p PORT
```
Проверим **HQ-RTR,BR-RTR**
Зайдём на них под юзером `net_admin` с паролем P@$$word

На **HQ-SRV** должны быть доступные диски
```
lsblk
```
Должно выдать следующее, доступны три диска - vdb, vdc, vdd
```
NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
vda    253:0    0   32G  0 disk 
├─vda1 253:1    0  2.9G  0 part [SWAP]
└─vda2 253:2    0 29.1G  0 part /
vdb    253:16   0    1G  0 disk 
vdc    253:32   0    1G  0 disk 
vdd    253:48   0    1G  0 disk 
```
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

Импорт пользователей
Напишем скрипт:
```
cd /opt
vim import.sh
```

Содержание import.sh
```
#!/bin/bash
tail -n +2 /opt/users.csv | while IFS=';' read -r firstName lastName _ _ ou _ _  
_ _ password
do
    samba-tool ou create "OU=$ou"
    samba-tool user create "${firstName}${lastName}" "$password" \
        --userou="OU=$ou"
done
```

Запуск:
```
sh import.sh
```
Частые ошибки при попытках добавления OU которые уже существуют это нормально.
Пример успешного выполнения:
```
Added ou "OU=Supporter,DC=au-team,DC=irpo"
User 'KayesStokes' added successfully
```

На **HQ-SRV**
```
vim /home/sshuser/bind9_flatfile
```
Удалить все строки сверху до красной линии
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

Реализуем повышение привелегий для пользоваталей группы hq, в конце перезагрузим машину чтобы можно было войти с пользователем домена. 
Выполнять из-под root:
```
apt-get install -y sudo
echo "%hq  ALL=(ALL) NOPASSWD: /bin/grep,/usr/bin/id,/bin/cat" >> /etc/sudoers
chmod 4755 /usr/bin/sudo
reboot
```

Проверка:
Зайти под одним из пользователей домена, напр. user1.hq и прописать следующую команду, в начале вывода строки должно показать uid=0(root)
```
sudo id
```
Так-же заодно проверим что у пользователей группы hq есть права только на выполнение ранее указанных команд
```
sudo cat /etc/os-release | sudo grep "ID"
```
Должно выдать всё без ошибок
## 2. Сконфигурируйте файловое хранилище
На **HQ-SRV**
Посмотрим доступные диски в системе
```
lsblk
```
Используем свободные диски по 1 гигу.
```
mdadm --create /dev/md0 --level=0 --raid-devices=3 /dev/vdb /dev/vdc /dev/vdd
mkfs.ext4 /dev/md0
mkdir /raid0
cat /proc/mdstat
```
Ждём пока завершится сборка
```
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
Проверим что наш диск примонтировался, выполним команду `mount`, ищем в конце строку
```
/dev/md0 on /raid0 type ext4 (rw,relatime,stripe=384)
```

Настроим nfs
```
apt-get install rpcbind nfs-server -y
mkdir /raid0/nfs
systemctl enable --now nfs
vim /etc/exports
```
Добавим следующую строку:
```
/raid0/nfs 172.16.200.0/28(no_root_squash,subtree_check,rw)
```
Опубликуем наш сетевой диск
```
exportfs -ra
```

На **HQ-CLI**
От root
```
mkdir /mnt/nfs
vim /etc/fstab
```
Добавим строку, между элементами - табы
```
hq-srv:/raid0/nfs	/mnt/nfs	nfs	defaults	0	0
```
Смонтируем и проверим что nfs подключена, так же проверим что мы можем в неё писать
```
mount -a
mount | grep hq-srv
touch /mnt/nfs/icanwrite
```

Вывод команды grep должен показать следующее
```
hq-srv:/raid0/nfs on /mnt/nfs type nfs4 (rw,relatime,vers=4.2,rsize=262144,wsize=262144,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=172.16.200.4,local_lock=none,addr=172.16.100.2)
```
## 3. Настройте службу сетевого времени на базе сервиса chrony
На **HQ-RTR**
```
vim /etc/chrony.conf
```

Закомментируем строчку с пулом и пропишем под ней следующие настройки:
```
#pool pool.ntp.org iburst
server 127.0.0.1 iburst
allow 0.0.0.0/0
local stratum 5
```
Перезапустим chronyd
```
systemctl restart chronyd
```

На **HQ-SRV, HQ-CLI, BR-RTR, BR-SRV**
```
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
Применим настройки
```
systemctl restart chronyd
chronyc makestep
chronyc sources
```
Должны быть выдана следующая строка
```
MS Name/IP address         Stratum Poll Reach LastRx Last sample               
===============================================================================
^* hq-rtr.au-team.irpo           5   6    17     1    -32us[  -49us] +/-  141us
```
Stratum должен быть 5, и MS - ^*
## 4. Сконфигурируйте ansible на сервере BR-SRV
Преднастройка машин (от root):
На **HQ-RTR, BR-RTR, HQ-CLI**
```
systemctl enable --now sshd
```

Настройка Ansible на **BR-SRV**
```
apt-get install -y ansible
cd /etc/ansible
vim ansible.cfg
```
В файле ansible.cfg, в блоке `[defaults]` раскоментируем строку
```
host_key_checking = False
```
Отредактируем и создадим файл hosts:
```
vim hosts
```
Он должен иметь следующее содержание:
Примечание - для HQ-CLI так же можно указать его адрес если он вдруг изменился и доменное имя перестало работать
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
ansible_ssh_pass=P@$$word
```

Проверка:
```
ansible -m ping all
```

Должно вывести:

![](images/DemExamGuide_20250331212012678.png)
## 5. Развертывание приложений в Docker на сервере BR-SRV.
Установим докер, произведём небольшую преднастройку
```
apt-get install -y docker-engine docker-compose
systemctl enable --now docker
cd /root
vim wiki.yml
```

Запишем в файл следующее:
```
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
docker compose -f wiki.yml up -d
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
Зайдем в консоль:
```
cd /home/user/Загрузки
scp -P 2024 LocalSettings.php sshuser@br-srv:/home/sshuser/
```

На **BR-SRV**
```
mv /home/sshuser/LocalSettings.php /root/
docker compose -f wiki.yml down
vim wiki.yml
```

Раскомментируем строку (убрать символ #)
```
#- ./LocalSettings.php:/var/www/html/LocalSettings.php
```
Поднимем контейнер
```
docker compose -f wiki.yml up -d
```

На **HQ-CLI**
Немного ждём и обновляем страницу, видим что вики теперь работает
![](images/DemExamGuide_20250402025529000.png)

На **BR-SRV** (ОСТОРОЖНО, НЕ ПИШИТЕ НЕ ПРОЧИТАВ!!!)
Если вы что-то настроили не так и нужно сбросить контейнеры и образы, используйте:
```
docker compose -f wiki.yml down -v
```

## 6. [2] На маршрутизаторах сконфигурируйте статическую трансляцию портов
На **BR-RTR**
```
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 2024 -j DNAT --to-destination 172.16.0.2:2024
iptables -t nat -A PREROUTING -p tcp -i eth0 --dport 80 -j DNAT --to-destination 172.16.0.2:8080
iptables-save -f /etc/sysconfig/iptables
```

Проверяем работу Wiki с HQ-CLI
В браузере открываем 172.16.5.2:80 и у нас должна открыться заглавная страница

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
curl 172.16.4.2:80
```
Вывод команды curl должен содержать html разметку, и не должно быть ошибок соединения

## 7. [1] Запустите сервис moodle на сервере HQ-SRV
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

На **HQ-CLI**
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
```
vim /var/www/webapps/moodle/config.php
```
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

Проверяем с **HQ-CLI**

В браузере открываем страницы, вводим те же адреса что и здесь, это важно
```
http://moodle.au-team.irpo/moodle/
http://wiki.au-team.irpo
```
## 9. Удобным способом установите приложение Яндекс Браузер для организаций на HQ-CLI
Из-под root
```
apt-get install -y yandex-browser-stable
```

# Модуль 3 - в процессе тестирования
## 1. Выполните миграцию на новый контроллер домена BR-SRV с BR-DC, являющийся наследием
### Возможно будет позже

## 2. Выполните настройку центра сертификации на базе HQ-SRV
Отроем конфиг openssl:
```
vim /etc/openssl/openssl.cnf
```
Настроим его следующим образом
```
[ ca ]
default_ca      = CA_default            # The default ca section

####################################################################
[ CA_default ]

dir             = ./demoCA              # Where everything is kept
certs           = $dir/certs            # Where the issued certs are kept
crl_dir         = $dir/crl              # Where the issued crl are kept
database        = $dir/index.txt        # database index file.
#unique_subject = no                    # Set to 'no' to allow creation of
                                        # several ctificates with same subject.
new_certs_dir   = $dir/newcerts         # default place for new certs.

certificate     = $dir/cacert.pem       # The CA certificate
serial          = $dir/serial           # The current serial number
crlnumber       = $dir/crlnumber        # the current crl number
                                        # must be commented out to leave a V1 CRL
crl             = $dir/crl.pem          # The current CRL
private_key     = $dir/private/cakey.pem# The private key

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

default_days    = 90                    # how long to certify for
default_crl_days= 90                    # how long before next CRL
default_md      = md_gost12_256         # which md to use.
preserve        = no                    # keep passed DN ordering
```
А так-же настроим секцию req
```
[ req ]
default_bits            = 2048
default_md              = md_gost12_256
default_keyfile         = privkey.pem
distinguished_name      = req_distinguished_name
attributes              = req_attributes
x509_extensions = v3_ca
```
Установим и включим поддержку сертификатов ГОСТ для openssl
```
apt-get install -y openssl openssl-gost-engine
control openssl-gost enabled
```
Преднастроим структуру файлов для нашего CA
```
cd /root
mkdir demoCA
mkdir demoCA/certs
mkdir demoCA/crl
mkdir demoCA/newcerts
mkdir demoCA/private
touch demoCA/index.txt
echo 00 > demoCA/crlnumber
```
Проверим структуру файлов если нужно 
```
apt-get install tree -y
tree demoCA
```
Должно вывести следующее
```
demoCA/
├── certs
├── crl
├── crlnumber
├── index.txt
├── newcerts
└── private
```
Сгенерируем все сертификаты
```
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:TCB -out ./demoCA/private/cakey.pem
openssl req -nodes -new -x509 -key ./demoCA/private/cakey.pem -out ./demoCA/cacert.pem -subj "/CN=AU-Team-CA"
openssl genpkey -algorithm gost2012_256 -pkeyopt paramset:A -out ./demoCA/private/web.pem
openssl req -new -key ./demoCA/private/web.pem -out ./demoCA/certs/web.cer -subj "/CN=*.au-team.irpo"
openssl x509 -req -in ./demoCA/certs/web.cer -CA ./demoCA/cacert.pem -CAkey ./demoCA/private/cakey.pem -CAcreateserial -out ./demoCA/newcerts/web.cer
openssl ca -gencrl -out ./demoCA/crl/ca.crl dgst:gost
```
Пересылаем необходимые файлы на машины
Примечание: у **hq-cli** IP адрес может поменяться и по доменному имени уже нельзя будет достучаться до него, тогда следует вбить его текущий адрес
```
scp ./demoCA/crl/ca.crl ./demoCA/cacert.pem  user@hq-cli:/home/user
```
На **ISP** настроим ssh и создадим директорию чтобы перекинуть файл
```
mkdir /etc/ssl/certs -p
vim /etc/openssh/sshd_config
```
Добавим параметр
```
PermitRootLogin yes
```
Перезагрузим sshd
```
systemctl restart sshd
```
На **HQ-SRV**
```
scp ./demoCA/private/web.pem ./demoCA/newcerts/web.cer root@172.16.4.1:/etc/ssl/certs
```
Снова на **ISP**, настроим nginx на использование сертификата по ГОСТу
```
apt-get install -y openssl openssl-gost-engine
control openssl-gost enabled
vim /etc/nginx/sites-available.d/proxy.conf
```
Перенастроим nginx следующим образом:
```
server {
 listen 443 ssl;
 server_name moodle.au-team.irpo;
 ssl_certificate /etc/ssl/certs/web.cer;
 ssl_certificate_key /etc/ssl/certs/web.pem;
 ssl_ciphers GOST2012-GOST8912-GOST8912:HIGH:MEDIUM;
 ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
 ssl_prefer_server_ciphers on;
 location / {
  proxy_pass http://172.16.4.2:80/moodle/;
 }
}
server {
 listen 443 ssl;
 server_name wiki.au-team.irpo;
 ssl_certificate /etc/ssl/certs/web.cer;
 ssl_certificate_key /etc/ssl/certs/web.pem;
 ssl_ciphers GOST2012-GOST8912-GOST8912:HIGH:MEDIUM;
 ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
 ssl_prefer_server_ciphers on;
 location / {
  proxy_pass http://172.16.5.2:80;
 }
}
```
Перезагрузим nginx
```
systemctl restart nginx
```

На **HQ-CLI**
```
mv /home/user/cacert.pem /etc/pki/ca-trust/source/anchors/
update-ca-trust
trust list | grep AU 
```
Проверим что система доверяет нашему CA, должно вывести `label: AU-Team-CA`
```
apt-get install -y cryptopro-preinstall
tar -xf linux-amd64.tgz #Архив качаем с сайта КриптоПро после регистрации, нам нужен "Актуальный" для Linux RPM x64
cd linux-amd64
apt-get install cprocsp-curl* lsb-cprocsp-base* lsb-cprocsp-capilite* lsb-cprocsp-kc1-64* lsb-cprocsp-rdr-64*
./install.sh
ln /opt/cprocsp/bin/amd64/* /bin
certmgr -install -store mRoot -file /etc/pki/ca-trust/source/anchors/cacert.pem #Вводим "o"
certmgr -install -store mRoot -crl -file /home/user/ca.crl
```
Включим поддержку шифрования по ГОСТу в яндексе, для этого нажать "Три горизонтальные полоски" (самые верхние правее)> Настройки > Системные > Подключаться к сайтам использующим шифрование ГОСТ

Проверить открыв в яндекс браузере https://wiki.au-team.irpo и https://moodle.au-team.irpo, если нет предупреждений (кроме того что сайт использует шифрование ГОСТ) то всё сработало.

## 3 Перенастройте ip-туннель с базового до уровня туннеля, обеспечивающего шифрование трафика
На **HQ-RTR, BR-RTR**
```
apt-get install -y strongswan
```
На **HQ-RTR**
```
vim /etc/strongswan/ipsec.conf
```
Добавим следующий блок конфига
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
Откроем файл с настройками аутентификации
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
Добавим следующий блок конфига
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
Откроем файл с настройками аутентификации
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
ipsec status
```
У соединения должен быть статус ESTABLISHED
```
ip xfrm state
```
Появится правило для протокола gre и src,dst адресов тоннеля

**Удаление правил**
Если добавили неправильное правило, просто выполните ту-же команду, но поменяйте **-I** или **-A** на **-D**, это по строгому соответствую удалит правило из цепочки
## 4. Настройте межсетевой экран на маршрутизаторах HQ-RTR и BR-RTR на сеть в сторону ISP

На **HQ-RTR, BR-RTR**
Запрещаем все подключения во внутреннюю сеть из интернета
```
iptables -A INPUT -i eth0 -j REJECT
iptables -A FORWARD -i eth0 -j REJECT
```
Обеспечиваем работу протоколов во внутреннюю сеть и к самим роутерам
```
iptables -I FORWARD -i eth0 -p tcp --dport 80 -j ACCEPT
iptables -I FORWARD -i eth0 -p tcp --dport 443 -j ACCEPT
iptables -I FORWARD -i eth0 -p udp --dport 53 -j ACCEPT
iptables -I FORWARD -i eth0 -p udp --dport 123 -j ACCEPT
iptables -I FORWARD -i eth0 -p icmp -j ACCEPT
iptables -I FORWARD -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -i eth0 -p tcp --dport 2024 -j ACCEPT
iptables -I INPUT -i eth0 -p icmp -j ACCEPT
iptables -I INPUT -i eth0 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
```
Разрешаем доступ к порту ssh на wan интерфейсе
```
iptables -I INPUT -i eth0 -p tcp --dport 22 -j ACCEPT
```
Отдельно на **HQ-RTR**
```
iptables -I FORWARD -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables -I INPUT -i eth0 -p udp --dport 123 -j ACCEPT
```
Проверка с **ISP**
Настроим временные маршруты чтобы можно было достучаться до ресурсов сети за роутерами, так же установим необходимые пакеты с инструментами для проверки
```
apt-get install -y nmap curl wget bind-utils
ip route add 172.16.100.0/26 via 172.16.4.2 
ip route add 172.16.0.0/27 via 172.16.5.2 
```
Для проверки можно использовать nmap, ping или для наглядности wget, curl, nslookup
Как пользоваться:
```
nmap IP -p PORT # Для TCP
nmap IP -p PORT -sU # Для UDP
wget IP:PORT
curl IP:PORT
curl http[s]://IP[:PORT]
nslookup DOMAIN DNS_SERVER_IP
ping IP
```
Проверяем для сети в сторону HQ-RTR т.к. тут есть больше всего возможностей наглядной проверки, если сработали настройки для этой сети то аналогичные сработали и для сети в сторону BR-RTR
```
nmap 172.16.100.2
curl 172.16.100.2 
nmap 172.16.100.2 -p 53 -sU
nmap 172.16.4.2 -p 123 -sU
nmap 172.16.4.2 -p 2024
nslookup hq-rtr.au-team.irpo 172.16.100.2
ping 172.16.100.2
ping 172.16.4.2
```
Проверяем что после применения нашего файрвола поднимется ipsec на **HQ-RTR**, **BR-RTR**
```
ipsec restart
ipsec status
```
Должен быть статус `ESTABLISHED`, возможно потребуется подождать около минуты.

На **HQ-RTR**, **BR-RTR**
Если всё проверено и работает, можем сохранить наши настройки
```
iptables-save -f /etc/sysconfig/iptables
```

## 5. Настройте принт-сервер cups на сервере HQ-SRV.
```
apt-get install -y cups cups-pdf
systemctl enable --now cups
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
Игнорируем ошибку сертификата и открываем страницу
![](images/DemExamGuide_20250407180506222.png)
Если задание появилось, то всё настроено правильно.
## 6. Реализуйте логирование при помощи rsyslog на устройствах HQ-RTR, BR-RTR, BR-SRV

На **HQ-SRV**
```
apt-get install -y rsyslog-classic
rm -f /etc/rsyslog.d/10_classic.conf
vim /etc/rsyslog.d/00_common.conf
```
Раскомментировать строки
```
module(load="imudp") # needs to be done just once
input(type="imudp" port="514")

module(load="imtcp") # needs to be done just once
input(type="imtcp" port="514")
```
Добавить в конец файла
```
$template RemoteLogs, "/opt/%HOSTNAME%/%HOSTNAME%.log"
*.* ?RemoteLogs
& ~
```
Запустим службу и добавим в автозагрузку
```
systemctl enable --now rsyslog
```

На **HQ-RTR, BR-RTR, BR-SRV**

```
apt-get install -y rsyslog-classic
vim /etc/rsyslog.d/00_common.conf
```
Раскомментировать
```
module(load="imjournal") # provides support for systemd-journald logging
module(load="imuxsock")  # provides support for local system logging (e.g. via logger command)
module(load="imklog")    # provides kernel logging support (previously done by rklogd)
module(load="immark")    # provides --MARK-- message capability
```
Добавить в конец файла
```
*.warning @@hq-srv:514
```
Запустим службу и добавим в автозагрузку
```
systemctl enable --now rsyslog
```

На **HQ-SRV**
Проверим что логи присылаются 
```
ls /opt
```
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
```
Добавим строку:
```
0 0 * * 0 /usr/sbin/logrotate -f /etc/logrotate.d/rsyslog
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
Настроим следующий конфиг
```
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
      ZBX_ALLOWUNSUPPORTEDDBVERSIONS: 1
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
Поднимем службу
```
docker compose -f zabbix.yml up -d
```
Откроем конфиг прямой зоны в bind
```
vim /etc/bind/zone/au-team.irpo
```
Добавим строку в список записей (через табы)
```
mon	IN	A	172.16.4.1
```
Пеперазпустим DNS сервер
```
systemctl restart bind
```
На **ISP**
```
vim /etc/nginx/sites-available.d/proxy.conf
```
Добавим следующий блок в конец файла
```
server {
 listen  443 ssl;
 server_name mon.au-team.irpo;
 ssl_certificate /etc/ssl/certs/web.cer;
 ssl_certificate_key /etc/ssl/certs/web.pem;
 ssl_ciphers GOST2012-GOST8912-GOST8912:HIGH:MEDIUM;
 ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
 ssl_prefer_server_ciphers on;
 location / {
  proxy_pass http://172.16.4.2:8080;
 }
}
```
Откроем конфиг nginx
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
На **HQ-RTR**
Настроим переадресацию из внешней сети на порт 8080 на HQ-SRV во внутренней сети
```
iptables -t nat -I PREROUTING -p tcp -i eth0 --dport 8080 -j DNAT --to-destination 172.16.100.2:8080
iptables -I FORWARD -i eth0 -p tcp --dport 8080 -j ACCEPT
iptables-save -f /etc/sysconfig/iptables
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

На **HQ-RTR, BR-RTR и BR-SRV**

От root
```
apt-get install -y zabbix-agent
vim /etc/zabbix/zabbix_agentd.conf
```
Ищем строки и настраиваем
```
Server=hq-srv 
ServerActive=hq-srv
```
При конфигурации на машине **HQ-SRV**
```
Server=0.0.0.0/0
ServerActive=hq-srv
```
Включаем агент
```
systemctl enable --now zabbix_agentd.service
```
На **HQ-CLI**
Добавим устройства в мониторинг, возможно придется уменьшить масштаб страницы чтобы увидеть кнопку добавления хоста, по аналогии с этим добавляем все устройства
![](images/DemExamGuide_20250409111424505.png)
Нажмем кнопку Add в пункте Interfaces и выберете Agent чтобы присвоить IP адрес машины
![](images/DemExamGuide_20250409111220186.png)
Как только мы добавим все машины аналогичным образом, можем смотреть для каждой графики её нагрузки пролистывая страницу вниз. 
Примечание: возможно придется немного подождать или перезагрузить страницу чтобы они появились
![](images/DemExamGuide_20250522214247234.png)

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
Запустим файл плейбука
```
ansible-playbook /etc/ansible/PC_INFO/playbook.yml
```

Если всё успешно, в папке PC_INFO появятся два файла с отчетом о машинах: `hq-cli.yml, hq-srv.yml`

Дополнительно если что-то не так, для отладки синтаксиса плейбука можно установить пакет и использовать утилиту ansible-lint

## 9. Реализуйте механизм резервного копирования конфигурации для машин HQ-RTR и BR-RTR, через Ansible на BR-SRV
Создадим папку и откроем конфигурацию нового плейбука
```
mkdir /etc/ansible/NETWORK_INFO
vim /etc/ansible/net.yml
```
Настроим плейбук
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
Выставим у файлов нужные права
```
chmod -R 777 /etc/frr
chmod o+r /etc/sysconfig /etc/sysconfig/iptables 
chmod -R o+r /etc/net/ifaces/
```

На **HQ-RTR**
Выставим у файла нужные права
```
chmod -R 777 /etc/dhcp
```

На **BR-SRV**
```
ansible-playbook /etc/ansible/net.yml
```

Для проверки смотрим папку 
```
apt-get install -y tree
tree /etc/ansible/NETWORK_INFO
```
Должна появиться следующая структура файлов
```
/etc/ansible/NETWORK_INFO
├── BR-RTR
│   ├── frr.conf
│   ├── ifaces
│   │   ├── default
│   │   │   ├── fw
│   │   │   │   ├── ebtables
│   │   │   │   │   ├── broute
│   │   │   │   │   │   └── BROUTING
│   │   │   │   │   ├── filter
│   │   │   │   │   │   ├── FORWARD
│   │   │   │   │   │   ├── INPUT
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   ├── loadorder
│   │   │   │   │   ├── modules
│   │   │   │   │   └── nat
│   │   │   │   │       ├── OUTPUT
│   │   │   │   │       ├── POSTROUTING
│   │   │   │   │       ├── PREROUTING
│   │   │   │   │       └── loadorder
│   │   │   │   ├── ip6tables
│   │   │   │   │   ├── filter
│   │   │   │   │   │   ├── FORWARD
│   │   │   │   │   │   ├── INPUT
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   ├── loadorder
│   │   │   │   │   ├── mangle
│   │   │   │   │   │   ├── FORWARD
│   │   │   │   │   │   ├── INPUT
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   ├── POSTROUTING
│   │   │   │   │   │   ├── PREROUTING
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   ├── modules
│   │   │   │   │   └── syntax
│   │   │   │   ├── ipset
│   │   │   │   │   ├── iphash
│   │   │   │   │   ├── ipmap
│   │   │   │   │   ├── ipporthash
│   │   │   │   │   ├── ipportiphash
│   │   │   │   │   ├── ipportnethash
│   │   │   │   │   ├── iptree
│   │   │   │   │   ├── iptreemap
│   │   │   │   │   ├── loadorder
│   │   │   │   │   ├── macipmap
│   │   │   │   │   ├── modules
│   │   │   │   │   ├── nethash
│   │   │   │   │   ├── portmap
│   │   │   │   │   └── setlist
│   │   │   │   ├── iptables
│   │   │   │   │   ├── filter
│   │   │   │   │   │   ├── FORWARD
│   │   │   │   │   │   ├── INPUT
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   ├── loadorder
│   │   │   │   │   ├── mangle
│   │   │   │   │   │   ├── FORWARD
│   │   │   │   │   │   ├── INPUT
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   ├── POSTROUTING
│   │   │   │   │   │   ├── PREROUTING
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   ├── modules
│   │   │   │   │   ├── nat
│   │   │   │   │   │   ├── OUTPUT
│   │   │   │   │   │   ├── POSTROUTING
│   │   │   │   │   │   ├── PREROUTING
│   │   │   │   │   │   └── loadorder
│   │   │   │   │   └── syntax
│   │   │   │   └── options
│   │   │   ├── options
│   │   │   ├── options-bnep
│   │   │   ├── options-dummy
│   │   │   ├── options-eth
│   │   │   ├── options-l2tp
│   │   │   ├── options-lo
│   │   │   ├── options-ovpn
│   │   │   ├── options-ppp
│   │   │   ├── options-tuntap
│   │   │   ├── options-usb
│   │   │   ├── options-vlan
│   │   │   └── sysctl.conf-dvb
│   │   ├── eth0
│   │   │   ├── ipv4address
│   │   │   ├── ipv4route
│   │   │   ├── options
│   │   │   └── resolv.conf
│   │   ├── lo
│   │   │   ├── ipv4address
│   │   │   └── options
│   │   └── unknown
│   │       ├── README
│   │       └── options
│   └── iptables
└── HQ-RTR
    ├── dhcpd.conf
    ├── frr.conf
    ├── ifaces
    │   ├── default
    │   │   ├── fw
    │   │   │   ├── ebtables
    │   │   │   │   ├── broute
    │   │   │   │   │   └── BROUTING
    │   │   │   │   ├── filter
    │   │   │   │   │   ├── FORWARD
    │   │   │   │   │   ├── INPUT
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   └── loadorder
    │   │   │   │   ├── loadorder
    │   │   │   │   ├── modules
    │   │   │   │   └── nat
    │   │   │   │       ├── OUTPUT
    │   │   │   │       ├── POSTROUTING
    │   │   │   │       ├── PREROUTING
    │   │   │   │       └── loadorder
    │   │   │   ├── ip6tables
    │   │   │   │   ├── filter
    │   │   │   │   │   ├── FORWARD
    │   │   │   │   │   ├── INPUT
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   └── loadorder
    │   │   │   │   ├── loadorder
    │   │   │   │   ├── mangle
    │   │   │   │   │   ├── FORWARD
    │   │   │   │   │   ├── INPUT
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   ├── POSTROUTING
    │   │   │   │   │   ├── PREROUTING
    │   │   │   │   │   └── loadorder
    │   │   │   │   ├── modules
    │   │   │   │   └── syntax
    │   │   │   ├── ipset
    │   │   │   │   ├── iphash
    │   │   │   │   ├── ipmap
    │   │   │   │   ├── ipporthash
    │   │   │   │   ├── ipportiphash
    │   │   │   │   ├── ipportnethash
    │   │   │   │   ├── iptree
    │   │   │   │   ├── iptreemap
    │   │   │   │   ├── loadorder
    │   │   │   │   ├── macipmap
    │   │   │   │   ├── modules
    │   │   │   │   ├── nethash
    │   │   │   │   ├── portmap
    │   │   │   │   └── setlist
    │   │   │   ├── iptables
    │   │   │   │   ├── filter
    │   │   │   │   │   ├── FORWARD
    │   │   │   │   │   ├── INPUT
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   └── loadorder
    │   │   │   │   ├── loadorder
    │   │   │   │   ├── mangle
    │   │   │   │   │   ├── FORWARD
    │   │   │   │   │   ├── INPUT
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   ├── POSTROUTING
    │   │   │   │   │   ├── PREROUTING
    │   │   │   │   │   └── loadorder
    │   │   │   │   ├── modules
    │   │   │   │   ├── nat
    │   │   │   │   │   ├── OUTPUT
    │   │   │   │   │   ├── POSTROUTING
    │   │   │   │   │   ├── PREROUTING
    │   │   │   │   │   └── loadorder
    │   │   │   │   └── syntax
    │   │   │   └── options
    │   │   ├── options
    │   │   ├── options-bnep
    │   │   ├── options-dummy
    │   │   ├── options-eth
    │   │   ├── options-l2tp
    │   │   ├── options-lo
    │   │   ├── options-ovpn
    │   │   ├── options-ppp
    │   │   ├── options-tuntap
    │   │   ├── options-usb
    │   │   ├── options-vlan
    │   │   └── sysctl.conf-dvb
    │   ├── eth0
    │   │   ├── ipv4address
    │   │   ├── ipv4route
    │   │   ├── options
    │   │   └── resolv.conf
    │   ├── lo
    │   │   ├── ipv4address
    │   │   └── options
    │   └── unknown
    │       ├── README
    │       └── options
    └── iptables
```
## Вариатив 1: Настройте приоритизацию трафика QoS на роутере офиса HQ
### Это задание было решено с использованием ИИ и пока не прошло официальное ревью

На **HQ-CLI**,**HQ-RTR** установим iperf3 для тестирования и измерения
```
apt-get install -y iperf3
```
На **HQ-RTR** включим сервер iperf3 в фоне
```
iperf3 -sD
```
С **HQ-CLI** измерим скорость до роутера
```
iperf3 -c 172.16.200.1
``` 
Получим что-то вроде:
```
Connecting to host 172.16.200.1, port 5201
[  5] local 172.16.200.4 port 58884 connected to 172.16.200.1 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  2.03 GBytes  17.5 Gbits/sec    0   2.53 MBytes       
[  5]   1.00-2.00   sec  2.40 GBytes  20.6 Gbits/sec    1   2.53 MBytes       
[  5]   2.00-3.00   sec  2.61 GBytes  22.4 Gbits/sec    0   2.53 MBytes       
[  5]   3.00-4.00   sec  2.59 GBytes  22.2 Gbits/sec    0   2.53 MBytes       
[  5]   4.00-5.00   sec  1.93 GBytes  16.6 Gbits/sec    0   2.53 MBytes       
[  5]   5.00-6.00   sec  2.34 GBytes  20.1 Gbits/sec    2   2.53 MBytes       
[  5]   6.00-7.00   sec  2.82 GBytes  24.3 Gbits/sec    0   2.53 MBytes       
[  5]   7.00-8.00   sec  2.13 GBytes  18.3 Gbits/sec    1   2.53 MBytes       
[  5]   8.00-9.00   sec  1.82 GBytes  15.6 Gbits/sec    0   2.53 MBytes       
[  5]   9.00-10.00  sec  2.40 GBytes  20.6 Gbits/sec    0   2.53 MBytes       
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  23.1 GBytes  19.8 Gbits/sec    4            sender
[  5]   0.00-10.00  sec  23.1 GBytes  19.8 Gbits/sec                  receiver
```
Поделим на два наш результат (Bitrate), получим примерно 9.9 Гбит, и это далее укажем в фильтре.
Приступим к настройке
```
tc qdisc add dev cli handle ffff: ingress
tc filter add dev cli parent ffff: protocol ip prio 1 u32 match ip protocol 1 0xff flowid :1
tc filter add dev cli parent ffff: protocol ip prio 2 u32 match ip src 172.16.200.4 police rate 9.9gbit burst 1m drop flowid :2
```
На **HQ-CLI**
Проверим применились и верны ли наши настройки
```
iperf3 -c 172.16.200.1
```
Должно выдать в конце примерно следующие значения
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  10.4 GBytes  8.96 Gbits/sec  178934            sender
[  5]   0.00-10.00  sec  10.4 GBytes  8.96 Gbits/sec                  receiver
```
Так же можем проверить на **HQ-RTR** что часть пакетов была отброшена фильтром
```
tc -s filter show dev cli parent ffff:
```
Выдаст примерно следующее, здесь нас интересует что `dropped` и `overlimits` не пусты
```
filter protocol ip pref 1 u32 chain 0 
filter protocol ip pref 1 u32 chain 0 fh 800: ht divisor 1 
filter protocol ip pref 1 u32 chain 0 fh 800::800 order 2048 key ht 800 bkt 0 flowid :1 not_in_hw  (rule hit 254116 success 0)
  match 00010000/00ff0000 at 8 (success 0 ) 
filter protocol ip pref 2 u32 chain 0 
filter protocol ip pref 2 u32 chain 0 fh 802: ht divisor 1 
filter protocol ip pref 2 u32 chain 0 fh 802::800 order 2048 key ht 802 bkt 0 flowid :2 not_in_hw  (rule hit 254116 success 254116)
  match ac10c804/ffffffff at 12 (success 254116 ) 
 police 0x1 rate 9900Mbit burst 1046925b mtu 2Kb action drop overhead 0b 
        ref 1 bind 1 installed 768 sec used 28 sec firstused 766 sec

 Sent 11472496705 bytes 3115 pkts (dropped 4764, overlimits 4764) 
```
После того как мы убедились что всё работает, нам нужно сделать так чтобы правила применялись после перезагрузки машины
```
vim /etc/net/ifaces/cli/ifup-post
```
Вставим туда все команды для настройки
```
tc qdisc add dev cli handle ffff: ingress
tc filter add dev cli parent ffff: protocol ip prio 1 u32 match ip protocol 1 0xff flowid :1
tc filter add dev cli parent ffff: protocol ip prio 2 u32 match ip src 172.16.200.4 police rate 9.9gbit burst 1m drop flowid :2
```
Поставим права на выполнение для файла
```
chmod +x /etc/net/ifaces/cli/ifup-post
```
Перезагрузим **HQ-RTR** и когда он запустится снова проверим работу фильтра с **HQ-CLI**
```
iperf3 -c 172.16.200.1
```
Здесь как уже известно, мы ожидаем увидеть примерно такой итог
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  10.2 GBytes  8.77 Gbits/sec  126381            sender
[  5]   0.00-10.01  sec  10.2 GBytes  8.76 Gbits/sec                  receiver
```

(ВНИМАНИЕ ЭТО УДАЛИТ НАСТРОЙКУ!!!)
Если что-то пошло не так, то можем удалить все созданные ранее настройки из загруженных на данный момент.  
```
tc qdisc del dev cli root
tc qdisc del dev cli ingress
```
Если неправильные настройки были записаны в скрипт `ifup-post`, то этот файл тоже нужно будет очистить и изменить чтобы они не применились при следующем перезапуске

## Вариатив 2: Метрики с сервера мониторинга необходимо экспортировать в Grafana

На **HQ-SRV**
```
apt-get install -y grafana
grafana-cli plugins install alexanderzobnin-zabbix-app
systemctl enable --now grafana-server
```
На **HQ-CLI**

Открываем в браузере http://hq-srv:3000

Username: admin

Password: admin

![](images/DemExamGuide_20250523231255592.png)
![](images/DemExamGuide_20250523231447325.png)
![](images/DemExamGuide_20250523231638492.png)
![](images/DemExamGuide_20250523231718444.png)
![](images/DemExamGuide_20250523231735268.png)
![](images/DemExamGuide_20250523231959747.png)
![](images/DemExamGuide_20250523232136052.png)
![](images/DemExamGuide_20250523232339401.png)
![](images/DemExamGuide_20250523232440175.png)
![](images/DemExamGuide_20250523232511974.png)
![](images/DemExamGuide_20250523232619053.png)
![](images/DemExamGuide_20250523232630082.png)
![](images/DemExamGuide_20250523232654834.png)
![](images/DemExamGuide_20250523232927610.png)
Листаем ниже до раздела подключения к zabbix
![](images/DemExamGuide_20250523233031532.png)
Листаем ниже и проверяем подключение
![](images/DemExamGuide_20250523233118842.png)
![](images/DemExamGuide_20250523233504921.png)
![](images/DemExamGuide_20250523233526616.png)
![](images/DemExamGuide_20250523233637481.png)
![](images/DemExamGuide_20250523233741366.png)
![](images/DemExamGuide_20250523234622378.png)
![](images/DemExamGuide_20250523234910078.png)
![](images/DemExamGuide_20250523234933158.png)
![](images/DemExamGuide_20250523235022103.png)
![](images/DemExamGuide_20250523235043461.png)
![](images/DemExamGuide_20250523235356767.png)
![](images/DemExamGuide_20250524001011251.png)
![](images/DemExamGuide_20250524001208870.png)
![](images/DemExamGuide_20250524001246275.png)
![](images/DemExamGuide_20250523235823450.png)
Проверим, что можно зайти под пользователем `monadmin`
![](images/DemExamGuide_20250524000000162.png)
![](images/DemExamGuide_20250524000048450.png)
![](images/DemExamGuide_20250524000631923.png)