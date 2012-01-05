/////////////////////////////////////////////
// NEW sbt-0.11.x definitions
////////////////////////////////////////////
name := "Kairos"

version := "0.11.2"

organization := "com.smartmobili"

scalaVersion := "2.9.1"

seq(webSettings :_*)

// If using JRebel uncomment next line
//jettyScanDirs := Nil

libraryDependencies ++= {
  val liftVersion = "2.4-M4" // Put the current/latest lift version here
  Seq(
    "net.liftweb" %% "lift-webkit" % liftVersion % "compile->default",
    "net.liftweb" %% "lift-mapper" % liftVersion % "compile->default",
    "net.liftweb" %% "lift-testkit" % liftVersion % "compile->default"
    )
}



// when using the sbt web app plugin 0.2.4+, use "container" instead of "jetty" for the context
// Customize any further dependencies as desired
libraryDependencies ++= Seq(
  //"org.eclipse.jetty" % "jetty-webapp" % "8.0.4.v20111024" % "container", // For Jetty 8
  //"org.eclipse.jetty" % "jetty-webapp" % "7.3.0.v20110203" % "container", // For Jetty 7
  "org.mortbay.jetty" % "jetty" % "6.1.22" % "container", // For Jetty 6, add scope test to make jetty avl. for tests
  "org.scala-tools.testing" % "specs_2.9.1" % "1.6.9" % "test", // For specs.org tests
  "junit" % "junit" % "4.5" % "test->default", // For JUnit 4 testing
  "javax.servlet" % "servlet-api" % "2.5" % "provided->default",
  "com.h2database" % "h2" % "1.3.146", // In-process database, useful for development systems
  "ch.qos.logback" % "logback-classic" % "0.9.26" % "compile->default" // Logging
)

