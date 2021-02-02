#!/bin/bash
# https://docs.alfresco.com/6.2/concepts/dev-arch-overview.html
# -------
# Script for install of Alfresco
#
# Copyright 2013-2017 Loftux AB, Peter Löfgren
# Distributed under the Creative Commons Attribution-ShareAlike 3.0 Unported License (CC BY-SA 3.0)
# -------
#set -xv
#trap read debug
# shellcheck disable=SC2162
			
# Color variables
#txtund=$(tput sgr 0 1)          # Underline
txtbld=$(tput bold)             # Bold
bldred=${txtbld}$(tput setaf 1) #  red
bldgre=${txtbld}$(tput setaf 2) #  red
bldblu=${txtbld}$(tput setaf 4) #  blue
#bldwht=${txtbld}$(tput setaf 7) #  white
txtrst=$(tput sgr0)             # Reset
#info=${bldwht}*${txtrst}        # Feedback
#pass=${bldblu}*${txtrst}
warn=${bldred}*${txtrst}
ques=${bldblu}?${txtrst}

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

function echoblue () {
  echo "${bldblu}$1${txtrst}"
}
function echored () {
  echo "${bldred}$1${txtrst}"
}
function echogreen () {
  echo "${bldgre}$1${txtrst}"
}

#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function export_variables() {
	
	export INSTALL_DIR="/tmp/alfrescoinstall"
	
	export ALFRESCO_DB_NAME="alfresco"
	export ALFRESCO_DB_USER="alfresco"
	export ALFRESCO_DB_USER_PASS="alfresco"

	
	export ALF_HOME=/opt/alfresco
	export ALF_DATA_HOME=$ALF_HOME/alf_data
	export CATALINA_HOME=$ALF_HOME/tomcat
	export ALF_USER=alfresco
	export ALF_GROUP=$ALF_USER
	export APTVERBOSITY="-qqy"
	export TMP_INSTALL=/tmp/alfrescoinstall
	export DEFAULTYESNO="y"
	
	CPU=$(uname -m)
	export CPU
	# can be x86_64 or aarch64
    # JAVA_HOME depends on cpu type
	if [ "$CPU" == "aarch64" ]; then
		echogreen "Installing IDK on ARM64 CPU"
		export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-arm64"
	else
		echogreen "Installing JDK on x86_64 CPU"
		export JAVA_HOME="/usr/lib/jvm/java-11-openjdk-amd64"
	fi
	
	DISTRO=$(lsb_release -si)
	export DISTRO
	
	VERSION_ID=$(lsb_release -sr)
	export VERSION_ID
	
	
	#Change this to prefered locale to make sure it exists. This has impact on LibreOffice transformations
	# find yours with command: less /usr/share/i18n/SUPPORTED
	export LOCALESUPPORT=it_IT.UTF-8
	
			
	if [ "$DISTRO" != "Ubuntu" ]; then
		echored "Installing Linux version different from Ubuntu NOT supported"
		exit 1
	fi
	if [ "$VERSION_ID" \< "20.04" ]; then
		echored "Installing on Ubuntu prior then 20.04 NOT supported"
		exit 1
	fi
	
	if [ "$CPU" == "aarch64" ]; then
		echogreen "Installing on ARM64 CPU"
	elif [ "$CPU" == "x86_64" ]; then
		echogreen "Installing on x86_64 CPU"
	else 
		echored "CPU $CPU NOT supported"
	fi
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function system_configuration() {
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Preparing for install. Updating the apt package index files..."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	sudo apt "$APTVERBOSITY" update
	echo

	#curl
	if [ "$(which curl)" = "" ]; then
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		echo "You need to install curl. Curl is used for downloading components to install."
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		sudo apt "$APTVERBOSITY" install curl
	fi

	#wget	
	if [ "$(which wget)" = "" ]; then
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		echo "You need to install wget. Wget is used for downloading components to install."
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		sudo apt "$APTVERBOSITY" install wget
	fi
	
	#netstat	
	if [ "$(which netstat)" = "" ]; then
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		echo "You need to install netstat. Netstat is used for configuring Libreoffice."
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		sudo apt "$APTVERBOSITY" install net-tools
	fi

	# ntpq
	if [ "$(which ntpq)" = "" ]; then
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		echo "You need to install ntp. (Network Time Protocol) . NTP is used to manage ans sync the system clock over a network."
		echogreen "You will be also asked to configure your timezone"
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		sudo apt "$APTVERBOSITY" install ntp 
		sudo dpkg-reconfigure tzdata
		#-p : Print a list of the peers known to the server as well as a summary of their state
		ntpq -p
		timedatectl status
	fi

	# unzip
	if [ "$(unzip)" = "" ]; then
	sudo apt "$APTVERBOSITY" install unzip
	fi



	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "You need to set the locale to use when running tomcat Alfresco instance."
	echo "This has an effect on date formats for transformations and support for"
	echo "international characters."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Enter the default locale to use: " -i "$LOCALESUPPORT" LOCALESUPPORT
	#install locale to support that locale date formats in open office transformations
	sudo locale-gen "$LOCALESUPPORT"
	echo
	echogreen "Finished updating locale"
	echo
	
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Ubuntu default for number of allowed open files in the file system is too low"
	echo "for alfresco use and tomcat may because of this stop with the error"
	echo "\"too many open files\". You should update this value if you have not done so."
	echo "Read more at http://wiki.alfresco.com/wiki/Too_many_open_files"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Add limits.conf${ques} [y/n] " -i "$DEFAULTYESNO" updatelimits
	if [ "$updatelimits" = "y" ]; then
	  echo "alfresco  soft  nofile  8192" | sudo tee -a /etc/security/limits.conf
	  echo "alfresco  hard  nofile  65536" | sudo tee -a /etc/security/limits.conf
	  echo
	  echogreen "Updated /etc/security/limits.conf"
	  echo
	  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session
	  echo "session required pam_limits.so" | sudo tee -a /etc/pam.d/common-session-noninteractive
	  echo
	  echogreen "Updated /etc/security/common-session*"
	  echo
	else
	  echo "Skipped updating limits.conf"
	  echo
	fi


}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function create_alfresco_user(){
	#test passed
	if id "$ALF_USER" &>/dev/null; then
	    echored "User $ALF_USER already exist"
	else
		echo
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		echo "You need to add a system user that runs the tomcat Alfresco instance."
		echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
		read -e -p "Add alfresco system user${ques} [y/n] " -i "$DEFAULTYESNO" addalfresco
		if [ "$addalfresco" = "y" ]; then
		  #sudo groupadd "$ALF_USER"
		  #set password for alfresco user
		  
		  sudo useradd -m  "$ALF_USER" -p "$ALF_USER"
		  echo "$ALF_USER":"$ALF_USER" | sudo chpasswd
		  #let 	user be sudo user
		  sudo usermod -aG sudo "$ALF_USER"

		  echo
		  echogreen "Finished adding alfresco user"
		  echo
		else
		  echo "Skipping adding alfresco user"
		  echo
		fi
	fi
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function install_postgres(){
echo
echoblue "--------------------------------------------"
echogreen "This script will install PostgreSQL."
echogreen "and create alfresco database and user."
echoblue "--------------------------------------------"
echo

read -e -p "Install PostgreSQL database? [y/n] " -i "y" installpg
if [ "$installpg" = "y" ]; then
	sudo apt "$APTVERBOSITY" install postgresql postgresql-contrib

echo
echoblue "--------------------------------------------"
echogreen "Creating alfresco database and user."
echoblue "--------------------------------------------"
echo  
	sudo su postgres <<EOF
	createdb  -E UTF8  $ALFRESCO_DB_NAME;
	psql -c "CREATE USER $ALFRESCO_DB_USER WITH PASSWORD '$ALFRESCO_DB_USER_PASS';"
	psql -c "grant all privileges on database $ALFRESCO_DB_NAME to $ALFRESCO_DB_USER;"
	psql -c "ALTER DATABASE $ALFRESCO_DB_NAME  OWNER TO $ALFRESCO_DB_USER"
	echo "Postgres User '$ALFRESCO_DB_USER' and database '$ALFRESCO_DB_NAME' created."
EOF
	
#To allow password-authenticated connections through TCP/IP, ensure that the PostgreSQL configuration file, pg_hba.conf, 
# and postgresql.conf  contain the following lines:	
sudo sed -i '/# IPv4 local connections:/{n;s/.*/host all all 0.0.0.0\/0 password/}' /etc/postgresql/12/main/pg_hba.conf
sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/"               /etc/postgresql/12/main/postgresql.conf 
sudo service postgresql restart

fi	
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function install_jdk() {
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Install Java JDK."
	echo "This will install OpenJDK 11 version of Java. If you prefer Oracle Java 11 "
	echo "you need to download and install that manually."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Install OpenJDK${ques} [y/n] " -i "$DEFAULTYESNO" installjdk
	if [ "$installjdk" = "y" ]; then
	  echoblue "Installing OpenJDK..."
	  sudo apt install openjdk-11-jdk "$APTVERBOSITY"	  
	  #append JAVA_HOME to system variables
	  # JAVA_HOME is defined in export_variables depending on cpu type
	  echo "JAVA_HOME=\"$JAVA_HOME\"" | sudo tee -a /etc/environment
	  
	  #TODO may create a symlink to /usr/java/jdk-11, beeing set to JAVA_HOME, 
	  # removing difference between arm64 and amd64 ??
	  
	  echo
	  echogreen "Make sure correct default java is selected!"
	  echo
	  sudo update-alternatives --config java
	  echo
	  echogreen "Finished installing OpenJDK "
	  echo
	else
	  echo "Skipping install of OpenJDK."
	  echored "IMPORTANT: You need to install other JDK and adjust paths for the install to be complete"
	  echo
	fi

}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function install_libreoffice() {
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Install LibreOffice."
	echo "This will download Ubuntu APT standard packages"
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Install LibreOffice${ques} [y/n] " -i "$DEFAULTYESNO" installibreoffice
	if [ "$installibreoffice" = "y" ]; then
	  sudo apt "$APTVERBOSITY" install libreoffice
	  echoblue "Installing some support fonts for better transformations."
	  # libxinerama1 libglu1-mesa needed to get LibreOffice to work. Add the libraries that Alfresco mention in documentatinas required.
	  # https://docs.alfresco.com/6.1/concepts/install-lolibfiles.html
		
	  # 
	  sudo apt "$APTVERBOSITY" install libfontconfig1 libice6 libsm6 libxrender1  libxext6  libxinerama1 libcups2 libglu1-mesa libcairo2 libgl1-mesa
	  
	  ###1604 fonts-droid not available, use fonts-noto instead
	  sudo apt "$APTVERBOSITY" install ttf-mscorefonts-installer fonts-noto fontconfig   
	  echo
	  echogreen "Finished installing LibreOffice from standard apt repository"
	  echogreen "set jodconverter.officeHome=/usr/lib/libreoffice in alfresco-global.properties"
	else
	  echo
	  echo "Skipping install of LibreOffice"
	  echored "If you install LibreOffice/OpenOffice separetely, remember to update alfresco-global.properties"
	  echored "Also run: sudo apt install ttf-mscorefonts-installer fonts-droid libxinerama1"
	  echo
	fi

}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function install_imagemagik() {
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Install ImageMagick."
	echo "This will ImageMagick from Ubuntu packages."
	echo "It is recommended that you install ImageMagick."
	echo "If you prefer some other way of installing ImageMagick, skip this step."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	read -e -p "Install ImageMagick${ques} [y/n] " -i "$DEFAULTYESNO" installimagemagick
	if [ "$installimagemagick" = "y" ]; then	
		echoblue "Installing ImageMagick. Fetching packages..."
		sudo apt "$APTVERBOSITY" install imagemagick ghostscript libgs-dev libjpeg62 libpng16-16
		echo
		echoblue "Creating symbolic link for ImageMagick-6."
		sudo ln -s /etc/ImageMagick-6 /etc/ImageMagick
		echo
		echogreen "Finished installing ImageMagick"
		echo
	else
		echo
		echo "Skipping install of ImageMagick"
		echored "Remember to install ImageMagick later. It is needed for thumbnail transformations."
		echo
fi
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function create_alfresco_home() {
	if [ -d "$ALF_HOME" ]; then
		echoblue "Creating Alfressco Home directory: $ALF_HOME"
		sudo mkdir -p $ALF_HOME
		sudo chown -R $ALF_USER:$ALF_GROUP $ALF_HOME
	fi
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


export_variables
system_configuration
create_alfresco_user
install_postgres
install_jdk
install_libreoffice
install_imagemagik
create_alfresco_home
