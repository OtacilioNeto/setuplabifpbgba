#!/bin/bash

OTA="1"
RHAVY="1"
BARROS="1"
ERICK="1"

# Esta opção deve ser habilitada quando executando o script nas máquinas que tem a placa 
# de rede problemática. As que usam driver TG3
TG3="0"

if [ $USER == "root" ]; then
	apt --fix-broken install
	apt install -y ethtool
        apt install net-tools
	if [ $TG3 == "1" ]; then
		echo -n "Reiniciando o driver tg3..."
		/sbin/ethtool -K eno1 highdma off
		/sbin/rmmod tg3
		/sbin/insmod /lib/modules/`uname -r`/kernel/drivers/net/ethernet/broadcom/tg3.ko
		sleep 3
		ifconfig eno1 | grep "inet " 
	while [ "$?" != "0" ]
	do
		sleep 1
		ifconfig eno1 | grep "inet " 
	done
	fi
	echo "Feito!"
fi

# Se nao tem o script de configuração
echo "Criando scripts de configuração do ambiente"
echo "#!/bin/sh" > $HOME/.setupifpbgba
echo "# Limpa a área de trabalho" >> $HOME/.setupifpbgba
echo "rm -rf $HOME/Área\ de\ Trabalho/*" >> $HOME/.setupifpbgba

echo "# configura o background para o padrão" >> $HOME/.setupifpbgba
echo "if [ -f /usr/share/backgrounds/warty-final-ubuntu.png ]; then" >> $HOME/.setupifpbgba
echo "gsettings set org.gnome.desktop.background picture-uri 'file:///usr/share/backgrounds/warty-final-ubuntu.png'" >> $HOME/.setupifpbgba
echo "fi" >> $HOME/.setupifpbgba
echo "# Configura 30 minutos de tempo para escurecer a tela e desabilita a solicitação de senha quando volta" >> $HOME/.setupifpbgba
echo "gsettings set org.gnome.desktop.session idle-delay 1800" >> $HOME/.setupifpbgba
echo "gsettings set org.gnome.desktop.screensaver lock-enabled false" >> $HOME/.setupifpbgba

chmod ugo+x $HOME/.setupifpbgba

if [ $USER != "root" ] && [ `cat $HOME/.profile | grep setupifpbgba | wc -l` -eq 0 ]; then
	echo "if [ -f ""$HOME/.setupifpbgba"" ]; then" >> $HOME/.profile
        echo ". ""$HOME/.setupifpbgba"" " >> $HOME/.profile
	echo "fi" >> $HOME/.profile
	
	exit 0
fi

if [ ! -d $HOME/bin ]; then
	mkdir $HOME/bin
fi

if [ $TG3 == "1" ]; then
	echo "#!/bin/sh" > $HOME/bin/reset_tg3.sh
	echo "echo -n \"Reiniciando o driver tg3...\"" >> $HOME/bin/reset_tg3.sh
	echo "/sbin/ethtool -K eno1 highdma off" >> $HOME/bin/reset_tg3.sh
	echo "/sbin/rmmod tg3" >> $HOME/bin/reset_tg3.sh
	echo "/sbin/insmod /lib/modules/\`uname -r\`/kernel/drivers/net/ethernet/broadcom/tg3.ko" >> $HOME/bin/reset_tg3.sh
	echo "sleep 3" >> $HOME/bin/reset_tg3.sh
	echo "    ifconfig eno1 | grep \"inet \"" >> $HOME/bin/reset_tg3.sh
	echo "        while [ \"\$?\" != \"0\" ]" >> $HOME/bin/reset_tg3.sh
	echo "       do" >> $HOME/bin/reset_tg3.sh
	echo "               sleep 1" >> $HOME/bin/reset_tg3.sh
	echo "                ifconfig eno1 | grep \"inet \"" >> $HOME/bin/reset_tg3.sh
	echo "       done" >>  $HOME/bin/reset_tg3.sh
	echo "        echo \"Feito!\"" >> $HOME/bin/reset_tg3.sh
	chmod u+x $HOME/bin/reset_tg3.sh
