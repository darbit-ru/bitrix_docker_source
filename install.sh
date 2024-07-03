#!/bin/sh
set -e

REPO_PATH=https://github.com/darbit-ru/bitrixdock.git
BITRIX_SETUP_PATH=http://www.1c-bitrix.ru/download/scripts/bitrixsetup.php
BITRIX_RESTORE_PATH=http://www.1c-bitrix.ru/download/scripts/restore.php
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
  echo -e "\e[31m    DOCKER-COMPOSE not installed, install started \e[39m" && curl -L "https://github.com/docker/compose/releases/download/v2.28.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose && source ~/.bashrc > /dev/null 2>&1
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
    echo -e "\e[33mGenerate certificate for www.$SITE_NAME too? (Y/N): \e[39m"
    read SSL_INSTALL_WWW
    until [[ $SSL_INSTALL_WWW != "Y" || $SSL_INSTALL_WWW != "N" ]]
    do
      echo -e "\e[33mGenerate certificate for www.$SITE_NAME too (with www prefix)?: \e[39m"
      read SSL_INSTALL_WWW
    done
    echo -e "\n"
  fi

  # creating website folder
  WEBSITE_FILES_PATH=$WORK_PATH/bitrix
  echo -e "\e[33mCreating website folder \e[39m"
  mkdir -p $WEBSITE_FILES_PATH && \
  cd $WEBSITE_FILES_PATH && \
  if [[ $INSTALLATION_TYPE == "C" ]]; then wget $BITRIX_SETUP_PATH > /dev/null 2>&1; elif [[ $INSTALLATION_TYPE == "R" ]]; then wget $BITRIX_RESTORE_PATH > /dev/null 2>&1; fi && \
  cd $(dirname $WORK_PATH) && chmod -R 775 $(basename $WORK_PATH) && chown -R root:www-data $(basename $WORK_PATH)
  sed -i "s|#WEBSITE_PATH#|$WEBSITE_FILES_PATH|g" $DOCKER_FOLDER_PATH/.env
  echo -e "\e[32m    Done \e[39m\n"

  # configuring nginx file
  echo -e "\n\e[33mConfiguring NGINX conf file \e[39m"
  cp -f $DOCKER_FOLDER_PATH/nginx/conf/default.conf_template $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
  sed -i "s/#SITE_NAME#/$SITE_NAME/g" $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf && \
  echo -e "\e[32m    Done \e[39m\n"

  # configuring database credentials
  echo -e "\n\e[33mConfiguring MySQL database... \e[39m"
  PROJECT_CLEARED_FROM_DOTS=${SITE_NAME//./_}
  PROJECT_CLEARED_NAME=${PROJECT_CLEARED_FROM_DOTS//-/_}
  MYSQL_DATABASE=$PROJECT_CLEARED_NAME"_db"
  sed -i "s|#MYSQL_DATABASE#|$MYSQL_DATABASE|g" $DOCKER_FOLDER_PATH/.env
  MYSQL_USER=$PROJECT_CLEARED_NAME"_user"
  sed -i "s|#MYSQL_USER#|$MYSQL_USER|g" $DOCKER_FOLDER_PATH/.env
  MYSQL_PASSWORD=$(openssl rand -base64 32)
  sed -i "s|#MYSQL_PASSWORD#|$MYSQL_PASSWORD|g" $DOCKER_FOLDER_PATH/.env
  echo -e "\033[5mCopy and save lines below!!! \033[0m\e[39m\n"
  echo -e "\e[32mDatabase server: db \e[39m"
  echo -e "\e[32mDatabase name: bitrix \e[39m"
  echo -e "\e[32mDatabase user: bitrix \e[39m"
  echo -e "\e[32mDatabase password: "$MYSQL_PASSWORD" \e[39m"

  # starting docker containers
  cd $DOCKER_FOLDER_PATH
  echo -e "\n\e[33mStarting DOCKER containers...\e[39m"
  docker-compose up -d > /dev/null 2>&1
  echo -e "\e[32m    Started\e[39m\n"

  #
  if [[ $SSL_INSTALL_ACTION == "Y" ]]
  then
    if [[ $SSL_INSTALL_WWW == "Y" ]]
    then
      echo -e "\e[33mPrepare to sending request to generate certificate for domains - $SITE_NAME, www.$SITE_NAME (Attention! Be sure that domain www.$SITE_NAME is correctly setup in domain control panel with A or CNAME dns record) \e[39m"
    else
      echo -e "\e[33mPrepare to sending request to generate certificate for domain - $SITE_NAME \e[39m"
    fi

    echo -e "\e[33mIs domains settings correct setup in domain control panel? (Y/N): \e[39m"
    read IS_CORRECT_DOMAIN
    until [[ $IS_CORRECT_DOMAIN != "Y" || $IS_CORRECT_DOMAIN != "N" ]]
    do
        echo -e "\e[33mIs domains settings correct setup in domain control panel? (Y/N): \e[39m"
        read IS_CORRECT_DOMAIN
    done

    if [[ $SSL_INSTALL_ACTION == "Y" ]]
    then
        if [[ $SSL_INSTALL_WWW == "Y" ]]
        then
          docker exec -it darbit_docker_web_server /bin/bash -c "certbot --nginx -d $SITE_NAME -d www.$SITE_NAME"
        else
          docker exec -it darbit_docker_web_server /bin/bash -c "certbot --nginx -d $SITE_NAME"
        fi

        DOCKER_FOLDER_PATH=$WORK_PATH/bitrixdock
        mv $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf $DOCKER_FOLDER_PATH/nginx/conf/conf.d/$SITE_NAME.conf.old && \
        docker cp darbit_docker_web_server:/etc/nginx/conf.d/$SITE_NAME.conf $DOCKER_FOLDER_PATH/nginx/conf/conf.d/ && \
        docker cp darbit_docker_web_server:/etc/letsencrypt/. $DOCKER_FOLDER_PATH/nginx/letsencrypt/
    fi
    echo -e "\e[32m    Done \e[39m\n"
  fi
else
  echo -e "\e[33mBitrixDock is installed. Clear all and remove all containers to reinstall\e[39m"
fi