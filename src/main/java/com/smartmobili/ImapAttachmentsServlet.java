/*
 *  ImapAttachmentsServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kzarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili;

import java.awt.*;
import java.awt.image.BufferedImage;
import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.OutputStream;
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

import com.sun.image.codec.jpeg.JPEGCodec;
import com.sun.image.codec.jpeg.JPEGEncodeParam;
import com.sun.image.codec.jpeg.JPEGImageEncoder;
import com.sun.mail.imap.IMAPMessage;
import com.sun.mail.util.BASE64DecoderStream;


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
				IMAPMessage msg = (IMAPMessage)arr[0];
				SMMailUtilJava util = new SMMailUtilJava();
				int size = Integer.parseInt(req.getParameter("fileSize"));
				String fileName = req.getParameter("fileName");
				Part part = util.getAttachmentPart(msg, size, fileName, false);
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
										createThumbnail(byteArrWithImageContent, ThumbnailsWidth, ThumbnailsHeight, 70);
									if (byteArrOfThumbnailImage != null) {
										resp.setContentType(part.getContentType());
										resp.setContentLength(size);
										
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
							
							writeBASE64PartContentIntoStream(part, out);
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
							// USE writeBASE64PartContentIntoStream
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

	/*
	 * Part: this should be an attachmnt (file or image).
	 */
	private void writeBASE64PartContentIntoStream(
			Part part, OutputStream writeToThisStream)
			throws IOException, MessagingException {
		BASE64DecoderStream stream = (BASE64DecoderStream)part.getContent();
		byte[] buf = new byte[1024];	
		
		while(true) {
			int readed = stream.read(buf, 0, buf.length);
			if (readed < 0)
				break;
			writeToThisStream.write(buf, 0, readed);
		}
	}
	
	/*
	 * 
	 * This function is based on code to create thumbnail from code snipped from here: 
	 * http://viralpatel.net/blogs/2009/05/20-useful-java-code-snippets-for-java-developers.html
	 * 
	 * This function can be rewrited to directly save data to output stream. This will require less memory 
	 * (no buffer-in-a-middle), but it will be not possible to show an error icon for user if
	 * something will goes wrong
	 * 
	 * TODO: check this function for memory leaks.
	 * 
	 * Returns byte array of result thumbnail image or null if some error occured.
	 */
	private byte[] createThumbnail(byte[] sourceImage, int thumbWidth,
			int thumbHeight, int quality) throws InterruptedException,
			IOException {
		// load image from filename
		Image image = Toolkit.getDefaultToolkit().createImage(sourceImage);
		// Image image = Toolkit.getDefaultToolkit().getImage(filename);
		MediaTracker mediaTracker = new MediaTracker(new Container());
		mediaTracker.addImage(image, 0);
		mediaTracker.waitForID(0);

		// use this to test for errors at this point:
		// System.out.println(mediaTracker.isErrorAny());
		if (mediaTracker.isErrorAny())
			return null;

		// determine thumbnail size from WIDTH and HEIGHT
		double thumbRatio = (double) thumbWidth / (double) thumbHeight;
		int imageWidth = image.getWidth(null);
		int imageHeight = image.getHeight(null);
		double imageRatio = (double) imageWidth / (double) imageHeight;
		if (thumbRatio < imageRatio) {
			thumbHeight = (int) (thumbWidth / imageRatio);
		} else {
			thumbWidth = (int) (thumbHeight * imageRatio);
		}

		// draw original image to thumbnail image object and
		// scale it to the new size on-the-fly
		Graphics2D graphics2D = null;
		BufferedImage thumbImage = null;
		try {
			thumbImage = new BufferedImage(thumbWidth, thumbHeight,
				BufferedImage.TYPE_INT_RGB);
			graphics2D = thumbImage.createGraphics();
			graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
				RenderingHints.VALUE_INTERPOLATION_BILINEAR);
			graphics2D.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);
		}
		catch (Exception ex) {
			return null;
		}
		finally {
			graphics2D.dispose();
		}

		// save thumbnail image
		ByteArrayOutputStream b = null;
		try {
			b = new ByteArrayOutputStream();

			JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(b);
			JPEGEncodeParam param = encoder
					.getDefaultJPEGEncodeParam(thumbImage);
			quality = Math.max(0, Math.min(quality, 100));
			param.setQuality((float) quality / 100.0f, false);
			encoder.setJPEGEncodeParam(param);
			encoder.encode(thumbImage);

			return b.toByteArray();
		} catch (Exception ex) {
			return null;
		} finally {
			b.close();
		}
	}
}
