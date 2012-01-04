Project Kairos
==============

Getting Started
---------------
The following prerequisites are necessary to get started :

* Java JDK
* Scala >= 2.9.1
* Sbt(Scala Build Tool) >= 0.11.x
* Cappuccino >= 0.9.5
* IntelliJ IDEA (Optional)

1) Java 
On Macos java is installed by default so normally you have nothing to do except launching at least once a java application(you can for instance enter java -version inside a terminal)
On linux you can use your package manager to install the latest java version, just make sure you are
using the Sun/Oracle version and not the OpenJDk because the code is using some imap classes only
available in Sun SDK.

2) Scala 2.9.x
You can download the latest scala version here : http://www.scala-lang.org/downloads/distrib/files/scala-2.9.1.final.tgz.  
Once downloaded and unarchived you can copy it on the location of your choice(ex /usr/local/scala-2.9.1) and add it to your shell path.

3) Sbt 0.11.2
You can download sbt 0.11.2 here : http://typesafe.artifactoryonline.com/typesafe/ivy-releases/org.scala-tools.sbt/sbt-launch/0.11.2/sbt-launch.jar  
Please DO NOT USE older version of sbt because build scripts are not compatible between some versions. 
Once the jar is downloaded, please go to the install directory and enter the following commands :  
`sudo mv sbt-launch.jar sbt-launch-0.11.2.jar`  
`sudo ln -s sbt-launch-0.11.2.jar sbt-launch.jar`  

Now we need to create the script that will call our downloaded jar through the java interpreter:  

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

Another option is to use JRebel.  
TODO : write a doc for this option and explain the pros and cons - http://vimeo.com/27162278

Once done you should get the following tree directory :  

    vincent@vincent-EP35-DS3R:/usr/local/sbt$ ls -la  
    total 944  
    drwxrwxr-x  2 root    admin     4096 2011-12-18 12:18 ./  
    drwxr-xr-x 15 root    root      4096 2011-12-18 10:58 ../  
    -rwxrwxr-x  1 vincent vincent     96 2011-12-11 13:16 sbt*  
    -rw-r--r--  1 root    admin  1041753 2011-12-10 15:31 sbt-launch-0.11.2.jar  
    lrwxrwxrwx  1 root    admin       20 2011-12-10 15:32 sbt-launch.jar -> sbt-launch-0.11.2.jar  

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



So once you have installed all the tools above a typical shell configuration(macos) looks like this:  

    # Java & scala  
    export JAVA_HOME="/System/Library/Frameworks/JavaVM.framework/Home"
    # export PATH="${JAVA_HOME}/bin:${PATH}" # On MacOS java is already in path so no need to add it
    export SCALA_HOME="/usr/local/scala-2.9.1"  
    export PATH="${SCALA_HOME}/bin"  

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
`$> sh ./setup.sh`  

Launching
---------------

Now we can run sbt :  

`$> sbt`  
`> clean`  
`> update`  
`> ~container:start`  

Now open your browser and go to http://localhost:8080  

Et voila! You should see the current status of the project.  

A better development environment
---------------
Ok so now we have a working environment it's time to configure a bit more to be able  
to easily debug from an ide (eclipse or idea), put some breakpoints and so on...  

1) Install Eclipse Indigo  
On linux sometimes the update repository list is empty so you need to add a new site  
Go to menu Help->Install New software...->"Available Software Sites"->Add  
Name: Indigo  
Location: http://download.eclipse.org/releases/indigo  






TO BE CONTINUED:  
Eclipse plugin for scala: Help->Install New software...->Add... and in Location enter http://download.scala-ide.org/releases-29/stable/site  
http://stackoverflow.com/questions/8104363/run-sbt-project-in-debug-mode-with-a-custom-configuration  
http://blog.morroni.com/  
http://java.dzone.com/articles/liftweb-setup-10-minutes-ide  
http://stackoverflow.com/questions/8621542/how-do-i-debug-lift-applications-in-eclipse  
http://blog.xebia.fr/2010/05/11/configurer-vos-projets-sbt-pour-eclipse-ou-intellij-idea/  

java -Dfile.encoding=UTF-8 ... -Xdebug -Xrunjdwp:transport=dt_socket,server=y,suspend=n,address=5005 -jar `dirname $0`/sbt-launch.jar "$@"  




