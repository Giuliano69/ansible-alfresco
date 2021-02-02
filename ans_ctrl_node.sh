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
	export THIRD_PARTY_DIR="files/third-party"
	
	export TOMCAT_DOWNLOAD=https://downloads.apache.org/tomcat/tomcat-9/v9.0.41/bin/apache-tomcat-9.0.41.tar.gz
	
	export ACTIVEMQ_DOWNLOAD=http://archive.apache.org/dist/activemq/5.16.1/apache-activemq-5.16.1-bin.tar.gz
	
	export JDBCPOSTGRES_DOWNLOAD=https://jdbc.postgresql.org/download/postgresql-42.2.18.jar

	export ACS_DOWNLOAD=https://artifacts.alfresco.com/nexus/service/local/repositories/releases/content/org/alfresco/alfresco-content-services-community-distribution/6.2.0-ga/alfresco-content-services-community-distribution-6.2.0-ga.zip
	#export ACSCD_ZIP=https://download.alfresco.com/cloudfront/release/community/201911-GA-build-368/alfresco-content-services-community-distribution-6.2.0-ga.zip
	# alfresco.war, share.war, ROOT.war, _vt_bin.war
					
	#Alfresco Search Services (ASS) zip
	#export ASS_DOWNLOAD=https://artifacts.alfresco.com/nexus/service/local/repositories/releases/content/org/alfresco/alfresco-search-services/2.1.0-A5/alfresco-search-services-2.1.0-A5.zip
	export ASS_DOWNLOAD=https://download.alfresco.com/cloudfront/release/community/SearchServices/1.4.0/alfresco-search-services-1.4.0.zip
	
	#Googledoc Alfresco Module Package .amp
	export GDRIVEREPO_DOWNLOAD=https://artifacts.alfresco.com/nexus/content/repositories/public/org/alfresco/integrations/alfresco-googledrive-repo-community/3.2.0/alfresco-googledrive-repo-community-3.2.0.amp
	export GDRIVESHARE_DOWNLOAD=https://artifacts.alfresco.com/nexus/content/repositories/public/org/alfresco/integrations/alfresco-googledrive-share/3.2.0/alfresco-googledrive-share-3.2.0.amp

	
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function check_main_urls() {
	echo
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo "Checking for the availability of the URLs inside script..."
	echoblue "- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -"
	echo

	URLERROR=0
	
	for REMOTE in $ACS_DOWNLOAD $TOMCAT_DOWNLOAD  $ASS_DOWNLOAD  \
	        $JDBCPOSTGRES_DOWNLOAD $ACTIVEMQ_DOWNLOAD \
	        $GDRIVEREPO_DOWNLOAD $GDRIVESHARE_DOWNLOAD
	do
		if ! wget --spider "$REMOTE" --no-check-certificate >& /dev/null;
		then
				echored "In alfinstall.sh, please fix this URL: $REMOTE"
				URLERROR=1
		fi
	done
	
	if [ $URLERROR = 1 ]
	then
	    echo
	    echored "Please fix the above errors and rerun."
	    echo
	    exit
	else 
		echogreen "Every URL is valid ! Proceed with download."
	fi
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
function download_third_party(){
	if [ ! -d "./$THIRD_PARTY_DIR" ]; then
	    echoblue "Creating directory directory: $THIRD_PARTY_DIR"
		mkdir -p "./$THIRD_PARTY_DIR"
		mkdir -p "./$THIRD_PARTY_DIR/amps"
		mkdir -p "./$THIRD_PARTY_DIR/amps_share"
    fi
    echo
    
	echoblue "Start dowloading third party files... "
	cd "$THIRD_PARTY_DIR" || exit
	
	if [ ! -f "$(basename $ACS_DOWNLOAD)" ]; then
		echogreen "Download Afresco Content services Comunity: $(basename $ACS_DOWNLOAD) "
		curl -# -L -O $ACS_DOWNLOAD		
	else
		echogreen "Found Afresco Content services Comunity: $(basename $ACS_DOWNLOAD)"
	fi
	
	if [ ! -f "$(basename $TOMCAT_DOWNLOAD)" ]; then
		echogreen "Download Apache Tomcat Archive: $(basename $TOMCAT_DOWNLOAD)"
		curl -# -L -O $TOMCAT_DOWNLOAD
	else
		echogreen "Found Apache Tomcat Archive: $(basename $TOMCAT_DOWNLOAD)"
	fi
	
	if [ ! -f "$(basename $ASS_DOWNLOAD)" ]; then
		echogreen "Download Alfresco Shearch Services: $(basename $ASS_DOWNLOAD)"
		curl -# -L -O $ASS_DOWNLOAD
	else
		echogreen "Found Alfresco Shearch Services: $(basename $ASS_DOWNLOAD)"
	fi
	
	if [ ! -f "$(basename $JDBCPOSTGRES_DOWNLOAD)" ]; then
		echogreen "Download Postgres Database Driver: $(basename $JDBCPOSTGRES_DOWNLOAD)"
		curl -# -L -O $JDBCPOSTGRES_DOWNLOAD
	else
		echogreen "Found Postgres Database Driver: $(basename $JDBCPOSTGRES_DOWNLOAD)"
	fi
	
	if [ ! -f "$(basename $ACTIVEMQ_DOWNLOAD)" ]; then
		echogreen "Download Apache ActiveMQ: $(basename $ACTIVEMQ_DOWNLOAD)"
		curl -# -L -O $ACTIVEMQ_DOWNLOAD
	else
		echogreen "Found Apache ActiveMQ: $(basename $ACTIVEMQ_DOWNLOAD)"
	fi
	
	if [ ! -f "./amps/$(basename $GDRIVEREPO_DOWNLOAD)" ]; then
		echogreen "Download Google drive integration: $(basename $GDRIVEREPO_DOWNLOAD)"
		#subshell to temporary change directory
		( cd ./amps_share ; curl -# -L -O $GDRIVEREPO_DOWNLOAD )
	else
		echogreen "Found Google drive integration: $(basename $GDRIVEREPO_DOWNLOAD)"
	fi
	
	if [ ! -f "./amps_share/$(basename $GDRIVESHARE_DOWNLOAD)" ]; then
		echogreen "Download Google Share integration: $(basename $GDRIVESHARE_DOWNLOAD)"
		#subshell to temporary change directory
		( cd ./amps_share ; curl -# -L -O $GDRIVESHARE_DOWNLOAD )
	else
		echogreen "Found Google Share integration: $(basename $GDRIVESHARE_DOWNLOAD)"
	fi
	
	cd .. 
	
	echoblue "Done"
	
}
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#-
#^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

#===================
export_variables
check_main_urls
download_third_party
