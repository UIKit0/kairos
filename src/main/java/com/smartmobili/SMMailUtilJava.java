/*
 *  SMMailUtilJava
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Contains portions of free code from Sun Microsystems, Inc.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

package com.smartmobili;

import javax.mail.*;
import javax.mail.internet.*;
import javax.mail.search.*;
import com.sun.mail.imap.*;
import java.io.*;
import java.net.URLEncoder;

class SMMailUtilJava {
	//private boolean textIsHtml = false;

	//public boolean isHtml = textIsHtml;

	/**
	 * Return the text content of the message.
	 * 
	 * TODO: perhaps not all cases is processed here. Perhaps need rewrite this function to clearly pass all cases of all kinds of emails.
	 */
	public String getText(String usedForLinkToAttachment_imapMailFolder, 
			String usedForLinkToAttachment_imapEmailId, Part p) throws MessagingException, IOException {
		if (p.isMimeType("text/*")) {
			String s = (String) p.getContent();
			boolean textIsHtml = p.isMimeType("text/html");
			if (textIsHtml == false) {
				s = s.replace("\n", "<br>"); // TODO: replace such kinds: [image: casesTest3.jpg]   to an link to attachment servlet. Use getAttachmentPart function with bool=true
				s = s.replace(" ", "&nbsp");
			}
			// System.out.println("It is text");
			return s;
		}
		if (p.isMimeType("multipart/alternative")) {
			// prefer html text over plain text
			Multipart mp = (Multipart) p.getContent();
			String text = null;
			// System.out.println("It is multipart alternative");
			for (int i = 0; i < mp.getCount(); i++) {
				Part part = mp.getBodyPart(i);
				String disposition = part.getDisposition();
				// System.out.println("Part #" + i + " " +part);
				// System.out.println("Disposition" + disposition);
				// Part is image, so save it
				if ((disposition != null)
						&& ((disposition.equals(Part.ATTACHMENT) || (disposition
								.equals(Part.INLINE))))) {
					// String filename = saveFile(part.getFileName(),
					// part.getInputStrea m());
					File f = saveFile(part.getFileName(), part.getInputStream()); // TODO:
					System.out.println(f.getPath());
					if (text == null)
						text = "(File " + part.getFileName() + " here. Not yet implemented attachements code).";// TODO
				} else if (disposition == null) {
					// Part is text
					Part bp = mp.getBodyPart(i);
					if (bp.isMimeType("text/plain")) {
						if (text == null)
							text = getText(usedForLinkToAttachment_imapMailFolder, usedForLinkToAttachment_imapEmailId, bp);
						continue;
					} else if (bp.isMimeType("text/html")) {
						String s = getText(usedForLinkToAttachment_imapMailFolder, usedForLinkToAttachment_imapEmailId, bp);
						if (s != null)
							return s;
					} else {
						return getText(usedForLinkToAttachment_imapMailFolder, usedForLinkToAttachment_imapEmailId, bp);
					}
				}
			}
			return text; 
		} else if (p.isMimeType("multipart/*")) {
			Multipart mp = (Multipart) p.getContent();
			String res = "";
			for (int i = 0; i < mp.getCount(); i++) {
				Part bp = mp.getBodyPart(i); 
				if (bp.isMimeType("text/*") || bp.isMimeType("multipart/alternative"))
					res = res + getText(usedForLinkToAttachment_imapMailFolder, 
							usedForLinkToAttachment_imapEmailId, bp);
				else if (bp.isMimeType("image/*")) {					
					// TODO: perhaps need also pass contentID to link, but always when I tested it was null. Here is code: IMAPBodyPart ibp = (IMAPBodyPart)bp;String contentId = ibp.getContentID();
				
					String imgCell = "<a href=\"" + 
							generateLinkToImage(bp, usedForLinkToAttachment_imapMailFolder, 
									usedForLinkToAttachment_imapEmailId, false) +
									"\" target=\"_blank\""+">" +
									"<img src=\"" + 
									generateLinkToImage(bp, usedForLinkToAttachment_imapMailFolder, 
											usedForLinkToAttachment_imapEmailId, true) + "\" />" +
									"</a>";
					String secondCell = "<b>" + bp.getFileName() + "</b>" + 
							"<br>" + 
							bp.getSize() + " bytes " + // TODO: convert to visible by human size e.g. K  MB and etc.		
							
							"<a href=\"" + 
							generateLinkToImage(bp, usedForLinkToAttachment_imapMailFolder, 
									usedForLinkToAttachment_imapEmailId, false) +
									"\" target=\"_blank\""+">" + "View</a>" /*+ 
							" <a href=\"" + 
									generateLinkToImage(bp, usedForLinkToAttachment_imapMailFolder, 
											usedForLinkToAttachment_imapEmailId, false) +"\">" + "Download</a>"*/;
					res = res + "<br>" +
							"<table border=\"0\" width=\"0%\"><tr><td width=\"0%\">" + 
							imgCell + "</td>" +
									"<td align=\"left\">" + secondCell + "</td></tr></table>";
				} else if (bp.isMimeType("message/rfc822")) {
					if (bp.getContent() instanceof IMAPNestedMessage) {
						IMAPNestedMessage msg = (IMAPNestedMessage)bp.getContent();
						// TODO: perhaps need to show also message header in-line?
						res = res + "<HR>" + getText(usedForLinkToAttachment_imapMailFolder, 
								usedForLinkToAttachment_imapEmailId, msg);;
					}
					else
						res = res + "Unknown type: " + bp.getContent(); // TODO: could this happen?
				}
				else
					res = res + "<br>Unknown file type (" + bp.getFileName() + ") (" + bp.getContentType() + ")"; // TODO:
			}
			if (res.length() == 0)
				res = null;
			return res;
		} 
		return null;
	}

	/*
	 * generateLinkToImage function. 
	 * Author: Victor Kazarinov <oobe@kazarinov.biz>
	 * 
	 * Creates link to ImapAttachmentsServlet and passing all parameters to unique 
	 * identificate folder, message and attachment in message
	 */
	private String generateLinkToImage(Part bp, 
			String usedForLinkToAttachment_imapMailFolder,
			String usedForLinkToAttachment_imapEmailId, 
			boolean asThumbnail) 
					throws UnsupportedEncodingException, MessagingException {
		String encodedId = URLEncoder.encode(usedForLinkToAttachment_imapEmailId, "UTF8") ;
		return "getAttachment" + 
				//"?hash=" + bp.hashCode() + 
				"?fileSize=" + bp.getSize() +
				"&imapFolder=" + URLEncoder.encode(usedForLinkToAttachment_imapMailFolder, "UTF8") + 
				"&imapMailId=" + encodedId + 
				"&fileName=" + URLEncoder.encode(bp.getFileName(), "UTF8") + 
				"&asThumbnail=" + String.valueOf(asThumbnail);
	}

	/*
	 * getAttachmentPart function. 
	 * Author: Victor Kazarinov <oobe@kazarinov.biz>
	 * 
	 * Searches in Part (p) the (sub)part satisfied the conditions such as size and fileName.
	 * Return null if part is not found.
	 */
	Part getAttachmentPart(Part p, int size, String fileName, boolean findOnlyUsingFileName)
			throws MessagingException {
		if (findOnlyUsingFileName) {
			if (p.getFileName() != null)
			if (fileName.contentEquals(p.getFileName()))
				return p;
		} else {
			if (p.getFileName() != null)
				if (fileName.contentEquals(p.getFileName()))
					if (p.getSize() == size)
						return p;
		}
		Object contentObj = null;
		try {
			contentObj = p.getContent();
		} catch (Exception ex) { /* nothing */ }
		if (contentObj != null)
			if (contentObj instanceof Multipart) {
				Multipart mp = (Multipart) contentObj;
				for (int i = 0; i < mp.getCount(); i++) {
					Part subPart = mp.getBodyPart(i);
					Part res = getAttachmentPart(subPart, size, fileName, findOnlyUsingFileName);
					if (res != null)
						return res;
				}
			}
		return null;
	}

	
	// private String saveFile(String filename, InputStream in) throws
	// IOException, FileNotFoundException{
	// File file = new File(filename);
	// for (int i = 0; file.exists(); i++) {
	// file = new File(filename+i);
	// }
	//
	// OutputStream out = new BufferedOutputStream(new FileOutputStream(file));
	//
	// // We can't just use p.writeTo( ) here because it doesn't
	// // decode the attachment. Instead we copy the input stream
	// // onto the output stream which does automatically decode
	// // Base-64, quoted printable, and a variety of other formats.
	//
	// //InputStream in = new BufferedInputStream(p.getInputStream( ));
	// int b;
	// while ((b = in.read()) != -1) out.write(b);
	// out.flush();
	// out.close();
	// //in.close();
	// return filename;
	// }

	public static void handleMultipart_UNUSED(Multipart multipart)
			throws MessagingException, IOException {
		for (int i = 0, n = multipart.getCount(); i < n; i++) {
			handlePart(multipart.getBodyPart(i));
		}
	}

	public static void handlePart(Part part) throws MessagingException,
			IOException {
		String disposition = part.getDisposition();
		String contentType = part.getContentType();
		if (disposition == null) { // When just body
			System.out.println("Null: " + contentType);
			// Check if plain
			if ((contentType.length() >= 10)
					&& (contentType.toLowerCase().substring(0, 10)
							.equals("text/plain"))) {
				part.writeTo(System.out);
			} else { // Don't think this will happen
				System.out.println("Other body: " + contentType);
				part.writeTo(System.out);
			}
		} else if (disposition.equalsIgnoreCase(Part.ATTACHMENT)) {
			System.out.println("Attachment: " + part.getFileName() + " : "
					+ contentType);
			saveFile(part.getFileName(), part.getInputStream());
		} else if (disposition.equalsIgnoreCase(Part.INLINE)) {
			System.out.println("Inline: " + part.getFileName() + " : "
					+ contentType);
			saveFile(part.getFileName(), part.getInputStream());
		} else { // Should never happen
			System.out.println("Other: " + disposition);
		}
	}

	public static File saveFile(String filename, InputStream input)
			throws FileNotFoundException, IOException {

		File file = new File(filename);
		if (true)
			return file; // Disabled saveFile by Oobe (Victor Kazarinov). Seems
							// like this is for tests or to show images from
							// server directly in web-app. Instead, we should
							// pass full images inside message to client (this
							// will work slow), or provide IDs of parts and let
							// client first show text content and then download
							// in background images and other attachments if
							// need.
		for (int i = 0; file.exists(); i++) {
			file = new File(filename + i);
		}
		FileOutputStream fos = new FileOutputStream(file);
		BufferedOutputStream bos = new BufferedOutputStream(fos);

		BufferedInputStream bis = new BufferedInputStream(input);
		int aByte;
		while ((aByte = bis.read()) != -1) {
			bos.write(aByte);
		}
		bos.flush();
		bos.close();
		bis.close();
		return file;
	}
}