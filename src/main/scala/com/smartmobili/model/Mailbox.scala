/*
 *  Mailbox
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
package com.smartmobili.model

import net.liftweb.mapper._
import net.liftweb.util.Helpers

class Mailbox extends LongKeyedMapper[Mailbox] with CreatedUpdated with IdPK with OneToMany[Long, Mailbox]{
	def getSingleton = Mailbox
	object folderLabel extends MappedString(this, 255)
	object messageCount extends MappedInt(this)
	object messageUnread extends MappedInt(this)
	object imapUser extends LongMappedMapper(this, ImapUser)
	object messages extends MappedOneToMany(Message, Message.folder)
                	with Owned[Message] 
                  with Cascade[Message]  
}

object Mailbox extends Mailbox with LongKeyedMetaMapper[Mailbox] {
	override def dbTableName = "mailboxes"
}