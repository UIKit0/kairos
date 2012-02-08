/*
 *  MailComposingGetAttachmentServlet
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

import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.mongodb.DB;
import com.mongodb.gridfs.GridFS;
import com.mongodb.gridfs.GridFSDBFile;
import com.smartmobili.httpSessionAttributes.CurrentComposingEmailProperties;
import com.smartmobili.httpSessionAttributes.CurrentComposingEmailProperties.OneAttachmentProperty;
import com.smartmobili.other.DbCommon;
import com.smartmobili.other.Thumbnailer;

@SuppressWarnings("serial")
public class MailComposingGetAttachmentServlet extends HttpServlet {
	final static int MaxSizeOfOritinalImageToProcessIntoThumbnailInBytes = 6 * 1024 * 1024; // 6
																							// Mb

	final static int ThumbnailsWidth = 180;
	final static int ThumbnailsHeight = 180;

	DB db;

	public void init(ServletConfig config) throws ServletException {
		super.init(config);

		this.db = DbCommon.connectToAttachmentsDb();
	}

	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException {
		String webServerAttachmentId = req
				.getParameter("webServerAttachmentId");

		boolean downloadMode = false;
		if (req.getParameter("downloadMode") != null)
			downloadMode = Boolean.parseBoolean(req
					.getParameter("downloadMode"));

		boolean asThumbnail = false;
		if (req.getParameter("asThumbnail") != null)
			asThumbnail = Boolean.parseBoolean(req.getParameter("asThumbnail"));

		// Check if session is valid and requested attachment id is in this
		// session.
		// TODO: this is possible place for hack - some-one can brute-force here
		// sessions ids and attachments ids and get attachments of foreign
		// users!

		CurrentComposingEmailProperties ep = CurrentComposingEmailProperties
				.getFromHttpSessionOrCreateNewDefaultInIt(req.getSession());

		OneAttachmentProperty oap = ep
				.getAttachmentProperty(webServerAttachmentId);
		if (oap == null) {
			// Here is timeout to reduce brute-forcing session ids where is
			// valid attachment id and get foreign attachment ID. But it is
			// still possible to do from multiple threads. DDOS attack can
			// overload server with this. (it will be possible to fast reach
			// limit of maximum sessions per server).
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				throw new ServletException("InterruptedException was thrown.");
			}
			throw new ServletException("Wrong attachment Id.");
		}

		ServletOutputStream out = null;
		try {
			out = resp.getOutputStream();
		} catch (IOException e2) {
			/* nothing */
		}

		if (oap.isThisAttachmentFromExistingImapMessage() == false) {
			GridFS attachmentsFilesGridFs = DbCommon
					.getGridFSforAttachmentsFiles(this.db);

			GridFSDBFile dbFile = attachmentsFilesGridFs.find(oap.getDbAttachmentId());
			

			try {
				// TODO: this is huge inbound traffic. Perhaps it is better to
				// cache
				// this in DB? (or cache only if requested more than 1 times).
				// (so
				// we can have DB with records for each attachment, and count of
				// accesses).
				// TODO: UNDONE: highly recommended to use local cache to store
				// attachments and thumbnails to speedup download. ALso second
				// feature: pre-download attachments and create thumbnails in
				// background when mail is just appear at IMAP server.

				if (oap.getContentType().startsWith("image")) {
					// return image or thumbnail

					if (asThumbnail) {
						// Here is image thumbnail
						if (oap.getSizeInBytes() > MaxSizeOfOritinalImageToProcessIntoThumbnailInBytes)
							// TODO: show image icon via file type.
							out.print("Image is too big to crate thumbnail from it.");
						else {
							ByteArrayOutputStream b = null;
							try {
								b = new ByteArrayOutputStream();
								writeDBFileContentIntoStream(dbFile, b);
								byte[] byteArrWithImageContent = b
										.toByteArray();
								byte[] byteArrOfThumbnailImage = Thumbnailer.createThumbnail(
										byteArrWithImageContent,
										ThumbnailsWidth, ThumbnailsHeight, 70);
								if (byteArrOfThumbnailImage != null) {
									resp.setContentType(oap.getContentType()); // TODO:
																				// possible
																				// place
																				// of
																				// error
																				// (if
																				// input
																				// image
																				// is
																				// png,
																				// output
																				// is
																				// jpeg?
																				// hm...)

									out.write(byteArrOfThumbnailImage);
								} else {
									out.print("Error converting image to thumbnail."); // TODO:
																						// perhaps
																						// show
																						// an
																						// "error"
																						// icon
																						// meaning
																						// that
																						// failed
																						// to
																						// get
																						// thumbnail
																						// from
																						// image.
																						// Or
																						// show
																						// icon
																						// of
																						// file
																						// type.
								}
							} finally {
								b.close();
							}
						}
					} else {
						// Here is full-size image
						resp.setContentType(oap.getContentType());
						resp.setContentLength((int) oap.getSizeInBytes());

						if (downloadMode) {
							resp.setHeader(
									"Content-Disposition",
									"attachment; filename=\""
											+ oap.getFileName() + "\"");
						} else
							resp.setHeader("Content-Disposition", "filename=\""
									+ oap.getFileName() + "\"");

						writeDBFileContentIntoStream(dbFile, out);
					}
				} else {
					if (asThumbnail) {
						out.print("Not yet supported"); // TODO: (if need) if
														// Thubmnail requested
														// and
														// filetype is an file,
														// then
														// show image via
														// extension
														// or an default image.
						// UNDONE: set mimeType of output stream.
					} else {
						// return whole file as-is
						resp.setContentType(oap.getContentType());
						resp.setContentLength((int) oap.getSizeInBytes());
						resp.setHeader("Content-Disposition",
								"attachment; filename=\"" + oap.getFileName()
										+ "\"");

						writeDBFileContentIntoStream(dbFile, out);
					}
				}

			} catch (Exception e) {
				// TODO:
				try {
					out.print("Exception");
				} catch (IOException e1) {
					// TODO Auto-generated catch block
					e1.printStackTrace();
				}
			}
		} else {
			// TODO: get attachment using sharing code from
			// ImapAttachmentsServlet
			throw new ServletException(
					"Attachments from IMAP is not yet supported");
		}
	}
	
	private void writeDBFileContentIntoStream(
			GridFSDBFile file, OutputStream writeToThisStream) throws IOException {
		InputStream stream = (InputStream)file.getInputStream(); // actually here is com.sun.mail.util.BASE64DecoderStream
		byte[] buf = new byte[1024];	
		
		while(true) {
			int readed = stream.read(buf, 0, buf.length);
			if (readed < 0)
				break;
			writeToThisStream.write(buf, 0, readed);
		}
	}
}
