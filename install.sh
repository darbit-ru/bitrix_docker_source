#!/bin/sh
set -e

REPO_PATH=https://github.com/darbit-ru/bitrixdock.git
GROUP_NAME=www-data
INSTALL_COMMAND=apt-get
if [[ -n "$(command -v yum)" ]]; then
  INSTALL_COMMAND=yum
fi

# checking is www-data group exist
echo -e "\e[33mChecking user group www-data \e[39m"
if [[ $(getent group $GROUP_NAME) ]]
then
  echo -e "\e[32m    Group exist \e[39m"
else
  echo -e "\e[31m    Group not exist, adding group - $GROUP_NAME \e[39m" && groupadd $GROUP_NAME > /dev/null 2>&1
fi

# checking is git installed
echo -e "\e[33mChecking GIT \e[39m"
if hash git > /dev/null 2>&1
then
  echo -e "\e[32m    GIT installed \e[39m"
else
  echo -e "\e[31m    GIT not installed, install started \e[39m" && $INSTALL_COMMAND install -y git > /dev/null 2>&1
fi

# checking is docker installed
echo -e "\e[33mChecking DOCKER \e[39m"
if hash docker > /dev/null 2>&1
then
  echo -e "\e[32m    DOCKER installed \e[39m"
else
  echo -e "\e[31m    DOCKER not installed, install started \e[39m" && cd /usr/local/src && wget -qO- https://get.docker.com/ | sh > /dev/null 2>&1
fi

# checking is installed docker-compose
echo -e "\e[33mChecking DOCKER-COMPOSE \e[39m"
if hash docker-compose > /dev/null 2>&1
then
  echo -e "\e[32m    DOCKER-COMPOSE installed \e[39m"
else
  echo -e "\e[31m    DOCKER-COMPOSE not installed, install started \e[39m" && curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && source ~/.bashrc > /dev/null 2>&1
fi

# show message that all required packets installed
echo -e "\n\e[32mAll required packets installed \e[39m\n\n"

# reading work folder path
echo -e "\e[33mSet work folder path (left empty for use default path. Default path = /var/www)\e[39m"
read WORK_PATH

# if work folder is empty, setting default value
if [[ "$WORK_PATH" = "" ]]; then
  WORK_PATH=/var/www
fi

