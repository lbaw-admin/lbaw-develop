#!/bin/bash
set -e

env >> /var/www/.env
php-fpm -D
nginx -g "daemon off;"
