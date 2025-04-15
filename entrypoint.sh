#!/bin/bash

#-------------------------------------------------------------
#  Welcome Message & Banner
#-------------------------------------------------------------
echo ""
echo "  ______  _____   ______   _____  _    _ __          __       _____   ______ "
echo " |  ____||  __ \ |  ____| / ____|| |  | |\ \        / //\    |  __ \ |  ____|"
echo " | |__   | |__) || |__   | (___  | |__| | \ \  /\  / //  \   | |__) || |__   "
echo " |  __|  |  _  / |  __|   \___ \ |  __  |  \ \/  \/ // /\ \  |  _  / |  __|  "
echo " | |     | | \ \ | |____  ____) || |  | |   \  /\  // ____ \ | | \ \ | |____ "
echo " |_|     |_|  \_\|______||_____/ |_|  |_|    \/  \//_/    \_\|_|  \_\|______|"
echo ""
echo ""
echo "*******************************************************"
echo "** FRESHWARE"
echo "** Shopware Version: ${SW6VERSION}"
echo "** PHP-FPM Version: ${PHP_VERSION}"
echo "** Version: ${FRESHWARE_VERSION}"
echo "** Copyright 2025 weselben"
echo "*******************************************************"
echo ""
echo "launching freshware...please wait..."
echo ""

set -e

#-------------------------------------------------------------
#  Function: update_composer_json
#  Description:
#   Downloads or updates the project's composer.json file using the
#   URL specified in the environment variable "COMPOSER_JSON_REMOTE_URL".
#   If the variable is not set, it defaults to:
#     "https://freshware-default-composer.memoryhost.workers.dev"
#   The function overwrites any existing composer.json file.
#-------------------------------------------------------------
update_composer_json() {
  # Determine remote URL: use env variable if set, otherwise default
  if [ -n "$COMPOSER_JSON_REMOTE_URL" ]; then
    REMOTE_URL="$COMPOSER_JSON_REMOTE_URL"
  else
    REMOTE_URL="https://freshware-default-composer.memoryhost.workers.dev"
  fi
  # Inform what action is being taken
  if [ -f "composer.json" ]; then
    echo "Updating existing composer.json from $REMOTE_URL"
  else
    echo "Downloading composer.json from $REMOTE_URL"
  fi

  rm -rf composer.json

  # Download and overwrite composer.json
  curl -fsSL "$REMOTE_URL" -o composer.json.template

  if [ -z "$SW6VERSION" ]; then
    echo "Error: SW6VERSION environment variable is not set."
    exit 1
  else
    echo "Using SW6VERSION: $SW6VERSION"
    mv composer.json.template composer.json
  fi
  composer require shopware/core:$SW6VERSION --no-update
  composer update -n
}

# Function to remove specific lines from docker.yaml
remove_jwt_keys_from_docker_yaml() {
  local file_path="/var/www/freshware/config/packages/docker.yaml"
  if [ -f "$file_path" ]; then
    echo "Removing JWT keys from $file_path"
    sed -i '/api:/,/public_key_path:/d' "$file_path"
  else
    echo "File $file_path does not exist."
    echo "JWT Tokens need to be mounted and changed manually to work (not intended)"
    echo "Please check the docker.yaml file for JWT keys"
    echo "-----------------------------------------------------"
  fi
}

# Function to install Frosh plugins
install_frosh_plugins() {
  echo "-----------------------------------------------------"
  echo "FRESHWARE: Installing and activating Frosh plugins..."
  
  # Use the command from README.md to install all Frosh plugins
  php bin/console plugin:list | grep 'Frosh' | awk '{print $1}' | xargs -I{} php bin/console plugin:install -a {}
  
  echo "FRESHWARE: Frosh plugins installation complete"
  echo "-----------------------------------------------------"
}

FILE=/freshware/freshware.lock

envsubst < /etc/freshware/templates/php/php.ini.template > /usr/local/etc/php/conf.d/php.ini
envsubst < /etc/freshware/templates/php/php.ini.template > /usr/local/etc/php-fpm.d/php.ini

envsubst < /etc/freshware/templates/php/www.conf.template > /usr/local/etc/php-fpm.d/www.conf

