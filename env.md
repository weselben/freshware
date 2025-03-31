# Environment Variables

This file documents the environment variables used by the application. Sensitive information, such as passwords and secret keys, should be replaced with appropriate values.

### MYSQL_USER

- **Value**: `shopware`
- **Description**: The username for the MySQL database connection.

### MYSQL_PWD

- **Value**: `your_mysql_password`
- **Description**: The password for the MySQL database user.

### APP_SECRET

- **Value**: `your_app_secret`
- **Description**: A secret key used by the application for security-related operations, such as generating tokens or encrypting data.

### INSTANCE_ID

- **Value**: `your_instance_id`
- **Description**: A unique identifier for this instance of the application.

### BLUE_GREEN_DEPLOYMENT

- **Value**: `0`
- **Description**: Flag to enable or disable blue-green deployment. Set to `1` to enable, `0` to disable.

### LOCK_DSN

- **Value**: `flock`
- **Description**: The DSN (Data Source Name) for the lock store, used for concurrency control. `flock` typically refers to file-based locking.

### OPENSEARCH_URL

- **Value**: `http://opensearch:9200`
- **Description**: The URL for the OpenSearch instance, used for search functionality.

### SHOPWARE_ES_ENABLED

- **Value**: `0`
- **Description**: Flag to enable or disable ElasticSearch/OpenSearch integration in Shopware. Set to `1` to enable, `0` to disable.

### SHOPWARE_ES_INDEXING_ENABLED

- **Value**: `0`
- **Description**: Flag to enable or disable indexing for ElasticSearch/OpenSearch. Set to `1` to enable, `0` to disable.

### SHOPWARE_ES_INDEX_PREFIX

- **Value**: `sw`
- **Description**: The prefix used for index names in ElasticSearch/OpenSearch.

### SHOPWARE_ES_THROW_EXCEPTION

- **Value**: `1`
- **Description**: Flag to control whether exceptions are thrown on ElasticSearch/OpenSearch errors. Set to `1` to throw exceptions, `0` to handle errors silently.

### STOREFRONT_PROXY_URL

- **Value**: `http://localhost`
- **Description**: The URL for the proxy server for the storefront.

### SHOPWARE_HTTP_CACHE_ENABLED

- **Value**: `1`
- **Description**: Flag to enable or disable HTTP caching in Shopware. Set to `1` to enable, `0` to disable.

### SHOPWARE_HTTP_DEFAULT_TTL

- **Value**: `7200`
- **Description**: The default time-to-live (in seconds) for the HTTP cache. `7200` seconds equals 2 hours.

### APP_ENV

- **Value**: `prod`
- **Description**: The application environment. Common values are `prod` for production and `dev` for development.

### APP_URL

- **Value**: `http://localhost`
- **Description**: The base URL of the application. Update this to match your deployment domain.

### DATABASE_URL

- **Value**: `mysql://shopware:your_mysql_password@mariadb:3306/shopware?charset=utf8mb4`
- **Description**: The connection string for the database. Replace `your_mysql_password` with the actual password.

### MAILER_DSN

- **Value**: `smtp://your_email:your_email_password@smtp.office365.com:587?encryption=tls`
- **Description**: The DSN for the mailer, specifying how to send emails. Replace `your_email` and `your_email_password` with the actual email credentials.

### MARIADB_ROOT_PASSWORD

- **Value**: `your_mariadb_root_password`
- **Description**: The root password for the MariaDB server.

### MARIADB_DATABASE

- **Value**: `shopware`
- **Description**: The name of the database to use.

### MARIADB_USER

- **Value**: `shopware`
- **Description**: The username for the MariaDB database.

### MARIADB_PASSWORD

- **Value**: `your_mariadb_password`
- **Description**: The password for the MariaDB database user.

### COMPOSER_HOME

- **Value**: `/var/www/freshware`
- **Description**: The home directory for Composer, a dependency manager for PHP.

### COMPOSER_ROOT_VERSION

- **Value**: `2`
- **Description**: The version of the root package for Composer.

