/*
 *  UploadAttachmentServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 *  
 *  Partially based on example from : http://commons.apache.org/fileupload/streaming.html 
 */

package com.smartmobili.servlets;


import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.PrintWriter;
 
import javax.servlet.ServletConfig;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.apache.commons.fileupload.FileItemIterator;
import org.apache.commons.fileupload.FileItemStream;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
import org.bson.types.ObjectId;

import com.mongodb.DB;
import com.mongodb.gridfs.GridFS;
import com.mongodb.gridfs.GridFSInputFile;
import com.smartmobili.httpSessionAttributes.CurrentComposingEmailProperties;
import com.smartmobili.other.DbCommon;
 
@SuppressWarnings("serial")
public class UploadAttachmentServlet extends HttpServlet {
	private static final String DESTINATION_DIR_PATH ="/tmp";
	private File destinationDir;
 
	DB db;
	
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		
		destinationDir = new File(DESTINATION_DIR_PATH);
		if(!destinationDir.isDirectory()) {
			throw new ServletException(DESTINATION_DIR_PATH+" is not a directory");
		}
		
		this.db = DbCommon.connectToAttachmentsDb();
	}
 
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
		// TODO: UNDONE: check if current session is valid (using saved IMAPsession?). It should not allow to send for not-authorized users!
		HttpSession httpSession = request.getSession();
		
		// Create a new file upload handler
		ServletFileUpload upload = new ServletFileUpload();

		// Parse the request
		FileItemIterator iter = null;
		try {
			iter = upload.getItemIterator(request);
		} catch (FileUploadException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		FileOutputStream fos = null;
		try {
			FileItemStream item = iter.next();
			String fileName = item.getName();
			String contentType = item.getContentType();
			
			InputStream streamOfFile = item.openStream();

			GridFS gfsFileAttachment = DbCommon.getGridFSforAttachmentsFiles(this.db);
			
			GridFSInputFile gfsIf = gfsFileAttachment.createFile(streamOfFile);
			gfsIf.setFilename(fileName);
			gfsIf.save();
			long fileSize = gfsIf.getLength();
			ObjectId id = (ObjectId) gfsIf.getId();

			CurrentComposingEmailProperties
					.getFromHttpSessionOrCreateNewDefaultInIt(httpSession)
					.newAttachmentAddedToTheDb(id, fileSize, fileName, contentType);

			// TODO: think and make removing attachments not associated with any
			// session (e.g. cleanup) somewhere (not here) in code of
			// web-server!

			System.out.println("Received file " + fileName);
		} catch (FileUploadException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		finally {
			if (fos != null)
				fos.close();
		}

		PrintWriter out = response.getWriter();
		response.setContentType("text/plain");
		out.println("File Upload OK");
		out.println();
		//out.close();
	}
}