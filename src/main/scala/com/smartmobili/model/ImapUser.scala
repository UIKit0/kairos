/*
 *  ImapUser
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
package com.smartmobili.model

import net.liftweb.mapper._
import net.liftweb.util.Helpers

class ImapUser extends LongKeyedMapper[ImapUser] with CreatedUpdated with IdPK with OneToMany[Long, ImapUser] {
	def getSingleton = ImapUser
	object email extends MappedEmail(this, 200)
	object password extends MappedPassword(this)
	object host extends MappedString(this, 255)
	object cacheCreation extends MappedDate(this)
	object folders extends MappedOneToMany(Mailbox, Mailbox.imapUser) 
	               with Owned[Mailbox] 
	               with Cascade[Mailbox]
}

object ImapUser extends ImapUser with LongKeyedMetaMapper[ImapUser] {
	override def dbTableName = "imap_users"
} 