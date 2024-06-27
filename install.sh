#!/bin/sh
set -e

GROUP_NAME=www-data
INSTALL_COMMAND=apt-get
if [[ -n "$(command -v yum)" ]]; then
  INSTALL_COMMAND=yum
fi

#checking is www-data group exist
echo -e "\e[33mChecking GIT \e[39m"
if [[ $(getent group $GROUP_NAME) ]]
then
  echo -e "\e[32m    Group exist \e[39m"
else
  echo -e "\e[31m    Group not exist, adding group - $GROUP_NAME \e[39m" && groupadd $GROUP_NAME
fi


#checking is git installed
echo -e "\e[33mChecking GIT \e[39m"
if hash git > /dev/null 2>&1
then
  echo -e "\e[32m    GIT installed \e[39m"
else
  echo -e "\e[31m    GIT not installed, install started \e[39m" && $INSTALL_COMMAND install -y git
fi

#checking is docker installed
echo -e "\e[33mChecking DOCKER \e[39m"
if hash docker > /dev/null 2>&1
then
  echo -e "\e[32m    DOCKER installed \e[39m"
else
  echo -e "\e[31m    DOCKER not installed, install started \e[39m" && cd /usr/local/src && wget -qO- https://get.docker.com/ | sh
fi

#checking is installed docker-compose
echo -e "\e[33mChecking DOCKER-COMPOSE \e[39m"
if hash docker-compose > /dev/null 2>&1
then
  echo -e "\e[32m    DOCKER-COMPOSE installed \e[39m"
else
  echo -e "\e[31m    DOCKER-COMPOSE not installed, install started \e[39m" && curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && source ~/.bashrc
fi

#show message that all required packets installed
echo -e "\n\e[32mAll required packets installed \e[39m\n\n"

echo -e "\e[33mSet work folder path (left empty for use default path. Default path = /var/www/)\e[39m"
read WORK_PATH

if [[ "$WORK_PATH" = "" ]]; then
  WORK_PATH=/var/www
fi

echo $WORK_PATH

# downloading docker from git source
DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
if [ ! -d "$DOCKER_FOLDER_PATH" ]
then
  mkdir $DOCKER_FOLDER_PATH

  echo -e "\e[33mDocker containers is not installed. Installation starting... \e[39m\n"

  cd $WORK_PATH && \
  git clone https://github.com/darbit-ru/bitrixdock.git && \
  cd /var/ && chmod -R 775 www/ && chown -R root:www-data www/ && \
  cd $DOCKER_FOLDER_PATH
else
  echo -e "\e[33mBitrixDock is installed. Clear all and remove all containers to reinstall\e[39m"
fi

#
#
#
#
#
#echo "Create folder struct"
#mkdir -p /var/www/bitrix && \
#cd /var/www && \
#rm -f /var/www/bitrix/bitrixsetup.php && \
#curl -fsSL https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php -o /var/www/bitrix/bitrixsetup.php && \
#rm -rf /var/www/bitrixdock && \
#git clone --depth=1 https://github.com/bitrixdock/bitrixdock.git && \
#chmod -R 775 /var/www/bitrix && chown -R root:www-data /var/www/bitrix && \
#
#echo "Config"
#cp -f /var/www/bitrixdock/.env_template /var/www/bitrixdock/.env
#sed -i 's/SITE_PATH=.\/www/SITE_PATH=\/var\/www\/bitrix/' /var/www/bitrixdock/.env
#
#echo "Run"
#docker compose -p bitrixdock down
#docker compose -f /var/www/bitrixdock/docker-compose.yml -p bitrixdock up -d
