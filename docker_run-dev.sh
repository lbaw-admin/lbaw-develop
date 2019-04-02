#!/bin/bash

if [ ! -f /.inited ]; then
    echo "Since it is the first launch, we will install project dependencies and seed the database."
    composer install
    touch /.inited
fi

echo "Launching PHP server..."
php artisan serve --host=0.0.0.0
