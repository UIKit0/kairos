/*
 *  ImapAttachmentsServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili.servlets;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.URLDecoder;

import javax.mail.Folder;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Part;
import javax.mail.Store;
import javax.mail.search.MessageIDTerm;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.smartmobili.other.MailTextAndAttachmentsProcesser;
import com.smartmobili.other.ImapSession;
import com.smartmobili.other.Thumbnailer;

@SuppressWarnings("serial")
public class ImapAttachmentsServlet extends HttpServlet {
	final static int MaxSizeOfOritinalImageToProcessIntoThumbnailInBytes = 6 * 1024 * 1024; // 6 Mb
	
	final static int ThumbnailsWidth = 180;
	final static int ThumbnailsHeight = 180;
	
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
				Message msg = arr[0]; //actually here is com.sun.mail.imap.IMAPMessage
				MailTextAndAttachmentsProcesser util = new MailTextAndAttachmentsProcesser();
				int size = Integer.parseInt(req.getParameter("fileSize"));
				String fileName = req.getParameter("fileName");
				String contentIdOrEmptyNotNullString = req.getParameter("contentIdOrEmptyNotNullString");
				Part part = util.getAttachmentPart(msg, size, fileName, contentIdOrEmptyNotNullString, false);
				if (part == null)
					out.print("Not found requested attachment in message"); // TODO: perhaps show image icon with erroror something else?
				else {
					boolean asThumbnail = Boolean.parseBoolean(req.getParameter("asThumbnail"));
					// TODO: this is huge inbound traffic. Perhaps it is better to cache this in DB? (or cache only if requested more than 1 times). (so we can have DB with records for each attachment, and count of accesses).
					// TODO: UNDONE: highly recommended to use local cache to store attachments and thumbnails to speedup download. ALso second feature: pre-download attachments and create thumbnails in background when mail is just appear at IMAP server.
					
					if(part.isMimeType("image/*")) {
						// return image or thumbnail
						
						if (asThumbnail) {
							// Here is image thumbnail
							if (size > MaxSizeOfOritinalImageToProcessIntoThumbnailInBytes) 
								out.print("Image is too big to crate thumbnail from it."); // TODO: show image icon via file type.
							else {
								ByteArrayOutputStream b = null;
								try {
									b = new ByteArrayOutputStream();
									writeBASE64PartContentIntoStream(part, b);
									byte[] byteArrWithImageContent = b.toByteArray();
									byte[] byteArrOfThumbnailImage =
											Thumbnailer.createThumbnail(byteArrWithImageContent, ThumbnailsWidth, ThumbnailsHeight, 70);
									if (byteArrOfThumbnailImage != null) {
										resp.setContentType(part.getContentType()); // TODO: possible place of error (if input image is png, output is jpeg? hm...)
										
										out.write(byteArrOfThumbnailImage);
									}
									else {
										out.print("Error converting image to thumbnail."); // TODO: perhaps show an "error" icon meaning that failed to get thumbnail from image. Or show icon of file type.
									}
								}
								finally {
									b.close();
								}
							}
						}
						else {
							// Here is full-size image
							resp.setContentType(part.getContentType());
							resp.setContentLength(size);
							
							boolean downloadMode = Boolean.parseBoolean(req.getParameter("downloadMode"));
							if (downloadMode) {
								resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
							}
							else 
								resp.setHeader( "Content-Disposition", "filename=\"" + fileName + "\"" );
							
							writeBASE64PartContentIntoStream(part, out);
						}
					}
					else {
						if (asThumbnail) {
							out.print("Not yet supported"); // TODO: (if need) if Thubmnail requested and filetype is an file, then show image via extension or an default image.
							// UNDONE: set mimeType of output stream.
						}
						else {
							// return whole file as-is
							resp.setContentType(part.getContentType());
							resp.setContentLength(size);
							resp.setHeader( "Content-Disposition", "attachment; filename=\"" + fileName + "\"" );
							
							writeBASE64PartContentIntoStream(part, out);
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

	/*
	 * Part: this should be an attachmnt (file or image).
	 */
	private void writeBASE64PartContentIntoStream(
			Part part, OutputStream writeToThisStream)
			throws IOException, MessagingException {
		InputStream stream = (InputStream)part.getContent(); // actually here is com.sun.mail.util.BASE64DecoderStream
		byte[] buf = new byte[1024];	
		
		while(true) {
			int readed = stream.read(buf, 0, buf.length);
			if (readed < 0)
				break;
			writeToThisStream.write(buf, 0, readed);
		}
	}
}
