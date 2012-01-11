/*
 *  ImapService, 
 *  SMMailUtil, SMCredentials, 
 *  SMMailbox, SMMailHeader, SMMailContent
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Contains a snippet from Markh Needham
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
package com.smartmobili.service

import javax.mail._
import javax.mail.internet._
import javax.mail.search._
import com.sun.mail.imap._

import scala.collection.JavaConverters._

import java.io._
import java.util.Properties
import javax.activation.DataHandler

import net.liftweb.actor._
import net.liftweb.util._
import net.liftweb.common._

import net.liftweb.mapper.{By, Like}

import com.smartmobili.snippet._
import org.hnlab.cardano.core.{HNUtil, CPDate}
import com.smartmobili.model.{ImapUser, Mailbox=>DBMailbox, Message=>DBMessage}
//import net.liftmodules.imapidle.EmailUtils

case class ImapService() extends Logger {
  val log = Logger(classOf[ImapService])
  log.info("Creating ImapService at %s".format(new java.util.Date))
    
  private val imapConnectionPoolSize = "10"
  private val imapConnectionPoolTimeout = "600000"
  private val imapTimeout = "200000"
  private val imapConnectionTimeout = "200000"

  private val isDebuggingEnabled: Boolean = false
  
  // FIXME this set of booleans will
  // be replaced by appropriate vars given by the client
  // once the cache panel is implemented
  private val shouldUseCache: Boolean = false // set false to disable caching in kairos mail

  private var needsUpdate: Boolean = !shouldUseCache // false to use cache
  private val isFirstTime: Boolean = false
  
  
  
  /**
   * Authentication
   *
   */
  
  def authenticateUser(user: String, pass: String, host: String): String = {    
    // Search for the user in the database    
    val userCached = ImapUser.find(By(ImapUser.email, user))
    val userName = userCached.map(_.email.is).openOr("User not found")

    userCached match {
      case Full(u) => {
        // two hours
        val ageCacheIsConsideredOld = 0//60 * 60 * (60 * 1000)
        val ageUserCache = System.currentTimeMillis() - u.cacheCreation.getTime
        log.info("Cache creation" + u.cacheCreation.getTime + "\nSystem.currentTimeMillis() - u.cacheCreation.getTime "+ ageUserCache + " timeCacheOld: " + ageCacheIsConsideredOld)
        
        if (shouldUseCache)
        	needsUpdate = ageUserCache > ageCacheIsConsideredOld
        
        if(needsUpdate){
          println("\n*****************\nCache is old\nConnecting...\n*****************\n")
          connect(user, pass, host)
        } else {
          println("\n*****************\nCache is not old\nUsing cached user\n*****************\n")
          CardanoCachedUser.set(userCached)
          "SMAuthenticationGranted" 
        }       
      }
      case Empty => connect(user, pass, host)
      case _ => connect(user, pass, host)
    }
  }


  /**
   * Connection
   *mailContentForMessageId:selectedEmail
   */
  
  // Connection with credentials
  private def connect: Store = {
    val credentials = CardanoCredentials.is.openOr(Empty).asInstanceOf[SMCredentials]
    
    // Non secure connection
    val props = new Properties
    props.put("mail.imap.connectionpoolsize", imapConnectionPoolSize)
    props.put("mail.imap.connectionpooltimeout", imapConnectionPoolTimeout)
    props.put("mail.imap.timeout", imapTimeout)
    props.put("mail.imap.connectiontimeout", imapConnectionTimeout)
    
    val session: Session = Session.getDefaultInstance(props)
    session.setDebug(isDebuggingEnabled)
    val store: Store = session.getStore("imap")
    store.connect(credentials.host, credentials.user, credentials.pass)
    store
  }
  
  // FIXME: This version uses a try/catch block for authentication, which is not
  // good style. This should use Authenticator
  private def connect(user: String, pass: String, host: String): String = {
    try {
      // Secure connection
      // val props = new Properties
      // props.put("mail.store.protocol", "imaps")
      // props.put("mail.imap.enableimapevents", "true")
      // 
      // val session: Session = Session.getDefaultInstance(props)
      // 
      // session.setDebug(Props.getBool("mail.session.debug", true))
      // 
      // val store: Store = session.getStore()
      // store.connect(host, user, pass)
      // println(store)
      
      // Non secure connection
      val props = new Properties
      props.put("mail.imap.connectionpoolsize", imapConnectionPoolSize)
      props.put("mail.imap.connectionpooltimeout", imapConnectionPoolTimeout)
      props.put("mail.imap.timeout", imapTimeout)
      props.put("mail.imap.connectiontimeout", imapConnectionTimeout)
      
      val session: Session = Session.getDefaultInstance(props)

      session.setDebug(isDebuggingEnabled)

      val store: Store = session.getStore("imap")
      
      // Instead of sending the password here, it is possible to define
      // an authenticator object "a" and get a session with 
      // Session.getDefaultInstance(props, a). For now, we do using this other
      // strategy
      store.connect(host, user, pass)

      // Keep the store to use it during the Lift/Cardano session
      CardanoSession.set(Full(store))

      // Search for the user in the database
      // If it does not exist, creates the user and cache it
      val userInDatabase = ImapUser.find(By(ImapUser.email, user))
      userInDatabase match {
        case Full(u) => {
          log.info("User "+user+" found in database.")
          CardanoCachedUser.set(Full(u))
        }
        case Empty => {
          log.info("Creating a new entry in the database for user "+user)
          val u = ImapUser.create.email(user).password(pass).host(host).cacheCreation(new java.util.Date).saveMe
          CardanoCachedUser.set(Full(u))
        }
        case _ => log.debug("Param Failure when trying to create/find user in the database.")
      }
            
      // Store the credentials
      val credentials = new SMCredentials(user, pass, host)
      CardanoCredentials.set(Full(credentials))
      
      // Grant Authentication
      log.info("Authentication granted to "+user)
      "SMAuthenticationGranted"
    } catch {
      case e: NoSuchProviderException => e.printStackTrace(); log.info("Authentication denied to "+user); "SMAuthenticationDenied"
      case e: MessagingException => e.printStackTrace(); log.debug("Error found when trying to authenticate "+user); stackTrace(e)
    }
  }

  def synchronizeAll(in: String) = {
    // Synchronize all mailboxes
    val mailboxesHaveBeenUpdated = updateCacheListMailboxes("fresh")
    val mailboxesList = databaseListMailboxes("fresh")
    for (mb <- mailboxesList) {
      updateHeadersForFolder(mb.name, "fresh")
    }
    // Synchronize all headers/messages
  }
  
  def listMailInFolder(folderLabel: String): String = {
    val store = CardanoSession.is.openOr(Empty)
    store match {
      case store: Store => {
        val inbox: Folder = store.getFolder(folderLabel)
        inbox.open(Folder.READ_ONLY)
        val messages: List[Message] = inbox.getMessages().toList
        for(message <- messages) {
          println(message)
        }
      }
      case Empty => println("Error getting the Imap Store from session")
      case s => println("\n\nGot "+s)
    }   
    "Mail in folder "+folderLabel+" listed"
  }


  /**
   * Mailboxes
   *
   */

  // Get top level boxes
  // See the useful discussion at
  // http://stackoverflow.com/questions/4790844/how-to-get-the-list-of-available-folders-in-a-mail-account-using-java-mail
  def listMailboxes(in: String): List[SMMailbox] = {

    if (isFirstTime) {
      updateCacheListMailboxes(in)
      log.info("Database cache for Mailboxes has been updated")  
    }
    
    println("Needs update "+needsUpdate)
    
    if(needsUpdate){
      // Connect to IMAP server and retrieve a fresh list
      log.info("Imap Server: Connecting to IMAP server to retrieve a fresh mailboxes list")
      imapListMailboxes(in)
    } else {
      // Use the local database list
      log.info("Imap Server: Retrieving from the database the stored mailboxes list")
      databaseListMailboxes(in)
    }    
  }
  
  
  private def databaseListMailboxes(in: String): List[SMMailbox] = {

    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    var topLevelFoldersList: List[SMMailbox] = List()
    
    println("\n\n\n\n**********************\nUsing cache\n**********************\n")
    
    cachedUser match {
      case u: ImapUser => {
        val cachedFolders = u.folders.all
        cachedFolders match {
          case x :: xs => {
            println("Cached Folders: " + cachedFolders)
            topLevelFoldersList = cachedFolders.map(f => {
              val label: String = f.folderLabel
              val count = f.messageCount
              val unread = f.messageUnread
              println("Label, count, unread: "+label, count, unread)
              // Creates the case class
              new SMMailbox(label, count, unread)
            })  
          }
          case Nil => {
            log.debug("Imap Server Warning: no cached mailboxes found. Trying to recover mailboxes...")
            topLevelFoldersList = updateCacheListMailboxes("")
          }
        }          
      }
      case _ => log.debug("Imap Server Error: an error ocurred when trying to get the cached mailboxes")
    }
    topLevelFoldersList
  }
  
  private def updateCacheListMailboxes(in: String): List[SMMailbox] = {
    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    var topLevelFoldersList: List[SMMailbox] = List()
    
    cachedUser match {
      case u: ImapUser => {
        val cachedFolders = u.folders.all
        // If it is first time (or there are no folders), cached folders is empty
        cachedFolders match {
          case Nil => {
            // Get the folders from IMAP
            topLevelFoldersList = imapListMailboxes(in)
            for (folder <- topLevelFoldersList) {
              DBMailbox.create.folderLabel(folder.name).messageCount(folder.count).messageUnread(folder.unread).imapUser(u).save
            }
          }
          case _ => {
            log.info("Imap Server: Found mailboxes in database for user") 
            if (in == "fresh") {
              log.info("Imap Server: bulk delete of all the mailboxes")
              // Bulk delete of mailboxes
              DBMailbox.bulkDelete_!!(Like(DBMailbox.folderLabel, "%"))
              
              // Get the folders from IMAP
              topLevelFoldersList = imapListMailboxes(in)
              for (folder <- topLevelFoldersList) {
                DBMailbox.create.folderLabel(folder.name).messageCount(folder.count).messageUnread(folder.unread).imapUser(u).save
              }
            }
          }
        }
      }
      case _ =>
    }
    topLevelFoldersList
  }
  
  private def imapListMailboxes(in: String): List[SMMailbox] = {
    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    var topLevelFoldersList: List[SMMailbox] = List()
    
    // Connect
    val store: Store = connect
    
    // Retrieves the folders
    // Folders are closed by default, and it is not necessary to open them
    val topLevelFolders: List[Folder] = store.getDefaultFolder.list.toList
    topLevelFoldersList = topLevelFolders.map(f => {
      val label: String = f.toString
      val count = f.getMessageCount
      val unread = f.getUnreadMessageCount
      // Creates the case class
      new SMMailbox(label, count, unread)
    })

    store.close

    // The preferred order is the reversed one
    topLevelFoldersList.reverse
  }
  
 /* def createFolder(folderName: String): List[SMMailbox] = {
    var folders: List[SMMailbox] = List()
    
    try {
      // Connect
      val store: Store = connect
      
      // Get the specified folder
      val newFolder: Folder = store.getFolder(folderName)
      if(! newFolder.exists) {
      
        if(newFolder.create(Folder.HOLDS_MESSAGES)) {
          // creation succeeded - create a list with one SMMailbox element
          folders = List(new SMMailbox(folderName, 0, 0))
        }

      }

      store.close 
      } catch {
        case e: Exception => e.printStackTrace();log.info("Cannot create folder "+folderName);
        //case e: NoSuchProviderException => e.printStackTrace(); log.info("Authentication denied to "); ""
        //case e: MessagingException => e.printStackTrace(); log.debug("Error found when trying to authenticate "+user); stackTrace(e)
        } 
      
      folders
  }*/
  
  /*
   * Try to rename IMAP folder if it exists, or create new folder if previous
   * one is not exists.
   * Return "null" if no errors, or return string with error description.
   * TODO: need add localization of return strings
   */
   def renameOrCreateFolder(oldName: String, destName: String): String = {
    try {

      // TODO: it is not good to connect every time. We should in future use some
      // IMAP pool, which should be already connected to IMAP for this user.
      // This pool will speedup things, because using it will pass connect() stage
      // and srart making renaming/craeting folder immidiatly.
      // (But in current case, user will not feel difference, because current operation
      // is asynchronius and user don't wait end of this operation. It will feel
      // result in other operations, such as browse between emails, pages and etc.)

      // Connect
      val store: Store = connect

      val rootFolder: Folder = store.getDefaultFolder

      var oldFolder: Folder = rootFolder.getFolder(oldName)
      val newFolder: Folder = rootFolder.getFolder(destName)
      
      var resultCode: String = "" //empty string will mean no error
      
      if (oldFolder.exists()) {
        if (newFolder.exists())
          resultCode = "Folder with such name is already exists. Failed to rename folder"
        else {
          if (oldFolder.renameTo(newFolder) == false)
            resultCode = "Failed to rename folder"
        }
      } else {
        if (!newFolder.exists) {
          if (newFolder.create(Folder.HOLDS_MESSAGES) == false) {
            resultCode = "Failed to create folder"
          }
        }
        else
           resultCode = "Folder with such name is already exists. Failed to create folder"
      }

      store.close
      resultCode
    } catch {
      case e: Exception => e.printStackTrace(); log.info("Cannot create or rename folder " + destName);
      //case e: NoSuchProviderException => e.printStackTrace(); log.info("Authentication denied to "); ""
      //case e: MessagingException => e.printStackTrace(); log.debug("Error found when trying to authenticate "+user); stackTrace(e)
      "Failed to create or rename folder"
    }
  }
  
  /**
   * Headers
   *
   */
  
  def headersForFolder(folderLabel: String): List[SMMailHeader] = {
    
    if (isFirstTime) {
      updateHeadersForFolder(folderLabel, "fresh")
      log.info("Imap Server: Database cache for headers in mailbox"+ folderLabel +" has been updated")
    }
    
    if(needsUpdate){
      // Connect to IMAP server and retrieve a fresh list
      log.info("Imap Server: Connecting to IMAP server to retrieve fresh headers")
      imapHeadersForFolder(folderLabel)
    } else {
      // Use the local database list
      log.info("Imap Server: Retrieving from the database the stored headers")
      databaseHeadersForFolder(folderLabel)
    }
  }
  
  private def databaseHeadersForFolder(folderLabel: String): List[SMMailHeader] = {

    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    
    log.info("Imap Server: Using database for headers")

    val headerList: List[SMMailHeader] = cachedUser match {
      case u: ImapUser => {
        val cachedFolders = u.folders.all
        
        u.folders.refresh

        val selectedFolder = cachedFolders filter(_.folderLabel.toLowerCase == folderLabel.toLowerCase)

        selectedFolder match {
          case List(f) => {
        
              val messages: List[DBMessage] = f.messages.all
              println("Folder " + f)
              println(messages)
              
              messages match {
                case mes :: mss => {
                  messages.map( m => {
                    val id = m.messageId

                    val fromName = m.from
                    val fromEmail = m.from
                    val subject = m.subject
                    val util = new HNUtil
                    val date = util.toCappuccinoDate(m.date)
                    // FIXME should calculate md5?
                    val md5 = "md5"
                    val isSeen = m.isSeen

                    new SMMailHeader(id, subject, fromName, fromEmail, date, md5, isSeen)
                    })
                }
                case Nil => {
                  log.debug("Imap Server Warning: no cached mail headers found. Trying to recover mail headers...")
                  updateHeadersForFolder(folderLabel, "")
                }
              }              
            }
          case Nil => {
            log.debug("Imap Server Error: no folder found when retrieving mail headers.")
            List()
          }
        }          
      }
      case _ => log.debug("Imap Server Error: an error ocurred when trying to get the cached headers"); List()
    }
    headerList
  }
  
  
  private def updateHeadersForFolder(folderLabel: String, in: String): List[SMMailHeader] = {
    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    var headerList: List[SMMailHeader] = List()
    val util = new HNUtil
    
    // Gets the user
    cachedUser match {
      case u: ImapUser => {
        // Get the selected folder
        val cachedFolders = u.folders.all
        val selectedFolder = cachedFolders filter(_.folderLabel.toLowerCase == folderLabel.toLowerCase)

        selectedFolder match {
          case List(f) => {
            log.info("Cached folders "+ f + " with folder id " + f.id)
                        
            // Get the headers from IMAP
            headerList = imapHeadersForFolder(folderLabel)
            
            if (in == "fresh") {
              DBMessage.bulkDelete_!!(Like(DBMessage.messageId, "%"))
            }
            
            // Store the headers in the database
            for (header <- headerList) {
              println(header.messageId)
              val mailContent: SMMailContent = imapMailContentForMessageId(header.messageId, folderLabel)

              // FIXME: convert from Cappuccino Date to Java Data
              DBMessage.create.messageId(header.messageId).from(mailContent.from).subject(mailContent.subject).date(mailContent.date.toScalaDate).to(mailContent.to).bcc(mailContent.bcc).body(mailContent.body).isSeen(mailContent.isSeen).folder(f).save
            }
            headerList
          }
          case Nil => log.warn("Imap Server: the selected folder was not found and it could not be updated"); List()
          case _ => log.warn("Imap Server Error: unexpected error when looking for folders to update headers"); List()
        }
      }
      case _ => List()
    }
  }
  
  private def imapHeadersForFolder(folderLabel: String): List[SMMailHeader] = {
    // Connect
    val store: Store = connect
        
    // Get the specified folder
    val folder: Folder = store.getFolder(folderLabel)
    
    // Folders are retrieved closed. To get the messages it is necessary to
    // open them (but not to rename them, for example)
    folder.open(Folder.READ_ONLY)
    
    // With IMAP, getMessages does not download the mail: we get a pointer
    // to the actual message that it is in the server up to the moment
    // we access it (note that this is probably the reason why we can not
    // refactor the getting into teh messagesInFolder function)
    val messages: List[Message] = folder.getMessages.toList

  
    // Implementation 1: using headers
    // val headersList = messages map(_.getAllHeaders)
    // 
    // val headerList: List[SMMailHeader] = headersList map (hen => {
    //  // one list per message
    //  val hit = hen.asScala.toList
    //  val hitMap = hit.map(pair => {
    //    val p = pair.asInstanceOf[Header]
    //    (p.getName, p.getValue)
    //  }).toMap
    //  
    //  val id: String = hitMap.getOrElse("Message-ID", "")
    //  val subject: String = hitMap.getOrElse("Subject", "")
    //  val from: String = hitMap.getOrElse("From", "")
    //  val util = new HNUtil
    //  val date: CPDate = util.toCappuccinoDate(new java.util.Date) //hitMap.getOrElse("Date", "")) 
    //  
    //  //val md5: String = hitMap.getOrElse("", "")
    //  println(id + " " + subject)
    //  new SMMailHeader(id, subject, from, from, date, "md5")
    // })
  
    // Implementation 2: using messages directly
    // Advantages: 
    //     - date received as java.util.Date
    //     - subject is properly decoded
    val headerList: List[SMMailHeader] = messages.map( message => {
      val m = message.asInstanceOf[IMAPMessage]
      // Note the capitalization of the ID in IMAP API
      val id = m.getMessageID
      val from: List[Address] = m.getFrom.toList

      val fromName = from.map(f => f.asInstanceOf[InternetAddress].getPersonal).mkString(", ")
      val fromEmail = from.map(f => f.asInstanceOf[InternetAddress].getAddress).mkString(", ")
      
      val subject = SMMailUtil.decodeSubject(m)
      val util = new HNUtil
      val date = util.toCappuccinoDate(m.getSentDate)
      val md5 = m.isSet(Flags.Flag.SEEN).toString
      val isSeen: Boolean = m.isSet(Flags.Flag.SEEN)
      
      new SMMailHeader(id, subject, fromName, fromEmail, date, md5, isSeen)
      })
      
    // Disconnect
    // The false argument indicates that we do not want to expunge deleted 
    // folders in the server
    folder.close(false)
    store.close
    
    headerList
  }
 
  /**
  * Mail content API
  *
  */

  /** 
  * 
  * 
  * @param  messageId       well isn't it obvious
  * @param  selectedFolder  well isn't it obvious
  * @return                 dunno
  */
  def mailContentForMessageId(messageId: String, selectedFolder: String): SMMailContent = {

    if(needsUpdate){
      // Connect to IMAP server and retrieve a fresh message
      log.info("Imap Server: Connecting to IMAP server to retrieve fresh message")
      imapMailContentForMessageId(messageId, selectedFolder)
    } else {
      // Use the local database
      log.info("Imap Server: Retrieving from the database the stored message")
      databaseMailContentForMessageId(messageId, selectedFolder)
    }
  }

  private def databaseMailContentForMessageId(messageId: String, selectedFolder: String): SMMailContent = {
    val cachedUser = CardanoCachedUser.is.openOr(Empty)
    
    log.info("Imap Server: Using database cache for message with id "+messageId)

    val mailContent: SMMailContent = cachedUser match {
      case u: ImapUser => {
        val cachedFolders = u.folders.all
        
        u.folders.refresh

        val theFolder = cachedFolders filter(_.folderLabel.toLowerCase == selectedFolder.toLowerCase)

        theFolder match {
          case List(f) => {
        
              val messages: List[DBMessage] = f.messages.all
              f.messages.refresh
              val messagesFiltered = messages.filter(_.messageId == messageId)
              
              val content: SMMailContent = messagesFiltered match {
                case mes :: mss => {                  
                  val from: String = mes.from
                  // FIXME replyTo field must be added
                  val replyTo: String = mes.from
                  val to: String = mes.to
                  val cc: String = mes.cc
                  val bcc: String = mes.bcc

                  val subject: String = mes.subject
                  val util = new HNUtil
                  val date: CPDate = util.toCappuccinoDate(mes.date)

                  val javaUtil = new SMMailUtilJava()

                  val body: String = mes.body

                  val isSeen: Boolean = mes.isSeen
                  println("is seen "+ isSeen)

                  // FIXME: a dummy attachment is sent for testing the client
                  val attachment: List[String] = List("attachment1", "attachment2")

                  new SMMailContent(from, subject, date, replyTo, to, cc, bcc, body, isSeen, attachment)
                }
                case Nil => {
                  log.debug("Imap Server Warning: no cached mail headers found. Trying to recover mail headers...")
                  new SMMailContent("","", new CPDate(1L, 1), "", "", "", "", "", false, List())
                }
              }
              content              
            }
          case Nil => {
            log.debug("Imap Server Error: no folder found when retrieving mail headers.")
            // FIXME: 
            new SMMailContent("","", new CPDate(1L, 1), "", "", "", "", "", false, List())
          }
        }          
      }
      case _ => log.debug("Imap Server Error: an error ocurred when trying to get the cached headers"); new SMMailContent("","", new CPDate(1L, 1), "", "", "", "", "", false, List())
    }
    mailContent
  }
   
  private def imapMailContentForMessageId(messageId: String, selectedFolder: String): SMMailContent = {
     // Connect
     val store: Store = connect

     val folder: Folder = store.getFolder(selectedFolder)
     folder.open(Folder.READ_ONLY)

     val util = new HNUtil
     val mailUtil = SMMailUtil

     // Search test
     val term: MessageIDTerm = new MessageIDTerm(messageId)

     val messages: List[Message] = folder.search(term).toList

     // The actual downloading of messages takes place here
     val messageSelected: List[SMMailContent] = for (msg <- messages) yield {

         val m = msg.asInstanceOf[IMAPMessage]

         val from: String = Option(InternetAddress.toString(m.getFrom)) getOrElse "Address not specified"
         // FIXME analyze the reply to case
         val replyTo: String = Option(InternetAddress.toString(m.getReplyTo)) getOrElse "Address not specified"
         val to: String = Option(InternetAddress.toString(m.getRecipients(Message.RecipientType.TO))) getOrElse "Address not specified"
         val cc: String = Option(InternetAddress.toString(m.getRecipients(Message.RecipientType.CC))) getOrElse "Address not specified"
         val bcc: String = Option(InternetAddress.toString(m.getRecipients(Message.RecipientType.BCC))) getOrElse "Address not specified"
         

         val subject: String = Option(SMMailUtil.decodeSubject(m)) getOrElse "<No subject>"
         val date: CPDate = Option(util.toCappuccinoDate(m.getSentDate)) getOrElse(util.toCappuccinoDate(new java.util.Date))

         val javaUtil = new SMMailUtilJava()

         val body: String = Option(javaUtil.getText(m)) getOrElse ""

         val isSeen: Boolean = m.isSet(Flags.Flag.SEEN)
         println("is seen "+ isSeen)

         val attachment: List[String] = mailUtil.attachmentListForMessage(m)
         println(attachment)
         
         new SMMailContent(from, subject, date, replyTo, to, cc, bcc, body, isSeen, attachment)
     } 

     // Disconnect
     folder.close(true)
     store.close

     messageSelected(0)
   }
  
  
  def stackTrace(throwable: Throwable): String = {
    val writer: Writer = new StringWriter()
    val printWriter: PrintWriter = new PrintWriter(writer)
    throwable.printStackTrace(printWriter)
    writer.toString
  }
}




