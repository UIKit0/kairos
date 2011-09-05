/*
 *  Message
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
package com.smartmobili.model

import net.liftweb.mapper._
import net.liftweb.util.Helpers

class Message extends LongKeyedMapper[Message] with CreatedUpdated with IdPK {
	def getSingleton = Message
	
	object folderLabel extends MappedString(this, 255)

	object messageId extends MappedString(this, 255)
	object from extends MappedString(this, 255)
	object subject extends MappedText(this)
	object date extends MappedDate(this)
	object to extends MappedString(this, 255)
	object cc extends MappedString(this, 255)
	object bcc extends MappedString(this, 255)
	object body extends MappedText(this)
	
	object isSeen extends MappedBoolean(this)
	
	object folder extends MappedLongForeignKey(this, Mailbox)
}

object Message extends Message with LongKeyedMetaMapper[Message] {
	override def dbTableName = "messages"
}