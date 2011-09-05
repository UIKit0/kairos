/*
 *  CardanoProject
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
import sbt._
import de.element34.sbteclipsify._

class CardanoProject(info: ProjectInfo) extends DefaultWebProject(info) with Eclipsify {

  val scalatoolsRelease = "Scala Tools Snapshot" at
  "http://scala-tools.org/repo-releases/"

  val scalatoolsSnapshot = ScalaToolsSnapshots

  val liftVersion = "2.4-M3"
  val cappuccinoVersion = "0.9"

	// IMAP idle (not used; evaluation purposes)
	lazy val liftModulesRelease = "liftmodules repository" at "http://repository-liftmodules.forge.cloudbees.com/release/"
  
	// If you're using JRebel for Lift development, uncomment
  // this line
  override def scanDirectories = Nil

	// H2 Database for IMAP caching prototyping
	val h2 = "com.h2database" % "h2" % "1.3.146"
	val mapper = "net.liftweb" %% "lift-mapper" % liftVersion

  override def libraryDependencies = Set(
    "net.liftweb" %% "lift-webkit" % liftVersion % "compile->default",
    "net.liftweb" %% "lift-testkit" % liftVersion % "compile->default",
		"net.liftmodules" %% "imap-idle" % (liftVersion+"-0.9"),
		"org.hnlab" %% "cardano-core" % "0.1.2",
    "org.mortbay.jetty" % "jetty" % "6.1.22" % "test->default",
    "ch.qos.logback" % "logback-classic" % "0.9.26",
    "junit" % "junit" % "4.5" % "test->default",
    "org.scala-tools.testing" %% "specs" % "1.6.6" % "test->default"
  ) ++ super.libraryDependencies
}