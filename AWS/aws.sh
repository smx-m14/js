#!/bin/bash

# Comprovació que estem amb root
if [ "$(id -u)" != "0" ]; then
   echo "Aquest programa s'ha d'executar amb l'usuari root" 1>&2;
   exit 1;
fi


# Comprovacions prèvies
sudo apt update > /dev/null 2> /dev/null;
sudo apt install dialog gcc make net-tools -y > /dev/null 2> /dev/null;

# Funcions
askPassword() {
   userPass=$(dialog --title "Contrasenya d'usuari (ubuntu i root)" --insecure --clear --passwordbox "Indiqueu la contrasenya del vostre compte d'usuari" 10 50 3>&1- 1>&2- 2>&3- );
   exitCode1=$?;
   
   userPassC=$(dialog --title "Contrasenya d'usuari (ubuntu i root)" --insecure --clear --passwordbox "Confirmeu la contrasenya del vostre compte d'usuari" 10 50 3>&1- 1>&2- 2>&3- );
   exitCode2=$?;
   
   #Comprovar que no sigui buida i que coincideixin.
   if [ -z "$userPass" ]
   then
     dialog --msgbox "La contrasenya no pot ser buida. Si us plau, introduïu una contrasenya vàlida." 7 50
     exitCode1=1;   
   fi
   
   if [ "$userPass" != "$userPassC" ]
   then
     dialog --msgbox "Les contrasenyes indicades no coincideixen. Si us plau, introduïu-les de nou." 7 50
     exitCode1=1;   
   fi
}


# Variables globals
userPass="Thos123!";


exitCode1=1;
while [[ $exitCode1 -ne 0 ]]
do
   askPassword;
done

echo $userPass;

# Demanar password per la màquina
#echo "root:$userPass" | chpasswd;
#echo "ubuntu:$userPass" | chpasswd;
# No ho fem, ho farem amb el certificat?


# TO DO: COMPTE CAL BUSCAR EL NOM D'ARXIU!!!!
# Si no fem la part de dalt, aquesta tampoc
# Permetem l'accés per password a la consola i reiniciem servei
#sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' filename
#service sshd restart

# Instal·lem i configurem XAMPP
wget https://sourceforge.net/projects/xampp/files/XAMPP%20Linux/7.4.33/xampp-linux-x64-7.4.33-0-installer.run/download > /dev/null 2> /dev/null;
mv download xampp.run;
chmod u+x xampp.run;
sudo ./xampp.run --mode unattended > /dev/null 2> /dev/null;
sudo /opt/lampp/lampp restart  > /dev/null 2> /dev/null;
rm xampp.run;

# Simulem el mateix que faria el security
sudo /opt/lampp/lampp restart

# Desactiva XAMPP`per xarxa
sudo sed -i 's/#skip-networking/skip-networking/' /opt/lampp/etc/my.cnf

# Canvia password del pma
sudo echo "update user set Password=password('$userPass') where User = 'pma';" | /opt/lampp/bin/mysql -uroot mysql
sudo /opt/lampp/bin/mysqladmin reload


# S'ha de provar bé, no sé si funciona
sudo cat /opt/lampp/phpmyadmin/config.inc.php | grep -v 'controlpass' | grep -v 'password' | grep -v 'auth_type' > config.inc.php
echo "\$cfg['Servers'][\$i]['auth_type'] = 'cookie';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['controlpass'] = '$userPass';" >> config.inc.php;
echo "\$cfg['Servers'][\$i]['password'] = '$userPass';" >> config.inc.php;
sudo mv config.inc.php /opt/lampp/phpmyadmin/config.inc.php
sudo /opt/lampp/lampp restart

# Obrim phpmyadmin per xarxa
sed -i 's/AllowOverride AuthConfig Limit/AllowOverride AuthConfig/' /opt/lampp/etc/extra/httpd-xampp.conf
sed -i 's/Require local/Require all granted/' /opt/lampp/etc/extra/httpd-xampp.conf

# Fem que daemon funcioni amb la contrasenya establida
sudo chown -R daemon:daemon /opt/lampp/htdocs
sed -i 's/UserPassword/#UserPassword/' /opt/lampp/etc/proftpd.conf
echo "PassivePorts           30000 30100" >> /opt/lampp/etc/proftpd.conf
echo "daemon:$userPass" | chpasswd;

/opt/lampp/lampp restart


# Archive unzipper --> me'l puc guardar al meu repo si cal
cd /opt/lampp/htdocs
wget https://raw.githubusercontent.com/ndeet/unzipper/master/unzipper.php


# Creem arxiu d'arrencada automàtica pel XAMPP
echo "[Unit]
Description=XAMPP

[Service]
ExecStart=/opt/lampp/lampp start
ExecStop=/opt/lampp/lampp stop
Type=forking

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/xampp.service

# Habilitem servei
systemctl enable xampp




# NO IP
# Mostrar missatge que ja està el XAMPP configurat correctament, ara configurarem NO IP
cd /usr/local/src/
wget http://www.noip.com/client/linux/noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
tar xf noip-duc-linux.tar.gz  > /dev/null 2> /dev/null;
cd noip-2.1.9-1/  > /dev/null 2> /dev/null;
make install
# comprobar exit code == 0 o reiniciar programa $? o hacer con while

echo "[Unit]
Description=NOIP

[Service]
Type=forking
ExecStart=/usr/local/bin/noip2
Restart=always

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/noip.service

sudo systemctl enable noip
sudo systemctl start noip
