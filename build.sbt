/////////////////////////////////////////////
// OLD sbt-0.7.7 build.properties to port
////////////////////////////////////////////

// -- project/build.properties --
// #Project properties
// #Sat Jul 23 19:53:19 CEST 2011
// project.organization=com.smartmobili
// project.name=Kairos
// sbt.version=0.7.7
// project.version=0.1.3
// build.scala.versions=2.9.1 2.8.1
// project.initialize=false

/////////////////////////////////////////////
// OLD sbt-0.7.7 Project.scala to port
////////////////////////////////////////////
// import sbt._
// import de.element34.sbteclipsify._
// 
// class CardanoProject(info: ProjectInfo) extends DefaultWebProject(info) with Eclipsify {
// 
//   val scalatoolsRelease = "Scala Tools Snapshot" at
//   "http://scala-tools.org/repo-releases/"
// 
//   val scalatoolsSnapshot = ScalaToolsSnapshots
// 
//   val liftVersion = "2.4-M4"
//   val cappuccinoVersion = "0.9"
// 
// 	// IMAP idle (not used; evaluation purposes)
// 	lazy val liftModulesRelease = "liftmodules repository" at "http://repository-liftmodules.forge.cloudbees.com/release/"
  
// 	// If you're using JRebel for Lift development, uncomment
//   // this line
//   override def scanDirectories = Nil

// 	// H2 Database for IMAP caching prototyping
// 	val h2 = "com.h2database" % "h2" % "1.3.146"
// 	val mapper = "net.liftweb" %% "lift-mapper" % liftVersion
// 
//   override def libraryDependencies = Set(
//     "net.liftweb" %% "lift-webkit" % liftVersion % "compile->default",
//     "net.liftweb" %% "lift-testkit" % liftVersion % "compile->default",
// 		//"net.liftmodules" %% "imap-idle" % (liftVersion+"-0.9"),
// 		//"org.hnlab" %% "cardano-core" % "0.1.2",
//     "org.mortbay.jetty" % "jetty" % "6.1.22" % "test->default",
//     "ch.qos.logback" % "logback-classic" % "0.9.26",
//     "junit" % "junit" % "4.5" % "test->default",
//     "org.scala-tools.testing" %% "specs" % "1.6.9-SNAPSHOT" % "test->default"
//   ) ++ super.libraryDependencies
// }


/////////////////////////////////////////////
// NEW sbt-0.11.x definitions
////////////////////////////////////////////
name := "Kairos"

version := "0.11.2"

organization := "com.smartmobili"

// set the Scala version used for the project
scalaVersion := "2.9.1"

seq(webSettings :_*)

libraryDependencies ++= {
  val liftVersion = "2.4-M4" // Put the current/latest lift version here
  Seq(
    "net.liftweb" %% "lift-webkit" % liftVersion % "compile->default",
    "net.liftweb" %% "lift-testkit" % liftVersion % "compile->default"
    )
}

// when using the sbt web app plugin 0.2.4+, use "container" instead of "jetty" for the context
// Customize any further dependencies as desired
libraryDependencies ++= Seq(
  //"org.eclipse.jetty" % "jetty-webapp" % "8.0.4.v20111024" % "container", // For Jetty 8
  //"org.eclipse.jetty" % "jetty-webapp" % "7.3.0.v20110203" % "container", // For Jetty 7
  "org.mortbay.jetty" % "jetty" % "6.1.22" % "container", // For Jetty 6, add scope test to make jetty avl. for tests
  "org.scala-tools.testing" % "specs_2.9.0" % "1.6.8" % "test", // For specs.org tests
  "junit" % "junit" % "4.5" % "test->default", // For JUnit 4 testing
  "javax.servlet" % "servlet-api" % "2.5" % "provided->default",
  "com.h2database" % "h2" % "1.2.138", // In-process database, useful for development systems
  "ch.qos.logback" % "logback-classic" % "0.9.26" % "compile->default" // Logging
)

