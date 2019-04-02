#!/bin/bash
set -e

env >> /var/www/.env
php-fpm7.2 -D
nginx -g "daemon off;"
