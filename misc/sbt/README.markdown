Getting Started
===============
This project assumes you have installed a local Cappuccino distribution. It also uses the [simple-build-tool](http://code.google.com/p/simple-build-tool/) version 0.7 [download](http://simple-build-tool.googlecode.com/files/sbt-launch-0.7.7.jar), in short `sbt`, to build and manage the Lift project. This project will eventually upgrade to version 0.10 once Lift project integration is completely stable.

Quick Install
-------------
Kairos use the Simple Build Tool to manage the Scala/Lift/Cardano project. This guide assume you are located in the `kairos` root directory (this Readme file is in `kairos/misc/sbt`).

Install the Cappuccino frameworks:

`capp gen -f --force src/main/webapp/`

To install Cardano framework untar `kairos/misc/cardano/cardano.tar.gz` into a temporary folder, here `/Development/tmp`. Then, copy Cardano and Debug folders inside the Frameworks located under webapp:

`mkdir -p /Development/tmp/`

`tar -xvzf misc/cardano/cardano.tar.gz --directory=/Development/tmp/`

Copy the client side part to Frameworks

`cp -R /Development/tmp/cardano/Cardano src/main/webapp/Frameworks/`

`cp -R /Development/tmp/cardano/Debug/Cardano/ src/main/webapp/Frameworks/Debug`

Copy the server side part of the framework, i.e., the `jar` file named `cardano-core_sss-xxx.jar` (where `sss` refers to the Scala version and `xxx` to this framework version) into the `lib` folder –here we create it as it does not exist:

`mkdir lib`
 
`cp /Development/tmp/cardano/cardano-core_2.8.1-0.1.2.jar lib`

Launch the simple-build-tool by typing sbt, and then update the project

`sbt`

`update`

Start the app container by typing

`jetty-run`

Point your browser to `http://localhost:8080/capp_debug`.