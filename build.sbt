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

// set the main Scala source directory to be <base>/src
//scalaSource in Compile <<= baseDirectory(_ / "src")

// set the Scala test source directory to be <base>/test
//scalaSource in Test <<= baseDirectory(_ / "test")



//override def libraryDependencies = Set(
//    "net.liftweb" %% "lift-webkit" % liftVersion % "compile->default",
//    "net.liftweb" %% "lift-testkit" % liftVersion % "compile->default",
//    "org.mortbay.jetty" % "jetty" % "6.1.22" % "test->default",
//    "ch.qos.logback" % "logback-classic" % "0.9.26",
//    "junit" % "junit" % "4.5" % "test->default",
//    "org.scala-tools.testing" %% "specs" % "1.6.9-SNAPSHOT" % "test->default"
//  ) ++ super.libraryDependencies

// add compile dependencies on some dispatch modules
libraryDependencies ++= Seq(
    
)

