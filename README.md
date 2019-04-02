# LBAW's (alternative) framework

## Introduction

This README describes how to setup the "alternative" development environment for LBAW 2018/19.
The official development environment is available in [the Master branch](https://git.fe.up.pt/lbaw/template/blob/master/README.md).

The template was prepared to run on Linux 18.04LTS, but it should be fairly easy to follow and adapt for other operating systems.


* [Installing Docker and Docker Compose](#installing-docker-and-docker-compose)
* [Setting up the Development repository](#setting-up-the-development-repository)
* [Starting Docker containers](#starting-docker-containers)
* [Development phase](#development-phase)
* [Working with pgAdmin](#working-with-pgadmin)
* [Publishing the image](#publishing-your-image)
* [Laravel code structure](#laravel-code-structure)


## Installing Docker and Docker Compose

Firstly, you'll need to have __Docker__ and __Docker Compose__ installed on your PC. 
The official instructions are in [Install Docker](https://docs.docker.com/install/) and in [Install Docker Compose](https://docs.docker.com/compose/install/#install-compose):

    # install docker-ce
    sudo apt-get update
    sudo apt-get install apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    sudo apt-get update
    sudo apt-get install docker-ce
    docker run hello-world # make sure that the installation worked

    # install docker-compose
    sudo curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version # verify that you have Docker Compose installed.


## Setting up the Development repository

You should have your own repository and a copy of the demo repository in the same folder in your machine.
Then, copy the contents of the demo repository to your own.

    # Clone the group repository (lbaw18GG), if not yet available locally
    # Notice that you need to substitute GG by your group's number
    git clone https://git.fe.up.pt/lbaw/lbaw18/lbaw18GG.git

    # clone the LBAW's project skeleton
    git clone -b docker-php https://git.fe.up.pt/lbaw/template.git

    # remove the Git folder from the demo folder
    rm -rf template/.git

    # goto your repository
    cd lbaw18GG

    # make sure you are using the master branch
    git checkout master 

    # copy all the demo files
    cp -r ../template/. .

    # add the new files to your repository
    git add .
    git commit -m "Base laravel structure"
    git push origin master 

At this point you should have the project skeleton in your local machine and be ready to start working on it.
You may remove the __template__ demo directory, as it is noy needed anymore.


## Starting Docker containers

You might just go ahead and execute `docker-compose up` at the project root and, while it runs, come back and read this section.
If you're not familiar with Docker, you can may get a quick grasp of the tool by looking into its documentation [What is docker?](https://www.docker.com/what-docker).

__Docker__ is a tool that allows you to run  _containers_ (similar to virtual machines, but much lighter). 
__Docker Compose__ is a tool that helps managing multiple containers at once: start, pause, stop, and so on.


### Configured containers

```
+-------+ +-------+ +-------+ +-------+
|       | |       | |       | |       |
|  PHP  | |POSTGRE| |PG     | |MAILHOG|
|       | |SQL    | |ADMIN4 | |       |
|       | |       | |       | |       |
+-------+ +-------+ +-------+ +-------+
+-------------------------------------+
|               Docker                |
+-------------------------------------+
```

For development purposes, we have 4 configured containers. 
Which are specified under services at __docker-compose.yml__: 
1. __php__ --- were your source code lives.
2. __postgres__ --- to host the development (local) database.
3. __pgadmin__ --- to help interacting with the database.
4. __mailhog__ --- (optional) offers a "fake" e-mail server and client.

We setup the _php container_ so that the project folder is shared with the container i.e. it both lives in your PC(s) and in the container. 
So when you change your code it also changes the code inside the container. 
Ports are also opened and forwarded so that, for instance, when you go to http://localhost:8000 on your browser, the requests are redirected to the _php container_ (that is where the PHP server lives).

__To start the servers__ you simply run 
```
docker-compose up
```

This will "automagically" do everything for you. 

But it is important that you know a thing or two about what's going on under the hood: 
1. Docker-compose will read the __docker-compose.yml__ file to know what containers it needs to start up.
2. For each container, it will see what _image_ this container is based on, and fetch it (from Docker Hub). 
In the case of an image not being provided, e.g. the _php container_, a Dockerfile is used. 
This file is like a shell script with commands to create the corresponding image. 
3. Once docker-compose has the _image_ of each service, it will spin up the respective containers. 
4. Around this phase, docker-compose sets up a network among all the containers and configures the respective internal DNS entries so that from one container you can reference the remaining by its service name (e.g if from the _php container_ you `ping postgres` you'll hit the database server host). 
5. When the _php container_ is launched, the __docker_run-dev.sh__ script is run within the container (check the __Dockerfile-dev__ for more details). 
If it is the first start up, it will install the project dependencies (`composer install`) and it launches the PHP server (`php artisan serve`).

You also need to seed your database to create the schema and have some tuples with plausible values when using the demo provided (see [Development phase](#development-phase)).

__Everything should now be up and running.__ Checkout your web server at `http://localhost:8000`, the phpAdmin at `http://localhost:5050` and mailhog at `http://localhost:8025`. To stop the servers just hit __Ctrl-C__.

__To restart the containers__ just issue `docker-compose up` again. 
This docker-compose up followed by Ctrl-C is similar to turn on and off your computer, meaning that everything will be kept including the data inside the database. 
But if for some reason you want to start fresh, you can run `docker-compose down` which will destroy the containers. 
The next time you run `docker-compose up`, docker instantiates brand new containers from the previously compiled __images__. 
But you'll probably just want to reseed the database [Development phase](#development-phase). 
Either way, your code will always be kept because it lives in the host (your computer) and is shared with the container.

To verify all containers running use `docker ps -a`.
To stop all containers and remove use `docker stop $(docker ps -a -q)` and `docker rm $(docker ps -a -q)`.

__When you [publish your image](#publishing-your-image),__ the project source code will be copied to a brand new _php container_, slightly differently configured, and uploaded to Docker Hub (check the __upload_image.sh__ file). 
Latter on, the image will be pulled by an automated process to the production machine and, due to the different setup configurations, it will connect to your production database at the "dbm.fe.up.pt", using the credentials previously given to each group.


## Development phase

During the development you might need to reseed your database, or reinstall PHP dependencies i.e., interact with PHP that is running inside the container. 
Thankfully, docker provides a quick way of executing commands inside a container from the host:
```
    docker exec lbaw_php php artisan db:seed
    docker exec lbaw_php composer install
```
__Note that the container must be running__ in order that you can run exec. 
Therefore, if you pause the containers by hitting Ctrl-C, for example, it won't work. 
This means that you'll need one terminal for running the containers and another to exec commands onto the _php container_. 

You may as well have a bash inside the container by executing:
```
    docker exec -it lbaw_php bash
```
Notice that the terminal prompt changes to something like `root@acf3dbd56f07:/app# `. 


## Working with pgAdmin
 
You will be using _PostgreSQL_ to implement this project. 
If you've followed the previous sections namely  [Starting Docker Containers](#starting-docker-containers) you should now have both _PostgreSQL_ and _pgAdmin4_ running locally.
 
You can access http://localhost:5050 to access _pgAdmin4_ and manage your database.
On the first usage you will need to add the connection to the database using the following attributes:

    hostname: postgres
    username: postgres
    password: pg!lol!2019

Hostname is _postgres_ instead of _localhost_ since _docker composer_ creates an internal _DNS_ entry to facilitate connection between linked containers.


## Setting up PHP Interpreter and Debugger

During the development, to use the debugger, you may use an IDE that integrates with Docker. 
We'll use PhpStorm, as an example.

### PhpStorm

You can check the official instructions [here](https://blog.jetbrains.com/phpstorm/2016/11/docker-remote-interpreters/), but it roughly translates into:
1. File > Settings
2. Languages & Frameworks > PHP
3. On CLI Interpreter, click (...)
4. Click (+) > From Docker, Vagrant, VM, Remote ...
5. Choose __Docker__ and select __lbaw_php:latest__ as the __Image Name__
6. Hit OK, and it automatically should detect PHP 7.1.15 and Xdebug 2.6.0


## Publishing your image

You should keep your git's master branch always functional and frequently build and deploy your code. 
To do so, you will create a _docker_ image for your project and publish it at [docker hub](https://hub.docker.com/). 
LBAW's production machine will frequently pull all these images and make them available at http://lbaw18GG.lbaw-prod.fe.up.pt/. 

This demo repository is available at [http://demo.lbaw-prod.fe.up.pt/](http://demo.lbaw-prod.fe.up.pt/). 
Make sure you are inside FEUP's network or VPN.

First thing you need to do is create a [docker hub](https://hub.docker.com/) account and get your username from it. 
Once you have a username, let your docker know who you are by executing:

    docker login

Once your docker is able to communicate with the docker hub using your credentials, configure the __upload_image.sh__ script with your username and the image name. 
Example configuration:

    DOCKER_USERNAME=johndoe # Replace by your docker hub username
    IMAGE_NAME=lbaw18GG     # Replace by your lbaw group name

Afterwards, you can build and upload the docker image by executing that script from the project root:

    ./upload_image.sh

You can test the image locally by running:

    docker run -it -p 8000:80 -e DB_DATABASE="lbaw18GG" -e DB_USERNAME="lbaw18GG" -e DB_PASSWORD="PASSWORD" <DOCKER_USERNAME>/lbaw18GG

The above command exposes your application on http://localhost:8000. 
The `-e` argument creates environment variables inside the container, used to provide Laravel with the required database configurations. 

Note that during the build process we adopt the production configurations configured in the __.env_production__ file. 
**You should not add your database username and password to this file. 
The configuration will be provided as an environment variable to your container on execution time**. 
This prevents anyone else but us from running your container with your database. 

Finally, note that here should be only one image per group. 
One team member should create the image initially and add his team to the **public** repository at docker hub. 
You should provide your teacher the details for accessing your docker image, namely, the docker username and repository (*DOCKER_USERNAME/lbaw18GG*), in case it was changed.

## Laravel code structure

In Laravel, a typical web request involves the following steps and files.

### 1) Routes

The web page is processed by *Laravel*'s [routing](https://laravel.com/docs/5.8/routing) mechanism.
By default, routes are defined inside *routes/web.php*. A typical *route* looks like this:

    Route::get('cards/{id}', 'CardController@show');

This route receives a parameter *id* that is passed on to the *show* method of a controller called *CardController*.

### 2) Controllers

[Controllers](https://laravel.com/docs/5.8/controllers) group related request handling logic into a single class. 
Controllers are normally defined in the __app/Http/Controllers__ folder.

    class CardController extends Controller
    {
        public function show($id)
        {
          $card = Card::find($id);

          $this->authorize('show', $card);

          return view('pages.card', ['card' => $card]);
        }
    }

This particular controller contains a *show* method that receives an *id* from a route. 
The method searches for a card in the database, checks if the user as permission to view the card, and then returns a view.

### 3) Database and Models

To access the database, we will use the query builder capabilities of [Eloquent](https://laravel.com/docs/5.8/eloquent) but the initial database seeding will still be done using raw SQL (the script that creates the tables can be found in __resources/sql/seed.sql__).

    $card = Card::find($id);

This line tells *Eloquent* to fetch a card from the database with a certain *id* (the primary key of the table). 
The result will be an object of the class *Card* defined in __app/Card.php__. 
This class extends the *Model* class and contains information about the relation between the *card* tables and other tables:

    /* A card belongs to one user */
    public function user() {
      return $this->belongsTo('App\User');
    }

    /* A card has many items */
    public function items() {
      return $this->hasMany('App\Item');
    }

### 4) Policies

[Policies](https://laravel.com/docs/5.8/authorization#writing-policies) define which actions a user can take. 
You can find policies inside the __app/Policies__ folder. 
For example, in the __CardPolicy.php__ file, we defined a *show* method that only allows a certain user to view a card if that user is the card owner:

    public function show(User $user, Card $card)
    {
      return $user->id == $card->user_id;
    }

In this example policy method, *$user* and *$card* are models that represent their respective tables, *$id* and *$user_id* are columns from those tables that are automatically mapped into those models.

To use this policy, we just have to use the following code inside the *CardController*:

    $this->authorize('show', $card);

As you can see, there is no need to pass the current *user*.

### 5) Views

A *controller* only needs to return HTML code for it to be sent to the *browser*. However we will be using [Blade](https://laravel.com/docs/5.8/blade) templates to make this task easier:

    return view('pages.card', ['card' => $card]);

In this example, *pages.card* references a blade template that can be found at __resources/views/pages/card.blade.php__. 
The second parameter contains the data we are injecting into the template.

The first line of the template states that it extends another template:

    @extends('layouts.app')

This second template can be found at __resources/views/layouts/app.blade.php__ and is the basis of all pages in our application. Inside this template, the place where the page template is introduced is identified by the following command:

    @yield('content')

Besides the __pages__ and __layouts__ template folders, we also have a __partials__ folder where small snippets of HTML code can be saved to be reused in other pages.

### 6) CSS

The easiest way to use CSS is just to edit the CSS file found at __public/css/app.css__.

If you prefer to use [less](http://lesscss.org/), a PHP version of the less command-line tool as been added to the project. 
In this case, edit the file at __resources/assets/less/app.less__ instead and keep the following command running in a shell window so that any changes to this file can be compiled into the public CSS file:

    ./compile-assets.sh

### 7) JavaScript

To add JavaScript into your project, just edit the file found at __public/js/app.js__.

