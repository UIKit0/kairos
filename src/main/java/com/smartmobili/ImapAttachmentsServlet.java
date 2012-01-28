/*
 *  ImapAttachmentsServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kzarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili;

import java.io.IOException;
import java.net.URLDecoder;
import java.net.URLEncoder;

import javax.mail.Flags;
import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Part;
import javax.mail.Store;
import javax.mail.internet.InternetAddress;
import javax.mail.search.MessageIDTerm;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.json.JSONObject;

import com.sun.mail.imap.IMAPMessage;
import com.sun.mail.util.BASE64DecoderStream;

@SuppressWarnings("serial")
public class ImapAttachmentsServlet extends HttpServlet {
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
		
		Store imapStore = ImapSession.imapConnect(req.getSession()); 
		// TODO: get cached opened
		// and connected imapStore,
		// or reconnect.

		ServletOutputStream out = null;
		try {
			out = resp.getOutputStream();
		} catch (IOException e2) {
			/*nothing*/
		}
		try {
			// Get the specified folder
			Folder folder = imapStore.getFolder(URLDecoder.decode(req.getParameter("imapFolder"), "UTF8"));
	
			// Folders are retrieved closed. To get the messages it is necessary to
		    // open them (but not to rename them, for example)
			folder.open(Folder.READ_ONLY);
			
			MessageIDTerm mIdTerm = new MessageIDTerm(req.getParameter("imapMailId"));
			
			Message[] arr = folder.search(mIdTerm);
			if (arr.length > 0)
			{
				IMAPMessage msg = (IMAPMessage)arr[0];
				SMMailUtilJava util = new SMMailUtilJava();
				int size = Integer.parseInt(req.getParameter("fileSize"));
				String fileName = req.getParameter("fileName");
				Part part = util.getAttachmentPart(msg, size, fileName, false);
				if (part == null)
					out.print("Not found requested attachment in message"); // TODO: perhaps show image icon with erroror something else?
				else {
					boolean asThumbnail = Boolean.parseBoolean(req.getParameter("asThumbnail"));
					// TODO: this is huge traffic. Perhaps it is better to cache this in DB? (or cache only if requested more than 1 times). (so we can have DB with records for each attachment, and count of accesses).
					
					if(part.isMimeType("image/*")) {
						// return image or thumbnail
						
						if (asThumbnail) {
							out.print("Here is image thumbnail"); // UNDONE:
							// UNDONE: set mimeType of output stream.
						}
						else {
							// Here is full-size image
							BASE64DecoderStream stream = (BASE64DecoderStream)part.getContent();
							byte[] buf = new byte[1024];
							
							resp.setContentType(part.getContentType());
							resp.setContentLength(size);
							while(true) {
								int readed = stream.read(buf, 0, buf.length);
								if (readed < 0)
									break;
								out.write(buf, 0, readed);
							}
						}
					}
					else {
						if (asThumbnail) {
							out.print("Not yet supported"); // TODO: (if need) if Thubmnail requested and filetype is an file, then show image via extension or an default image.
							// UNDONE: set mimeType of output stream.
						}
						else {
							// return whole file as is
							// UNDONE: set mimeType of output stream.
							out.print("Not yet supported");
						}
					}
				}
			}
			else
			{
				// TODO: output error icon for image.
				// Temporary:
				out.print("Error: not found message via message id");
			}
			folder.close(false);
		} catch (Exception e) {
			// TODO:
			try {
				out.print("Exception");
			} catch (IOException e1) {
				// TODO Auto-generated catch block
				e1.printStackTrace();
			}
		} finally {
			try {
				imapStore.close();
			} catch (MessagingException e) {
				/*nothing*/
			}
		}
		
		
			
			/*return "getAttachment?hash=" + bp.hashCode() + 
					"&fileSize=" + bp.getSize() +
					"&imapFolder=" + URLEncoder.encode(usedForLinkToAttachment_imapMailFolder, "UTF8") + 
					"&imapMailId=" + URLEncoder.encode(usedForLinkToAttachment_imapEmailId, "UTF8") + 
					"&fileName=" + URLEncoder.encode(bp.getFileName(), "UTF8") + 
					"&asThumbnail=" + String.valueOf(asThumbnail);*/
	
	}
}