#-------------------------------------------------------------
#  First-time Installation Block
#-------------------------------------------------------------
if [ "${SKIP_INSTALLATION_CHECK}" = "1" ] || [ -f "$FILE" ]; then
    # Either SKIP_INSTALLATION_CHECK is enabled or freshware.lock exists
    # This means we treat the system as already installed
    touch /var/www/html/install.lock

    CONTAINER_STARTUP_DIR=$(pwd)

    echo "FRESHWARE: Checking MariaDB connection..."
    START_TIME=$(date +%s)
    TIMEOUT=180  # Increased timeout from 120 to 180 seconds

    while true; do
      CURRENT_TIME=$(date +%s)
      ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
      if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
        echo "FRESHWARE: MariaDB connection timeout after $TIMEOUT seconds. Exiting..."
        exit 1
      fi

      if mysqladmin ping -h $MARIADB_HOST -u root --password="$MARIADB_ROOT_PASSWORD" --silent; then
        echo "FRESHWARE: MariaDB is available! Proceeding with startup..."
        break
      else
        sleep 5
        echo "FRESHWARE: MariaDB not yet available. Retrying..."
      fi
    done

    echo "-----------------------------------------------------------"
    echo "FRESHWARE: PHP: ${PHP_VERSION} ..."
    echo "-----------------------------------------------------------"

    echo "-----------------------------------------------------"
    cd /var/www/html

    #-------------------------------------------------------------
    #  Update composer.json using remote URL if needed.
    #-------------------------------------------------------------

    if [ "${WORKER_STARTUP}" = "1" ]; then
        sleep 30
        update_composer_json
        composer install -n
    elif [ "${TASKER_STARTUP}" = "1" ]; then
        sleep 60
        update_composer_json
        composer install -n
    else
        update_composer_json
        composer install -n
    fi

    php bin/console dotenv:dump .env
    php bin/console assets:install
    php bin/console database:migrate --all
    if [ "${REMOVE_CACHE_AO_AUTOLOAD_FILES}" = "1" ]; then
      if [ "${TASKER_STARTUP}" != "1" ] || [ "${TASKER_STARTUP}" != "1" ]; then
        php bin/console cache:pool:clear --all
        if ! rm -rf /var/www/freshware/var/cache/dev_*; then
          rm -rf /var/www/freshware/var/cache/prod_*
        fi
        composer dump-autoload
        php bin/console cache:clear
        php bin/console cache:warmup
      fi
    fi
    php bin/console system:check -c pre_rollout

    # Remove JWT keys from docker.yaml
    remove_jwt_keys_from_docker_yaml

    # Check if Frosh plugins installation is enabled
    if [ "${INSTALL_FROSH_PLUGINS}" = "1" ]; then
      if [ "${WORKER_STARTUP}" = "0" ] && [ "${TASKER_STARTUP}" = "0" ];then
        install_frosh_plugins
      fi
    fi

    echo ""
    echo "WOHOOO, weselben/freshware IS READY :) - let's get started"
    echo "-----------------------------------------------------"
    echo "PHP: $(php -v | grep cli)"
    echo "----------------------"
    echo "SHOP URL: http://${SHOP_DOMAIN}"
    echo "ADMIN URL: http://${SHOP_DOMAIN}/admin"
    echo "----------------------"
    echo "or with SSL: "
    echo "----------------------"
    echo "SHOP URL: https://${SHOP_DOMAIN}"
    echo "ADMIN URL: https://${SHOP_DOMAIN}/admin"
    echo "-----------------------------------------------------"

    echo ""
    echo "What's new in this version? see the changelog for further details"
    echo "https://www.shopware.com/de/changelog/"
    echo ""

    echo "-----------------------------------------------------------"
    echo "FRESHWARE - now running ..."

    if [ "${WORKER_STARTUP}" = "1" ]; then
        echo "FRESHWARE: Starting worker..."
        php bin/console messenger:consume async failed low_priority --memory-limit=${WORKER_MEMORY_LIMIT} --time-limit=${WORKER_TIME_LIMIT}
    elif [ "${TASKER_STARTUP}" = "1" ]; then
        echo "FRESHWARE: Starting task-schedule..."
        php bin/console scheduled-task:register
        php bin/console scheduled-task:run --memory-limit=${TASKER_MEMORY_LIMIT} --time-limit=${TASKER_TIME_LIMIT}
    else
        exec "$@"
        PID=$!
        wait $PID
        if [ $? -ne 0 ]; then
            echo "FRESHWARE: PHP-FPM process has exited with error. Shutting down..."
            exit 1
        fi
        echo ""
        echo "FRESHWARE: PHP-FPM process has exited. Shutting down..."
        echo "-----------------------------------------------------"

        php bin/console cart:migrate

    fi

    echo "Goodbye!"
    echo "-----------------------------------------------------"
