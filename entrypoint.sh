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
echo "** Shopware Version: 6.6.9.0"
echo "** PHP-FPM Version: ${PHP_VERSION}"
echo "** Version: 0.0.1"
echo "** Copyright 2025 MG Wesel GmbH"
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
  curl -fsSL "$REMOTE_URL" -o composer.json

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

FILE=/freshware/freshware.lock

#-------------------------------------------------------------
#  First-time Installation Block
#-------------------------------------------------------------
if [ ! -f "$FILE" ]; then
    if [ -f "$FILE" ]; then
        echo "Already installed! Script will just start Shopware"
    else
        echo "-----------------------------------------------------------"

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
        php bin/console system:generate-jwt-secret --force

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

#-------------------------------------------------------------
#  Subsequent Startup Block (Installation Already Completed)
#-------------------------------------------------------------
else
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

    update_composer_json
    composer install -n
    php bin/console dotenv:dump .env
    php bin/console assets:install
    php bin/console database:migrate --all
    php bin/console cache:clear
    php bin/console system:check -c pre_rollout

    # Remove JWT keys from docker.yaml
    remove_jwt_keys_from_docker_yaml

    echo ""
    echo "WOHOOO, mg-wesel-gmbh/freshware IS READY :) - let's get started"
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

    php-fpm -F &
    PID=$!

    # Wait for php-fpm process to exit
    wait $PID

    echo ""
    echo "FRESHWARE: PHP-FPM process has exited. Shutting down..."
    echo "-----------------------------------------------------"

    php bin/console cart:migrate

    echo "Goodbye!"
    echo "-----------------------------------------------------"
fi