object SMMailUtil extends Loggable {

  def attachmentListForMessage(m: Message): List[String] = {
    val content = m.getContent
    val messageInfo: List[Map[String, String]] = content match {
      case mp: Multipart => handleMultipart(mp).toList
      case _ => List(Map("contentType"->"non-valid"))
    }
    val listOfAttachments: List[Option[String]] = messageInfo.map(_.get("attachment"))
    listOfAttachments.flatten
  }
  
  def handleMultipart(m: Multipart) = {
    for (i <- 0 until m.getCount) yield handlePart(m.getBodyPart(i))
  }
  
  def handlePart(part: Part): Map[String, String] = {
    val disposition: String = Option(part.getDisposition) getOrElse ""
    val contentType: String = Option(part.getContentType) getOrElse ""
    
    println("Disposition: "+disposition)
    println("ContentType: "+contentType)
    val result: Map[String, String] = if (disposition.equalsIgnoreCase("")) {
      Map("contentType"-> contentType)
    } else if (disposition.equalsIgnoreCase(Part.ATTACHMENT)) {
      Map("attachment"-> part.getFileName, 
          "contentType"-> contentType)
      //saveFile(part.getFileName(), part.getInputStream());
    } else if (disposition.equalsIgnoreCase(Part.INLINE)) {
      Map("inline"-> part.getFileName,
          "contentType"-> contentType)
      //saveFile(part.getFileName(), part.getInputStream());
    } else {  // Should never happen
      Map("other"-> disposition)
    }
    println("Result: "+result)
    result
  }

