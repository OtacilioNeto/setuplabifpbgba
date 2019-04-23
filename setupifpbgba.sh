#!/bin/bash

RHAVY="1"

ARQUIVOS_DEB="linux-headers-4.14.36-041436_4.14.36-041436.201804240906_all.deb linux-headers-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb linux-modules-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb linux-image-unsigned-4.14.36-041436-generic_4.14.36-041436.201804240906_amd64.deb"

#O kernel 4.14.36 eh uma versão que não tem o problema no driver da placa de rede e funciona o virtualbox
if [ `uname -a | awk '{print $3}'` != "4.14.36-041436-generic" ]; then	
	echo "INSTALANDO O KERNEL 4.14.36"

	cd /tmp
	
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

apt-get update
apt-get upgrade -y

# Instala o virtualbox
RET=`dpkg --list | grep virtualbox | awk '{print $2}'`
if [ "$RET" != "virtualbox-6.0" ]; then
	cat /etc/apt/sources.list | grep virtualbox
	if [ $? != 0 ]; then
		echo "deb https://download.virtualbox.org/virtualbox/debian bionic contrib">>/etc/apt/sources.list
	fi

	wget -q https://www.virtualbox.org/download/oracle_vbox_2016.asc -O- | sudo apt-key add -
	wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo apt-key add -

	apt-get update
	apt-get install -y gcc make linux-headers-$(uname -r) dkms
	apt-get install -y virtualbox-6.0
	usermod -a -G vboxusers aluno
fi

# Este é a configuração de Rhavy.
if [ $RHAVY != "0" ]; then
	# Java
	javac 2>&1 > /dev/null
	if [ $? != 2 ]; then
    		echo "====== Instalando o Java ======"
    		add-apt-repository ppa:linuxuprising/java
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
	RET=`dpkg --list | grep python3-pip`
	if [ "$RET" != "python3-pip" ]; then
		echo "====== Instalando o Pip 3 ======"
		apt-get install -y python3-pip
	else
		echo "====== Pip 3 já instalado ======"
	fi
fi

# Remove arquivos não utilizados

apt-get autoclean -y
apt-get autoremove -y
