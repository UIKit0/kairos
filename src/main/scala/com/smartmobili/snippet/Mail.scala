/*
 *  Mail
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

package com.smartmobili.snippet

import org.hnlab.cardano.core.{Cardano, Deflector}

import net.liftweb._
import http._
import js._
import JsCmds._
import JE._
import util._
import Helpers._

import scala.xml._
import scala.collection.mutable.ListBuffer

import net.liftweb.util.Helpers._
import net.liftweb.common.{Box,Full,Empty,Failure,ParamFailure}

import javax.mail.Store

import com.smartmobili.model.{ImapUser, Mailbox=>DBMailbox, Message=>DBMessage}
import com.smartmobili.service._

object CardanoSession extends SessionVar[Box[Store]](Empty)
object CardanoCachedUser extends SessionVar[Box[ImapUser]](Empty)
object CardanoCredentials extends SessionVar[Box[SMCredentials]](Empty)

class Mail extends Cardano {
  override def render(in: NodeSeq): NodeSeq = super.render(in)
}