  implicit def multipartHelper(m: Multipart) = new {
    def bodyParts = for (i <- 0 until m.getCount) yield m.getBodyPart(i)
  }

  def decodeSubject(m: Message): String = Box !! m.getSubject openOr("")

  // Version 1
  // Development
  def processPart(m: Part): String = m.getContent match {
        case p: Multipart => println("*******Processing multipart with "+p.getCount+" parts"); p.bodyParts map { processPart } mkString " "
        case h: String => {
          var result: String = ""
          if (m.isMimeType("text/plain")) {
            result = h
          } else if (m.isMimeType("text/html")) {
          println("******* String text/html"+m.getContentType)
        }
        result
      }
        case x => {
          logger.warn("IMAP Don't know how to extract text from a " + x.getClass + " " + m.getContentType + "") 
          val in = new BufferedInputStream(m.getInputStream)
          scala.io.Source.fromInputStream(in).getLines().mkString("\n")
        }
      }
  
  //http://www.markhneedham.com/blog/2009/10/26/scala-converting-an-input-stream-to-a-string/
  def convertStreamToString(is : InputStream) : String = {
      def inner(reader : BufferedReader, sb : StringBuilder) : String = {
        val line = reader.readLine()
        if(line != null) {
          try {
            inner(reader, sb.append(line + "\n"))
          } catch {
            case e : IOException => e.printStackTrace()
          } finally {
            try {
              is.close()
            } catch {
              case e : IOException => e.printStackTrace()
            }
          }

        }
        sb.toString()
      }

      inner(new BufferedReader(new InputStreamReader(is)), new StringBuilder())
    }
}

case class SMCredentials(user: String, pass: String, host: String)

/* SMMailbox
  @implementation SMMailbox : CPObject
  {
      CPString name @accessors;
      CPNumber count @accessors;
      CPNumber unread @accessors;
  }
*/
case class SMMailbox(name: String, count: Int, unread: Int) {
  override def toString: String = name+" total: "+count+" ("+unread+")"
}

/* SMMailHeader.j 
  @implementation SMMailHeader : CPObject
  {
      CPNumber messageId;
      CPString subject;
      CPString fromName;
      CPString fromEmail;
      CPDate date;
      CPString md5;
  }
*/
case class SMMailHeader(messageId: String, subject: String, fromName: String, fromEmail: String, date: CPDate, md5: String, isSeen: Boolean)

/* SMMailContent.j
  @implementation SMMailContent : CPObject
  {
      CPString from;
      CPString subject;
      CPDate date;
      CPString to;
      CPString toJoin;
      CPString cc;
      CPString bcc;
      CPString body;
  }
*/
case class SMMailContent(from: String, subject: String, date: CPDate, to: String, toJoin: String, cc: String, bcc: String, body: String, isSeen: Boolean, attachment: List[String])
