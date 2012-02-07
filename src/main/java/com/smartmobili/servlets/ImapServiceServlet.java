/*
 *  ImapServiceServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili.servlets;

import javax.mail.*;
import javax.mail.internet.InternetAddress;
import javax.mail.search.MessageIDTerm;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.*;
import java.lang.reflect.Method;
import java.util.ArrayList;
import org.apache.log4j.*;

import com.smartmobili.httpSessionAttributes.CurrentComposingEmailProperties;
import com.smartmobili.other.MailTextAndAttachmentsProcesser;
import com.smartmobili.other.ImapSession;
//import com.sun.mail.imap.IMAPFolder;
import com.sun.mail.imap.IMAPMessage;

import net.sf.json.*;
//import org.eclipse.jetty.websocket.*;

@SuppressWarnings("serial")
public class ImapServiceServlet extends HttpServlet {
	private static final int messagesCountPerPage = 50; // NOTE: There is also settings for this at client side (to change, need change both client and server sides).
	final int SessionMaxInactiveInterval = 10*60;
	
	Logger log = Logger.getLogger(ImapServiceServlet.class);
/*	public WebSocket doWebSocketConnect(HttpServletRequest request, String protocol)
    {
        return null;//new ChatWebSocket();
    }*/

	protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
		try {
			resp.getOutputStream().print("Get method is not supported");
		} catch (Exception ex) {
		}
	}

	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) {
		BufferedReader reader = null;
		PrintWriter writer = null; 
		try {
		    reader = new BufferedReader(new InputStreamReader(request.getInputStream(), "UTF8"));
			
			StringBuilder sb = new StringBuilder();
			String line = reader.readLine();
			while (line != null) {
				sb.append(line + "\n");
				line = reader.readLine();
			}
			reader.close();
			String data = sb.toString();

			JSONObject jsonObject = (JSONObject) JSONSerializer.toJSON(data);
			String functionNameToCall = (String) jsonObject
					.get("functionNameToCall");
			String functionParametersAsJsonString = null;
			if (jsonObject.get("functionParameters") instanceof JSONNull == false)
				functionParametersAsJsonString = (String) jsonObject.get("functionParameters");
			JSONObject functionParametersAsJsonObject = null;
			if (functionParametersAsJsonString != null)
				functionParametersAsJsonObject = (JSONObject) JSONSerializer
					.toJSON(functionParametersAsJsonString);

			HttpSession session = request.getSession();
			session.setMaxInactiveInterval(SessionMaxInactiveInterval); // TODO: need to test, if between requests is more time, what application will do withoout all attributes from session? It should reload/re-request user login? Or silently reconnect with same credentials and continue to work (show folders and etc).
			// TODO: who setup session? Why this made here, and not there where is ImapSession initialized?
			
			Method method = ImapServiceServlet.class.getMethod(
					functionNameToCall, JSONObject.class, HttpSession.class);
			JSONObject res = (JSONObject) method.invoke(this,
					functionParametersAsJsonObject, session);

			response.setContentType("application/json; charset=UTF-8");

			OutputStreamWriter osw = new OutputStreamWriter(
					response.getOutputStream(), "UTF8");
			writer = new PrintWriter(osw, true);
			writer.print(res.toString());
			writer.flush();
		}
		catch (Exception ex) {
			log.error("Exception in doPost()", ex);
			ex.printStackTrace(); 
		}
		finally {
			if (writer != null)
				writer.close();
			if (reader != null)
				try {
					reader.close();
				} catch (IOException e) {
					/* nothing */
				}
		}
	}

	public JSONObject authenticate(JSONObject parameters, HttpSession session) {
		// We don't have our own DB and accounting system, we use IMAP system.
		/*
		 * NOTE: we don't cache authentication results (if it success) so each
		 * further call of "authenticate" with same session will still re-check
		 * credentials. In future need make TESTS/trace and if this
		 * "authenticate" is called several times during app run (not only at
		 * app start), then need to make same caching and re-check password only
		 * in intervals (e.g. one time per 2 hours).
		 * NOTE: with saved session (see TODO bellow) this above NOTE is not a 
		 * problem, because authenticate will work as other functions - first
		 * it will check saved IMAP session. If it still connected and alive,
		 * just use it (in case of authenticate - immidiately return with success. 
		 * NOTE: we need also check if username and password same as was when initial
		 * connection. If not then re-authenticate and update saved imap session.
		 */
		session.setAttribute("authenticationUserName",
				parameters.get("userName"));
		session.setAttribute("authenticationPassword",
				parameters.get("password"));
		

		// TODO: save opened IMAP connection to session. Later don't forget to
		// close it when session timeout expired, or used exited. (logged out).

		JSONObject res = new JSONObject();
		
		Store imapStore = ImapSession.imapConnect(session);
		if (imapStore != null) {
			res.put("status", "SMAuthenticationGranted");
			session.setAttribute("authenticatated", true);
			try
			{ imapStore.close(); }
			catch(Exception ex){}
		} else {
			res.put("status", "SMAuthenticationDenied");
			session.setAttribute("authenticatated", false);
		}	

		return res;
	}

	public JSONObject listMailfolders(JSONObject parameters, HttpSession httpSession) throws MessagingException {
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
													// and connected imapStore,
													// or reconnect.
		try {
			Folder defaultFolder = imapStore.getDefaultFolder(); // Actually here is IMAPFolder
			Folder[] imapFolders = defaultFolder.list(); 

			// TODO: find way to speedup gettin attributes. Somekind of "fetch" for all folders from list. Perhaps "Fetch" command will work? If no, then split getting list of folder names and gettin folder attributes. And then in GUI first show list of folders, then show "loading" icon near each folder, and then load attributes for each folder in background, replacing loading icon with number of unread messages. Worse way: use some kind of cache, but it will show not actual information which can confuse user, and still we need show progress icon and reload attributes in background. So better way to not use cache.
			JSONArray jsonArrayOfFolders = new JSONArray();
			for (Folder f : imapFolders) {
				JSONObject folderAsJson = new JSONObject();
				folderAsJson.put("label", f.toString());// f.getFullName());
				int msgCount = 0;
				try
				{
					msgCount = f.getMessageCount();
				}
				catch(Exception ex){}
				folderAsJson.put("count", msgCount);
				
				int unreadMsgCount = 0;
				try
				{
					unreadMsgCount = f.getUnreadMessageCount();
				}
				catch(Exception ex){}
				folderAsJson.put("unread", unreadMsgCount);
				jsonArrayOfFolders.add(folderAsJson);
			}
			JSONObject result = new JSONObject();
			result.put("listOfFolders", jsonArrayOfFolders);
			return result;
		} finally {
			imapStore.close();
		}
	}
	
	public JSONObject headersForFolder(JSONObject parameters, HttpSession httpSession) throws MessagingException  {
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
													// and connected imapStore,
													// or reconnect.
		try {
			// Get the specified folder
			Folder folder = imapStore.getFolder(parameters.getString("folder"));
	
			// Folders are retrieved closed. To get the messages it is necessary to
		    // open them (but not to rename them, for example)
			folder.open(Folder.READ_ONLY);
			
			// With IMAP, getMessages does not download the mail: we get a pointer
		    // to the actual message that it is in the server up to the moment
		    // we access it (note that this is probably the reason why we can not
		    // refactor the getting into teh messagesInFolder function)
			
		    int fromT = 1 + messagesCountPerPage * (parameters.getInt("pageToLoad") - 1);
			
			// TODO: what if will be requested page which not exists at IMAP, so from will be greater that messages count?
		    int toT = fromT + messagesCountPerPage - 1;
		    if (toT > folder.getMessageCount())
		    	toT = folder.getMessageCount();
		    
		    // inverse "from" and "to" to get reverse order
		    final int to = folder.getMessageCount() - fromT+1;
		    final int from = folder.getMessageCount() - toT+1;
			
		    final Message[] messagesArr = folder.getMessages(from, to);
		    	      FetchProfile fp = new FetchProfile();
		    	      fp.add(FetchProfile.Item.ENVELOPE);
		    	      fp.add(FetchProfile.Item.FLAGS);
		    	      fp.add("Newsgroups");
		    	      folder.fetch(messagesArr, fp);
	      
			JSONArray jsonArrayOfMessagesHeaders = new JSONArray();
			for (Message msg : messagesArr) {
				JSONObject messageHeaderAsJson = new JSONObject();			
				final IMAPMessage imapMsg = (IMAPMessage)msg;
				messageHeaderAsJson.put("messageId", imapMsg.getMessageID());
				messageHeaderAsJson.put("from_Array", imapMsg.getFrom());
				messageHeaderAsJson.put("subject", imapMsg.getSubject());			
				messageHeaderAsJson.put("sentDate", (int)(imapMsg.getSentDate().getTime() / 1000));
				messageHeaderAsJson.put("isSeen", imapMsg.isSet(Flags.Flag.SEEN));
				jsonArrayOfMessagesHeaders.add(0, messageHeaderAsJson); // inserting to begin of list to get reverse order of mails (from new to old).
			}
			
			JSONObject result = new JSONObject();
			result.put("listOfHeaders", jsonArrayOfMessagesHeaders);
			// pass back input parameters to idetificate this request.
			result.put("folder", parameters.getString("folder")); 
			result.put("page", parameters.getInt("pageToLoad"));
			// return result
			return result;
		}
		catch(Exception ex) {
			JSONObject result = new JSONObject();
			result.put("listOfHeaders", null);
			return result;
		}
		finally {
			imapStore.close();
		}
	}
	
	public JSONObject mailContentForMessageId(JSONObject parameters, HttpSession httpSession) throws MessagingException, IOException {
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
		// and connected imapStore,
		// or reconnect.

		try {
			// Get the specified folder
			Folder folder = imapStore.getFolder(parameters.getString("folder"));
	
			// Folders are retrieved closed. To get the messages it is necessary to
		    // open them (but not to rename them, for example)
			folder.open(Folder.READ_ONLY);
			
			MessageIDTerm mIdTerm = new MessageIDTerm(parameters.getString("messageId"));
			
			JSONObject result = new JSONObject();
		
			Message[] arr = folder.search(mIdTerm);
			if (arr.length > 0)
			{
				IMAPMessage msg = (IMAPMessage)arr[0];
				JSONObject mailContentInJson = new JSONObject();
				mailContentInJson.put("from_Array", msg.getFrom());
				mailContentInJson.put("from", InternetAddress.toString(msg.getFrom()));
				
				mailContentInJson.put("replyTo_Array", msg.getReplyTo());
				mailContentInJson.put("to_Array", msg.getRecipients(Message.RecipientType.TO));
				mailContentInJson.put("to", InternetAddress.toString(msg.getRecipients(Message.RecipientType.TO)));
				mailContentInJson.put("cc_Array", msg.getRecipients(Message.RecipientType.CC));
				mailContentInJson.put("bcc_Array", msg.getRecipients(Message.RecipientType.BCC));
				mailContentInJson.put("subject", msg.getSubject());	
				mailContentInJson.put("sentDate", (int)(msg.getSentDate().getTime() / 1000));
				
				MailTextAndAttachmentsProcesser javaUtil = new MailTextAndAttachmentsProcesser();
				mailContentInJson.put("body", javaUtil.getText(parameters.getString("folder"), 
						parameters.getString("messageId"), msg)); // TODO: need to send to cappucino not just "text" but separated multipart content as is (so it will show images and text properly). See more comments by Oobe in SMMailUtilJava regarding background downloading of attachements (images).
				
				mailContentInJson.put("isSeen", msg.isSet(Flags.Flag.SEEN));
				
				mailContentInJson.put("attachements", null); // TODO: SMMailUtil function attachmentListForMessage from Scala was used here. 
				
				result.put("mailContent", mailContentInJson);
			}
			else
			{
				result.put("mailContent", null);
			}
			return result;
		} finally {
			imapStore.close();
		}
	}
	
	/*
	 * Rename IMAP folder. 
	 * Result is "" if no errors, or result is string with
	 * error description. TODO: need add localization of return strings
	 */
	public JSONObject renameFolder(JSONObject parameters, HttpSession httpSession) throws MessagingException, IOException {
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
		// and connected imapStore,
		// or reconnect.

		// TODO: it is not good to connect every time. We should in future use
		// some
		// IMAP pool, which should be already connected to IMAP for this user.
		// This pool will speedup things, because using it will pass connect()
		// stage
		// and start making renaming/creating folder immediately.
		// (But in current case, user will not feel difference, because current
		// operation
		// is asynchronous and user don't wait end of this operation. It will
		// feel
		// result in other operations, such as browse between emails, pages and
		// etc.)

		JSONObject result = new JSONObject();
		try {
			String resultCode = "";
			Folder rootFolder = imapStore.getDefaultFolder();
			Folder oldFolder = rootFolder.getFolder(parameters
					.getString("oldFolderName"));
			Folder newFolder = rootFolder.getFolder(parameters
					.getString("toName"));

			if (oldFolder.exists() == false)
				resultCode = "Folder to rename is not exists.";
			else {
				if (newFolder.exists())
					resultCode = "Folder with such name is already exists. Failed to rename folder.";
				else {
					if (oldFolder.renameTo(newFolder) == false)
						resultCode = "Failed to rename folder.";
				}
			}

			result.put("result", resultCode);
		} catch (Exception ex) {
			log.info("Cannot rename folder from "
					+ parameters.getString("oldFolderName") + " to "
					+ parameters.getString("toName"));
			result.put("result",
					"Error exception raised: Failed to rename folder.");
		} finally {
			imapStore.close();
		}
		// transfer input parameters back to indicate which exactly folder was renamed.
		result.put("oldFolderName", parameters
				.getString("oldFolderName"));
		result.put("toName", parameters
				.getString("toName"));
		// return result
		return result;
	}
	
	/*
	   * Create IMAP folder and "subscribe" (IMAP command) to it.
	   * Result is "" if no errors, or result is string with error description.
	   * TODO: need add localization of return strings
	   */
	public JSONObject createFolder(JSONObject parameters, HttpSession httpSession) throws MessagingException, IOException {
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
		// and connected imapStore,
		// or reconnect.

		// TODO: it is not good to connect every time. We should in future use
		// some
		// IMAP pool, which should be already connected to IMAP for this user.
		// This pool will speedup things, because using it will pass connect()
		// stage
		// and start making renaming/creating folder immediately.
		// (But in current case, user will not feel difference, because current
		// operation
		// is asynchronous and user don't wait end of this operation. It will
		// feel
		// result in other operations, such as browse between emails, pages and
		// etc.)

		JSONObject result = new JSONObject();
		try {
			String resultCode = "";
			Folder rootFolder = imapStore.getDefaultFolder();
			Folder newFolder = rootFolder.getFolder(parameters
					.getString("folderNameToCreate"));

			if (newFolder.exists()) {
				resultCode = "Folder with such name is already exists. Failed to create folder.";
			} else {
				if (newFolder.create(Folder.HOLDS_MESSAGES) == false) {
					resultCode = "Failed to create folder.";
				} else {
					if (newFolder.isSubscribed() == false)
						newFolder.setSubscribed(true);
				}
			}

			result.put("result", resultCode);
		} catch (Exception ex) {
			log.info("Cannot create folder  "
					+ parameters.getString("folderNameToCreate"));
			result.put("result",
					"Error exception raised: Failed to create folder.");
		} finally {
			imapStore.close();
		}
		return result;
	}
	
	/*
	 * Return new events from server to client such as "changed list of visible headers with folders
	 * list and unread messages" (this is UNDONE yet). 
	 * Other thing is check if session is still valid (see TODOs bellow. Currently it works by checking 
	 * IMAP credentials from imap server (this is bad, because it will connect to server often for this).
	 */
	public JSONObject getEventsAndTestSessionValidSoKeepAlive(JSONObject parameters, HttpSession httpSession) throws MessagingException  {
		// TODO: // UNDONE: this is temporary solution. It should be replaced to keep IMAP connection alive.
		// !!!!!!!!!!Currently it re-connects each 3 seconds and this is bad!!!!!!!!!!
		// How it should work (again, because described in this file several times in TODOs):
		// It should get imap session (saved once at authenticate) and re-use it. 
		// Here we SHOULD check if "saved imap" is exists in session. If exists, check if it connected. 
		// If all fine, return OK. If imap connection is not exists - means that session is ended its life in 
		// keep-alive cycle so all variables reset, then return NOT OK means that need to re-authenticate. 
		// If session is exists but offline - remote/close it and re-authenticate.
		//
		// The one thing which is a little hard - there is need think out when and who will close imap connection.
		// Especially if session is ended its life. 
		Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
																// and connected imapStore,
																// or reconnect.

		// If ImapStore is null, this means that saved in httpSession IMAP credentaials is invalid or NULL.
		JSONObject result = new JSONObject();
		if (imapStore != null) {
			imapStore.close();
			result.put("credentialsIsValidInSession", true);
		}
		else {
			result.put("credentialsIsValidInSession", false); 
			// This means that client (Cappuccino) should re-authenticate. It
			// should first try silently do this, and if old credentials is
			// invalid too, then reload app asking user to re-enter login and
			// password (or just show authentication dialog).
		}

		return result;
	}
	
	public JSONObject currentlyComposingEmailGetListOfAttachments(JSONObject parameters, HttpSession httpSession) throws MessagingException, IOException {
		//Store imapStore = ImapSession.imapConnect(httpSession); // TODO: get cached opened
		// and connected imapStore,
		// or reconnect.

		JSONObject result = new JSONObject();
		
		try {
			CurrentComposingEmailProperties ccep = CurrentComposingEmailProperties.getFromHttpSessionOrCreateNewDefaultInIt(httpSession);
			ArrayList<CurrentComposingEmailProperties.OneAttachmentProperty> listOfAttachemnts = 
					ccep.getCopyOfListOfAttachments();
			JSONArray jsonList = new JSONArray();
			for(CurrentComposingEmailProperties.OneAttachmentProperty webServerAttachmentProperty : listOfAttachemnts)
			{
				JSON obj = net.sf.json.JSONSerializer.toJSON(webServerAttachmentProperty);
				//Address a = InternetAddress.parse("127.0.0.2")[0];
				jsonList.add(obj);
			}
			
			result.put("listOfAttachments", jsonList);
		} catch (Exception ex) {
			log.info("Exception in currentlyComposingEmailGetListOfAttachments, details=" + ex.toString());
			result.put("result",
					"Error exception raised: Failed to create folder.");
		} 
		return result;
	}
}