else
    if [ -f "$FILE" ]; then
        echo "Already installed! Script will just start Shopware"
    else
        echo "-----------------------------------------------------------"

        # Add wait period for installation boot if ENABLE_ADMIN_WORKER is enabled
        if [ "${ENABLE_ADMIN_WORKER}" = "true" ] || [ "${WORKER_STARTUP}" = "1" ] || [ "${TASKER_STARTUP}" = "1" ]; then
            echo "FRESHWARE: WORKER SETUP OR STARTUP is enabled. Waiting 60 seconds for system setup..."
            echo "FRESHWARE: Ensures that no unnecessary processes are started during installation, which could lead to issues on Startup."
            sleep 60
            if [ "${WORKER_STARTUP}" = "1" ] || [ "${TASKER_STARTUP}" = "1" ]; then
              exit 0
            fi
        else
            echo "FRESHWARE: ENABLE_ADMIN_WORKER is not set. Proceeding with normal installation..."
        fi

        echo "FRESHWARE: Checking MariaDB connection..."
        START_TIME=$(date +%s)
        TIMEOUT=180  # Increased timeout from 120 to 180 seconds for higher load

        while true; do
          CURRENT_TIME=$(date +%s)
          ELAPSED_TIME=$((CURRENT_TIME - START_TIME))
          if [ $ELAPSED_TIME -ge $TIMEOUT ]; then
            echo "FRESHWARE: MariaDB connection timeout after $TIMEOUT seconds. Exiting..."
            exit 1
          fi

          if mysqladmin ping -h $MARIADB_HOST -u root --password="$MARIADB_ROOT_PASSWORD" --silent; then
            echo "FRESHWARE: MariaDB is available! Proceeding with startup..."
            break
          else
            sleep 5
            echo "FRESHWARE: MariaDB not yet available. Retrying..."
          fi
        done

        echo "-----------------------------------------------------------"

        echo "FRESHWARE: Installing Shopware Basic..."
        cd /var/www/html

        #-------------------------------------------------------------
        #  Update composer.json using remote URL if needed.
        #  This function checks the environment variable "COMPOSER_JSON_REMOTE_URL"
        #  and downloads the finetuned composer.json accordingly.
        #-------------------------------------------------------------
        update_composer_json

        # Perform installation steps
        php bin/console system:install --force
        php bin/console assets:install

        # Use SHOP_DOMAIN environment variable for storefront creation
        if [ -n "$SHOP_DOMAIN" ]; then
            php bin/console sales-channel:create:storefront --url="http://$SHOP_DOMAIN"
            php bin/console sales-channel:create:storefront --url="https://$SHOP_DOMAIN"
        else
            echo "Error: SHOP_DOMAIN environment variable not set."
            php bin/console sales-channel:create:storefront --url=http://localhost
            php bin/console sales-channel:create:storefront --url=https://localhost
        fi

        # Use environment variables for admin credentials
        if [ -n "$INSTALL_ADMIN_USERNAME" ] && [ -n "$INSTALL_ADMIN_PASSWORD" ]; then
            php bin/console user:create -a -p "$INSTALL_ADMIN_PASSWORD" "$INSTALL_ADMIN_USERNAME"
        else
            echo "Error: INSTALL_ADMIN_USERNAME or INSTALL_ADMIN_PASSWORD environment variables not set."
            php bin/console user:create -a -p "shopware" "admin"
        fi

        # Create the installed.lock file to mark the completion of installation
        touch "$FILE"
        touch "/var/www/html/install.lock"
    fi
fi
