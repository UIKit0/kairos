Project Kairos
==============

Getting Started
---------------
The following prerequisites are necessary to get started :

* Java JDK
* Scala >= 2.9.1
* Sbt(Scala Build Tool) 0.7.7 : http://code.google.com/p/simple-build-tool/downloads/detail?name=sbt-launch-0.7.7.jar&can=2&q=
* Cappuccino
* IntelliJ IDEA (Optional)

1) Java 
On Macos java is installed by default so normally you have nothing to do except launching at least once a java application(you can for instance enter java -version inside a terminal)
On linux you can use your package manager to install the latest java version, just make sure you are
using the Sun/Oracle version and not the OpenJDk because the code is using some imap classes only
available in proprietary version.

2) Scala 2.9.x
You can download the latest scala version here : http://www.scala-lang.org/downloads/distrib/files/scala-2.9.1.final.tgz.  
Once downloaded and unarchived you can copy it on the location of your choice(ex /usr/local/scala-2.9.1) and add it to your shell path.

3) Sbt 0.7.7
You can download sbt 0.7.7 here : http://code.google.com/p/simple-build-tool/downloads/detail?name=sbt-launch-0.7.7.jar&can=2&q=  
Please DO NOT USE a newer version of sbt because build scripts are not compatible for the moment !  
Once the jar is downloaded, please go to the install directory and enter the following commands :  
sudo ln -s sbt-launch-0.7.7.jar sbt-launch.jar  

`sudo touch sbt`  
`sudo chmod +x sbt`  

Open your favorite text editor and add the following command to sbt file :  

    java -Dfile.encoding=UTF-8 -XX:+CMSClassUnloadingEnabled  -XX:MaxPermSize=512m -Xmx1512M  -jar `dirname $0`/sbt-launch.jar "$@"

The `+CMSClassUnloadingEnabled` command is used to resolve a problem of memory when restarting sbt too many times.  
Here is the explanation from the lift mailing list (sbt ~jetty-run leaks) :

"By default the JVM does not unload classes once they are loaded and loaded 
classes are kept in the "perm gen" (permanent generation) heap space.  This 
is mostly what you want because the cost of loading and JITing classes is 
high.  But during development or if you've got a container that is changing 
what apps it runs, it's best to allow unloading of the classes and also to 
set perm gen to a reasonably big number. "

Another better option is to use JRebel.  
TODO : write a doc for this option - http://vimeo.com/27162278

Once done you should get the following tree directory :  

    vincent@vincent-EP35-DS3R:/usr/local/sbt$ ls -la  
    total 944  
    drwxrwxr-x  2 root    admin     4096 2011-12-18 12:18 ./  
    drwxr-xr-x 15 root    root      4096 2011-12-18 10:58 ../  
    -rwxrwxr-x  1 vincent vincent     96 2011-12-11 13:16 sbt*  
    -rw-r--r--  1 root    admin   952175 2011-12-10 15:31 sbt-launch-0.7.7.jar  
    lrwxrwxrwx  1 root    admin       20 2011-12-10 15:32 sbt-launch.jar -> sbt-launch-0.7.7.jar  

Now you need to update your shell environment and add sbt to the path  
    # simple build tool (sbt)  
    export PATH=/usr/local/sbt:${PATH}  

4) Cappuccino  
In a temporary folder please enter the following command:  
  
`curl https://raw.github.com/cappuccino/cappuccino/v0.9.5/bootstrap.sh >/tmp/cb.sh`  
`sudo bash /tmp/cb.sh`  

and follow the installer instructions.  
At the end of install, please add cappuccino to your shell path :  
    export PATH=/usr/local/narwhal/bin:${PATH}  

5) IntelliJ Idea  
Download and install.  
Add install location to your path :  
    #IntelliJ  
    export PATH=/usr/local/idea-IC-111.69/bin:${PATH}  



So once you have installed all the tools above 
a typical shell configuration (on ubuntu for instance) looks like this:

    # Java & scala  
    # Note: (On MacOS JAVA_HOME is not necessary and should be commented)
	export JAVA_HOME="/usr/lib/jvm/java-7-oracle"  # comment this line if running macos
    export SCALA_HOME="/usr/lib/jvm/scala-2.9.1"  
    export PATH="${SCALA_HOME}/bin:${JAVA_HOME}/bin:${PATH}"  

    # simple build tool (sbt)  
    export PATH=/usr/local/sbt:${PATH}  

    # Cappuccino  
    export PATH=/usr/local/narwhal/bin:$PATH  

    #IntelliJ  
    export PATH=/usr/local/idea-IC-111.69/bin:${PATH}  

Getting Sources  
---------------  
  
`$> git clone git@github.com:smartmobili/kairos.git`  
`$> cd kairos`  
`$> ln -s project-sbt-0.7 project`  
`$> tar xvf misc/cardano/cardano.tar.gz  -C misc/cardano/`  
`$> capp gen -f src/main/webapp`  
`$> cp -R misc/cardano/cardano/* src/main/webapp/Frameworks/`  
`$> cp -R misc/cardano/cardano/Debug/* src/main/webapp/Frameworks/Debug/`  



Launching
---------------

Now we can run sbt :  

`$> sbt`  
`> clean`  
`> update`  
`> jetty-run`  

Now open your browser and go to http://localhost:8080  

Et voila! You should see the current status of the project.  


