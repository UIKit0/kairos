/*
 *  Boot
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

package bootstrap.liftweb
import _root_.net.liftweb.util._
import _root_.net.liftweb.common._
import _root_.net.liftweb.http._
import _root_.net.liftweb.http.provider._
import _root_.net.liftweb.sitemap._
import _root_.net.liftweb.sitemap.Loc._
import Helpers._
import net.liftweb._
import http.{LiftRules, NotFoundAsTemplate, ParsePath}
import sitemap.{SiteMap, Menu, Loc}
import util.{ NamedPF }

import net.liftweb.http.js.jquery.JQuery14Artifacts

import net.liftweb.mapper.{MapperRules,DefaultConnectionIdentifier, DBLogEntry,DB,Schemifier,StandardDBVendor}
import com.smartmobili.model._


class Boot {
  def boot {
  
  
    // where to search snippet
    LiftRules.addToPackages("com.smartmobili")

		// handle JNDI not being available
		if (!DB.jndiJdbcConnAvailable_?) {
			DB.defineConnectionManager(DefaultConnectionIdentifier, Database)
			LiftRules.unloadHooks.append(() => Database.closeAllConnections_!())
		}

		if (Props.devMode)
			Schemifier.schemify(true, Schemifier.infoF _, ImapUser, Mailbox, Message)

    // build sitemap
    val entries = List(Menu("Home") / "index") :::
									List(Menu("Mail") / "capp") :::
									List(Menu("Mail-debug") / "capp_debug") :::
                  Nil
    
    LiftRules.uriNotFound.prepend(NamedPF("404handler"){
      case (req,failure) => NotFoundAsTemplate(
        ParsePath(List("exceptions","404"),"html",false,false))
    })
    
    LiftRules.setSiteMap(SiteMap(entries:_*))
    
    // set character encoding
    LiftRules.early.append(_.setCharacterEncoding("UTF-8"))
    
    LiftRules.jsArtifacts = JQuery14Artifacts

    /*
     * Show the spinny image when an Ajax call starts
     */
    LiftRules.ajaxStart =
    Full(() => LiftRules.jsArtifacts.show("ajax-loader").cmd)

    /*
     * Make the spinny image go away when it ends
     */
    LiftRules.ajaxEnd =
    Full(() => LiftRules.jsArtifacts.hide("ajax-loader").cmd)

    LiftRules.early.append(makeUtf8)

    LiftRules.useXhtmlMimeType = false

		/**
		 * Cardano
		 * To avoid ajax retries when the operation is expensive
		 * the retry is limited to one, and time to consider the
		 * server has not responded to 30s
		 */
		LiftRules.ajaxRetryCount = Full(1)
		LiftRules.ajaxPostTimeout = 30000

    // We serve Cappuccino files with wicked friendly
    // mime types
    LiftRules.liftRequest.append {
      case Req( _, "j", GetRequest) => true
      case Req( _, "sj", GetRequest) => true
      case Req( _, "plist", GetRequest) => true
    }

    LiftRules.statelessDispatchTable.prepend {
      case r @ Req( _, "j", GetRequest) => ObjJServer.serve(r)
      case r @ Req( _, "sj", GetRequest) => ObjJServer.serve(r)
      case r @ Req( _, "plist", GetRequest) => ObjJServer.serve(r)
    }
	}

  /**
   * Force the request to be UTF-8
   */
  private def makeUtf8(req: HTTPRequest) {
    req.setCharacterEncoding("UTF-8")
  }
	
	/**
	 * Database for caching
	 */
	object Database extends StandardDBVendor( 
		Props.get("db.class").openOr("org.h2.Driver"), 
		Props.get("db.url").openOr("jdbc:h2:database/kairos_mail_dev;AUTO_SERVER=TRUE"), 
		Props.get("db.user"),
		Props.get("db.pass"))
}

object ObjJServer {
  def serve(req: Req)(): Box[LiftResponse] =
  for {
    url <- LiftRules.getResource(req.path.wholePath.mkString("/", "/", ""))
    urlConn <- tryo(url.openConnection)
    lastModified = ResourceServer.calcLastModified(url)
  } yield {
    req.testFor304(lastModified, "Expires" -> toInternetDate(millis + 30.days)) openOr {
      val stream = url.openStream
      StreamingResponse(stream, () => stream.close, urlConn.getContentLength,
                        (if (lastModified == 0L) Nil else
                         List(("Last-Modified", toInternetDate(lastModified)))) :::
                        List(("Expires", toInternetDate(millis + 30.days)),
                             ("Content-Type","application/text")), Nil,
                        200)
    }
  }

}