# downloading docker from git source
DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
if [ ! -d "$DOCKER_FOLDER_PATH" ]
then
  #creating work folders if they are not exist
  mkdir -p $DOCKER_FOLDER_PATH

  echo -e "\n\n\e[33mDocker containers is not installed. Installation starting... \e[39m\n"

  # downloading files from repo
  echo -e "\e[33mCloning repo to local... \e[39m"
  cd $WORK_PATH && \
  git clone $REPO_PATH > /dev/null 2>&1 && \
  cd $(dirname $WORK_PATH) && chmod -R 775 $(basename $WORK_PATH) && chown -R root:www-data $(basename $WORK_PATH) && \
  cd $DOCKER_FOLDER_PATH
  echo -e "\e[32m    Done \e[39m\n"

  # copy .env file from template file
  echo -e "\e[33mCopy environment setting file and starting configuration \e[39m"
  cp -f .env_template .env && \
  echo -e "\e[32m    Done \e[39m\n"

  # chosing PHP version
  echo -e "\e[33mSelect PHP version [7.4, 8.0, 8.1, 8.2, 8.3]: \e[39m"
  read PHP_VERSION
  until [[ $PHP_VERSION != "7.4" || $PHP_VERSION != "8.0" || $PHP_VERSION != "8.1" || $PHP_VERSION != "8.2" || $PHP_VERSION != "8.3" ]]
  do
      echo -e "\e[33mSelect PHP version [7.4, 8.0, 8.1, 8.2, 8.3]: \e[39m"
      read PHP_VERSION
  done
  echo -e "\n"

  # select php version
  if [[ $PHP_VERSION == "7.4" ]]; then
    SELECTED_PHP_VERSION=php74
  elif [[ $PHP_VERSION == "8.0" ]]; then
    SELECTED_PHP_VERSION=php80
  elif [[ $PHP_VERSION == "8.1" ]]; then
    SELECTED_PHP_VERSION=php81
  elif [[ $PHP_VERSION == "8.2" ]]; then
    SELECTED_PHP_VERSION=php82
  elif [[ $PHP_VERSION == "8.3" ]]; then
      SELECTED_PHP_VERSION=php83
  fi
  sed -i "s/#PHP_VERSION#/$SELECTED_PHP_VERSION/g" $DOCKER_FOLDER_PATH/.env

  # set database root password
  echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
  read MYSQL_DATABASE_ROOT_PASSWORD
  until [[ ! -z "$MYSQL_DATABASE_ROOT_PASSWORD" ]]
  do
    echo -e "\e[33mSet MYSQL database ROOT PASSWORD: \e[39m"
    read MYSQL_DATABASE_ROOT_PASSWORD
  done
  sed -i "s/#DATABASE_ROOT_PASSWORD#/$MYSQL_DATABASE_ROOT_PASSWORD/g" $DOCKER_FOLDER_PATH/.env
  echo -e "\n"

  # checking site name domain
  echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
  read SITE_NAME
  domainRegex="(^([a-zA-Z0-9](([a-zA-Z0-9-]){0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{0,10}$)"
  until [[ $SITE_NAME =~ $domainRegex ]]
  do
    echo -e "\e[33mEnter site name (websitename.domain | example: mail.ru): \e[39m"
    read SITE_NAME
  done
  sed -i "s/#DOMAIN_URL#/$SITE_NAME/g" $DOCKER_FOLDER_PATH/.env
  echo -e "\n"

  # checking site installation type
  echo -e "\e[33mSite installation type? (C - clear install bitrixsetup.php / R - restore from backup): \e[39m"
  read INSTALLATION_TYPE
  until [[ $INSTALLATION_TYPE == [CR] ]]
  do
    echo -e "\e[33mSite installation type? (C - clear install bitrixsetup.php / R - restore from backup): \e[39m"
    read INSTALLATION_TYPE
  done
  echo -e "\n"

  # checking site installation type
  echo -e "\e[33mDo you want install SSL from letsencrypt? (Y/N): \e[39m"
  read SSL_INSTALL_ACTION
  until [[ $SSL_INSTALL_ACTION != "Y" || $SSL_INSTALL_ACTION != "N" ]]
  do
    echo -e "\e[33mDo you want install SSL from letsencrypt? (Y/N): \e[39m"
    read SSL_INSTALL_ACTION
  done
  echo -e "\n"

  if [[ $SSL_INSTALL_ACTION == "Y" ]]
  then
    echo -e "\e[33mEnter domain admin email: \e[39m"
    read DOMAIN_ADMIN_EMAIL
    until [[ "$DOMAIN_ADMIN_EMAIL" != "" ]]
    do
      echo -e "\e[33mEnter domain admin email: \e[39m"
      read DOMAIN_ADMIN_EMAIL
    done
    sed -i "s/#DOMAIN_EMAIL#/$DOMAIN_ADMIN_EMAIL/g" $DOCKER_FOLDER_PATH/.env
    echo -e "\n"
  else
    DOMAIN_ADMIN_EMAIL=test@mail.no
    sed -i "s/#DOMAIN_EMAIL#/$DOMAIN_ADMIN_EMAIL/g" $DOCKER_FOLDER_PATH/.env
  fi

  # creating website folder
  WEBSITE_FILES_PATH=$WORK_PATH/bitrix
  echo -e "\e[33mCreating website folder \e[39m"
  mkdir -p $WEBSITE_FILES_PATH && \
  cd $WEBSITE_FILES_PATH && \
  if [[ $INSTALLATION_TYPE == "C" ]]; then wget http://www.1c-bitrix.ru/download/scripts/bitrixsetup.php > /dev/null 2>&1; elif [[ $INSTALLATION_TYPE == "R" ]]; then wget http://www.1c-bitrix.ru/download/scripts/restore.php > /dev/null 2>&1; fi && \
  cd $(dirname $WORK_PATH) && chmod -R 775 $(basename $WORK_PATH) && chown -R root:www-data $(basename $WORK_PATH)
  sed -i "s/#WEBSITE_PATH#/$WEBSITE_FILES_PATH/g" $DOCKER_FOLDER_PATH/.env
  echo -e "\e[32m    Done \e[39m\n"

  echo -e "\n\e[33mConfiguring NGINX conf file \e[39m"
  cp -f $DOCKER_FOLDER_PATH/nginx/conf/default.conf_template $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
  sed -i "s/#SITE_NAME#/$SITE_NAME/g" $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
  echo -e "\e[32m    Done \e[39m\n"

  echo -e "\n\e[33mConfiguring MySQL database... \e[39m"
  PROJECT_CLEARED_NAME=${SITE_NAME%*.*} && echo $output | tr '.' '_' | tr '-' '_'

  MYSQL_DATABASE=$PROJECT_CLEARED_NAME"_db"
  sed -i "s|#MYSQL_DATABASE#|$MYSQL_DATABASE|g" $DOCKER_FOLDER_PATH/.env

  MYSQL_USER=$PROJECT_CLEARED_NAME"_user"
  sed -i "s|#MYSQL_USER#|$MYSQL_USER|g" $DOCKER_FOLDER_PATH/.env

  MYSQL_PASSWORD=$(openssl rand -base64 32)
  sed -i "s|#MYSQL_PASSWORD#|$MYSQL_PASSWORD|g" $DOCKER_FOLDER_PATH/.env

  echo -e "\033[5mCopy and save lines below!!! \033[0m\e[39m\n"

  echo -e "\e[32mDatabase server: db \e[39m"
  echo -e "\e[32mDatabase name: "$MYSQL_DATABASE" \e[39m"
  echo -e "\e[32mDatabase user: "$MYSQL_USER" \e[39m"
  echo -e "\e[32mDatabase password: "$MYSQL_PASSWORD" \e[39m"

  cd $DOCKER_FOLDER_PATH
  echo -e "\n\e[33mStarting DOCKER containers...\e[39m"
  docker-compose up -d > /dev/null 2>&1
  echo -e "\e[32m    Started\e[39m\n"
else
  echo -e "\e[33mBitrixDock is installed. Clear all and remove all containers to reinstall\e[39m"
fi