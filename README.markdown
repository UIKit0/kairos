Kairos Project
==============

![Kairos-Webmail](https://github.com/smartmobili/kairos/raw/java/misc/kairos_screenshot.png)


A demo is running here : [http://bifrost.smartmobili.com/kairos-1.0/](http://bifrost.smartmobili.com/kairos-1.0/)


Getting Started
---------------
The following prerequisites are necessary to get started :

* Java JDK  
* Cappuccino >= 0.9.5 (Optional)  
* mongodb >= 2.0.2  

1) Java 
On Macos java is installed by default so normally you have nothing to do except launching at least once a java application(you can for instance enter java -version inside a terminal)
On linux you can use your package manager to install the latest java version, just make sure you are
using the Sun/Oracle version and not the OpenJDk because the code is using some imap classes only
available in Sun SDK.

2) Cappuccino  
In a temporary folder please enter the following command:  
  
`curl https://raw.github.com/cappuccino/cappuccino/v0.9.5/bootstrap.sh >/tmp/cb.sh`  
`sudo bash /tmp/cb.sh`  

and follow the installer instructions.  
At the end of install, please add cappuccino to your shell path :  
    export PATH=/usr/local/narwhal/bin:${PATH}  

3) MongoDB
Download, install and run mongodb with default configuration. Check that it is working (run "mongo" client from console and ensure that it successfully can connect to localhost).
No need to create and pre-fill DB collections and etc, later when you will start and use server part of kairos, it will create all needed data automatically on-demand in mongo DB. So default configuration of mongodb is enough to begin.


So once you have installed all the tools above a typical shell configuration(macos) looks like this:  

    # Java 
    export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
    # export PATH="${JAVA_HOME}/bin:${PATH}" # On MacOS java is already in path so no need to add it

    # Cappuccino  
    export PATH=/usr/local/narwhal/bin:$PATH  

    # MongoDB
    export PATH=/usr/local/mongodb-osx-x86_64-2.0.2/bin:$PATH  

    #IntelliJ  
    export PATH=/usr/local/idea-IC-111.69/bin:${PATH}  

Getting Sources  
---------------  
  
`$> git clone git@github.com:smartmobili/kairos.git`  
`$> cd kairos`  

Quick Launch
---------------

`$> mongod --dbpath data/db`  
`$> ./gradlew jettyRun`  

Now open your browser and go to http://localhost:8080  

Et voila! You should see the current status of the project.  

Development
---------------

The kairos project is splitted in two parts :

- a backend using java
- a frontend using cappuccino

For the backend we use eclipse as a preferred ide and gradle is able to generate an eclipse project through a plugin (see build.gradle)

`$> ./gradlew eclipse`

Now start eclipse and import the kairos project into your workspace (File->Import...->Existing projects into Workspace)
Right-click on src/test/java and choose Debug As->Java application, normally a jetty webserver should get launched and you can go
to http://localhost:8080.