fi

if [ $# -eq 0 ]; then
	USUARIO=$USER
	sudo /bin/bash $0 $USUARIO
	exit $?
else
	USUARIO=$1
fi

echo "Utilizando usuário $USUARIO nas consfigurações"

if [ $TG3 == "1" ]; then

	ARQUIVOS_DEB="linux-headers-4.14.36-041436_4.14.36-041436.201804240906_all.deb linux-headers-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb linux-modules-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb linux-image-unsigned-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb"
	#O kernel 4.14.36 eh uma versão que não tem o problema no driver da placa de rede e funciona o virtualbox
	if [ `uname -r` != "4.14.36-041436-generic" ]; then	
		echo "INSTALANDO O KERNEL 4.14.36"

		if [ -d "/media/$USER/OTACILIO" ]; then
			cd "/media/$USER/OTACILIO"
		else
			cd /tmp
		fi
	
		for I in $ARQUIVOS_DEB
		do	
			# Baixao arquivo .deb
			if [ ! -f $I ]; then
				wget https://kernel.ubuntu.com/~kernel-ppa/mainline/v4.14.36/$I
				if [ $? != 0 ]; then
					echo "Erro ao tentar baixar o arquivo $I"
					exit 1
				fi
			fi
		
			# Instala o arquivo .deb
			dpkg -i $I
			if [ $? != 0 ]; then
				echo "Erro ao instalar $I. Provavelmente o arquivo está corrompido."
				rm -f $I
				exit 1
			fi
		done

		# Atualize o grub para dar o boot pelo novo kernel
		sed -i 's/GRUB_DEFAULT=0/GRUB_DEFAULT="Opções avançadas para Ubuntu>Ubuntu, com o Linux 4.14.36-041436-generic"/g' /etc/default/grub

		update-grub

		# Vamos reiniciar para carregar o kernel novo
		shutdown -r now
	else
		echo "Kernel 4.14.36-041436-generic detectado. Continuando a instalação"
	fi
fi

apt-get update
apt-get upgrade -y

apt-get install -y libelf-dev
apt-get install -y net-tools
apt-get install -y gitk
apt-get install -y build-essential
apt-get install -y whois
# Para usar o comando que supostamente melhora a estabilidade da placa de rede  ethtool -K eno1 highdma off
apt install -y ethtool

# Instala o vim
RET=`dpkg --list | grep vim | awk '{print $2}' | head -n 1`
if [ "$RET" != "vim" ]; then
	echo "====== Instalando o Vim ======"
	apt-get install -y vim
else
	echo "====== Vim já instalado ======"
fi

if [ "$OTA" != "0" ]; then
	# Instala o virtualbox
	RET=`dpkg --list | grep virtualbox | awk '{print $2}'`
	if [ "$RET" != "virtualbox-6.0" ]; then
		echo "====== Instalando o VirtualBox ======"
		cat /etc/apt/sources.list | grep virtualbox
		if [ $? != 0 ]; then
			echo "deb https://download.virtualbox.org/virtualbox/debian bionic contrib">>/etc/apt/sources.list
		fi

		wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
		wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

		apt-get update
		apt-get install -y gcc make linux-headers-$(uname -r) dkms
		apt-get install -y virtualbox-6.0
		usermod -a -G vboxusers $USUARIO
	else
		echo "====== VirtualBox já instalado ======"
	fi
fi

# Este é a configuração de Rhavy.
if [ "$RHAVY" != "0" ]; then
	# Java
	javac 2>&1 > /dev/null
	if [ $? != 2 ]; then
    		echo "====== Instalando o Java ======"
    		add-apt-repository -y ppa:linuxuprising/java
   		apt update
    		apt install -y oracle-java11-installer
    		apt install -y oracle-java11-set-default
    		java -version # Testar Java
    	else
		echo "====== Java já instalado ======"
    	fi

    	# Pycharm
    	RET=`whereis pycharm-community | awk '{print $2}'`
    	if [ "$RET" = "" ]; then
    		echo "====== Instalando o Pycharm ======"
    		snap install pycharm-community --classic
    	else
    		echo "====== Pycharm já instalado ======"
    	fi

    	# Atom
    	RET=`whereis atom | awk '{print $2}'`
    	if [ "$RET" = "" ]; then
   	 	echo "====== Instalando o Atom ======"
    		apt install -y software-properties-common apt-transport-https wget
    		wget -q https://packagecloud.io/AtomEditor/atom/gpgkey -O- | sudo apt-key add -
    		add-apt-repository "deb [arch=amd64] https://packagecloud.io/AtomEditor/atom/any/ any main"
    		apt install -y atom
    	else
	    	echo "====== Atom já instalado ======"
    	fi

    	# Bracket
    	RET=`whereis brackets | awk '{print $2}'`
    	if [ "$RET" = "" ]; then
    		echo "====== Instalando o Bracket ======"
    		add-apt-repository -y ppa:webupd8team/brackets
    		apt-get update
    		apt-get install -y brackets
    	else
	    	echo "====== Bracket já instalado"
    	fi

    	# Git
    	git --version
    	if [ $? != 0 ]; then
    		echo "====== Instalando o Git ======"
    		apt install -y git
    		git --version # Testar Git
    	else
	   	echo "====== Git já instalado ======"
    	fi 

    	# MySQL
    	RET=`whereis mysql | awk '{print $2}'`
    	if [ "$RET" = "" ]; then
    		echo "====== Instalando o MySQL ======"
    		apt install -y mysql-server
    		mysql_secure_installation
    	else
	    	echo "====== MySQL já instalado ======"
    	fi

	# Pip 3
	RET=`dpkg --list | grep python3-pip | awk '{print $2}'`
	if [ "$RET" != "python3-pip" ]; then
		echo "====== Instalando o Pip 3 ======"
		apt-get install -y python3-pip
	else
		echo "====== Pip 3 já instalado ======"
	fi


	# O eclipse do Ubuntu está quebrado. Só funcionou pelo instalador depois dos comentários
	# Instalação do Eclipse
	#RET=`dpkg --list | grep eclipse | awk '{print $2}'`
        #if [ "$RET" != "eclipse" ]; then
        #        echo "====== Instalando o Eclipse ======"
	#	apt  install -y eclipse eclipse-platform
        #else
        #        echo "====== Eclipse já instalado ======"
        #fi
	if [ ! -d /usr/local/bin/eclipse ]; then
		cd /tmp
		if [ ! -f eclipse-jee-2019-03-R-linux-gtk-x86_64.tar.gz ]; then
			wget http://eclipse.bluemix.net/packages/2019-03/data/eclipse-jee-2019-03-R-linux-gtk-x86_64.tar.gz
		fi
		echo "Extraindo Eclipse"
		tar -zxvf eclipse-jee-2019-03-R-linux-gtk-x86_64.tar.gz 2>&1 > /dev/null
		if [ $? != 0 ]; then
			rm -rf  eclipse-jee-2019-03-R-linux-gtk-x86_64.tar.gz
			echo "Erro ao extrair o instalador do Eclipse. Arquivo possivelmente corrompido"
			exit 1
		fi
		mv eclipse /usr/local/bin/eclipse
		cd
		echo "PATH=\$PATH:/usr/local/bin/eclipse" >> "/home/$USUARIO/.profile"

		echo "[Desktop Entry]" >  /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Name=Eclipse"    >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Type=Application">> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Exec=/usr/local/bin/eclipse/eclipse" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Terminal=false" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Icon=/usr/local/bin/eclipse/icon.xpm" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Comment=Integrated Development Environment" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "NoDisplay=false" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Categories=Development;IDE;">> /home/$USUARIO/.local/share/applications/eclipse.desktop
		echo "Name[Pt-BR]=Eclipse" >> /home/$USUARIO/.local/share/applications/eclipse.desktop
	else
		echo "Eclipse já instalado"
	fi
fi

if [ "$BARROS" != "0" ]; then
	RET=`dpkg --list | grep postgresql | awk '{print $2}'`
	if [ "$RET" != "postgresql" ]; then
		echo "====== Instalando o PostgreSQL ======"
		apt-get install -y postgresql postgresql-contrib postgis
		update-rc.d postgresql enable
		service postgresql start
	else
		echo "====== PostgreSQL já instalado ======"
		service postgresql restart
	fi
	service postgresql status

	RET=`java -version 2>&1 | awk '{print $1}' | head -n 1`
        if [ "$RET" != "openjdk" ]; then
                echo "====== Instalando o OpenJDK ======"
		add-apt-repository -y ppa:openjdk-r/ppa
		apt-get update
		apt-get install -y openjdk-8-jdk
#		java-common oracle-java8-installer oracle-java8-set-default
		update-alternatives --config java
        else
		echo "====== OpenJDK já instalado ======"
        fi

	RET=`dpkg --list | grep netbeans | awk '{print $2}'`
        if [ "$RET" != "netbeans" ]; then
		echo "====== Instalando o NetBeans ======"
		apt  install -y netbeans
	else
		echo "====== Netbeans já instalado ======"
	fi

	RET=`dpkg --list | grep astah-professional | awk '{print $2}'`
        if [ "$RET" != "astah-professional" ]; then
		echo "====== Instalando o Astah ======"
		cd /tmp 
		astah-professional_8.1.0.3ac74f-0_all.deb
		wget astah-professional_8.1.0.3ac74f-0_all.deb http://cdn.change-vision.com/files/astah-professional_8.1.0.3ac74f-0_all.deb
		dpkg -i astah-professional_8.1.0.3ac74f-0_all.deb
		cd
	else
		echo "====== Asth já instalado ======"
	fi

	if [ ! -f /usr/local/bin/brmodelo.sh ]; then
		echo "====== Instalando o brModelo ======"
		cd /tmp
		wget brModelo.jar http://www.sis4.com/brModelo/brModelo.jar
		mv brModelo.jar /usr/local/bin
		echo "#! /bin/bash" > /usr/local/bin/brmodelo.sh
		echo "java -jar /usr/local/bin/brModelo.jar" >> /usr/local/bin/brmodelo.sh
		chmod ugo+x /usr/local/bin/brmodelo.sh
	else
		echo "====== brModelo já instalado ======"
	fi
fi

if [ "$ERICK" != "0" ]; then
	RET=`whereis vmware | awk '{print $2}'`
        if [ "$RET" != "/usr/bin/vmware" ]; then
		echo "====== Instalando o vmware ======"
		cd /tmp
		if [ ! -f ./vmware.bin ]; then
			wget -O ./vmware.bin https://download3.vmware.com/software/player/file/VMware-Player-15.5.1-15018445.x86_64.bundle?HashKey=7c94176a06d89d5a3c7043fedf9c341e&params=%7B%22sourcefilesize%22%3A%22157.73+MB%22%2C%22dlgcode%22%3A%22PLAYER-1551%22%2C%22languagecode%22%3A%22en%22%2C%22source%22%3A%22DOWNLOADS%22%2C%22downloadtype%22%3A%22manual%22%2C%22eula%22%3A%22N%22%2C%22downloaduuid%22%3A%228181c761-efe1-4e17-a331-d6e3b192cfb8%22%2C%22purchased%22%3A%22N%22%2C%22dlgtype%22%3A%22Product+Binaries%22%2C%22productversion%22%3A%2215.5.1%22%2C%22productfamily%22%3A%22VMware+Workstation+Player%22%7D&AuthKey=1582306879_45f9191e5cbfacb14b403478fd433120
		fi
		chmod u+x vmware.bin
		./vmware.bin
		cd
	else
		echo "====== Vmware já instalado ======"
	fi
fi


# Remove arquivos não utilizados

apt-get autoclean -y
apt-get autoremove -y

snap install gnome-3-26-1604
snap connect gnome-system-monitor:gnome-3-26-1604 gnome-3-26-1604