### SW_CURRENCY

- **Value**: `EUR`
- **Description**: The default currency for the shop (e.g., `EUR` for Euro).

### SW_TASKS_ENABLED

- **Value**: `0`
- **Description**: Flag to enable or disable certain tasks or jobs in Shopware. Set to `1` to enable, `0` to disable.

### SHOP_DOMAIN

- **Value**: `localhost`
- **Description**: The domain name of the shop. Update this to match your deployment domain.

### MARIADB_HOST

- **Value**: `mariadb`
- **Description**: The hostname of the MariaDB server.

### JWT_PRIVATE_KEY

- **Value**: `your_jwt_private_key`
- **Description**: The private key for JSON Web Token (JWT) authentication, in PEM format, base64 encoded.

### JWT_PUBLIC_KEY

- **Value**: `your_jwt_public_key`
- **Description**: The public key for JSON Web Token (JWT) authentication, in PEM format, base64 encoded.

### REDIS_URL

- **Value**: `redis://redis:6379`
- **Description**: The URL for the Redis server, typically used for caching or session management.

### APP_URL_CHECK_DISABLED

- **Value**: `1`
- **Description**: Flag to disable checking of the `APP_URL`. Set to `1` to disable, `0` to enable.

### SHOPWARE_CACHE_ID

- **Value**: `fresh`
- **Description**: An identifier for the cache, used to invalidate the cache when necessary.

### TRUSTED_PROXIES

- **Value**: `0.0.0.0/16`
- **Description**: The trusted proxies for the application, specified in CIDR notation.

### COMPOSER_JSON_REMOTE_URL

- **Value**: `https://freshware-default-composer.memoryhost.workers.dev`
- **Description**: A URL pointing to a remote `composer.json` file for dependency management.


```dotenv
# Example .env file

# Database configuration
MYSQL_USER=shopware
MYSQL_PWD=your_mysql_password
DATABASE_URL=mysql://shopware:your_mysql_password@mariadb:3306/shopware?charset=utf8mb4

# Application secrets and identifiers
APP_SECRET=your_app_secret
INSTANCE_ID=your_instance_id

# Deployment and concurrency settings
BLUE_GREEN_DEPLOYMENT=0
LOCK_DSN=flock

# Search and indexing configuration
OPENSEARCH_URL=http://opensearch:9200
SHOPWARE_ES_ENABLED=0
SHOPWARE_ES_INDEXING_ENABLED=0
SHOPWARE_ES_INDEX_PREFIX=sw
SHOPWARE_ES_THROW_EXCEPTION=1

# Storefront and caching settings
STOREFRONT_PROXY_URL=http://localhost
SHOPWARE_HTTP_CACHE_ENABLED=1
SHOPWARE_HTTP_DEFAULT_TTL=7200

# Application environment and URL
APP_ENV=prod
APP_URL=http://localhost
APP_URL_CHECK_DISABLED=1

# Mailer configuration
MAILER_DSN=smtp://your_email:your_email_password@smtp.office365.com:587?encryption=tls

# MariaDB configuration
MARIADB_ROOT_PASSWORD=your_mariadb_root_password
MARIADB_DATABASE=shopware
MARIADB_USER=shopware
MARIADB_PASSWORD=your_mariadb_password
MARIADB_HOST=mariadb

# Composer configuration
COMPOSER_HOME=/var/www/freshware
COMPOSER_ROOT_VERSION=2
COMPOSER_JSON_REMOTE_URL=https://freshware-default-composer.memoryhost.workers.dev

# Shopware specific settings
SW_CURRENCY=EUR
SW_TASKS_ENABLED=0
SHOP_DOMAIN=localhost
SHOPWARE_CACHE_ID=fresh

# JWT keys for authentication
JWT_PRIVATE_KEY=your_jwt_private_key
JWT_PUBLIC_KEY=your_jwt_public_key

# Redis configuration
REDIS_URL=redis://redis:6379

# Proxy settings
TRUSTED_PROXIES=0.0.0.0/16
```