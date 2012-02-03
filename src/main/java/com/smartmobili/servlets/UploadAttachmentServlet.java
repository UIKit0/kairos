/*
 *  UploadAttachmentServlet
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kzarinov.biz>
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

import org.apache.commons.fileupload.FileItemIterator;
import org.apache.commons.fileupload.FileItemStream;
import org.apache.commons.fileupload.FileUploadException;
import org.apache.commons.fileupload.servlet.ServletFileUpload;
 
@SuppressWarnings("serial")
public class UploadAttachmentServlet extends HttpServlet {
	private static final String DESTINATION_DIR_PATH ="/tmp";
	private File destinationDir;
 
	public void init(ServletConfig config) throws ServletException {
		super.init(config);
		
		destinationDir = new File(DESTINATION_DIR_PATH);
		if(!destinationDir.isDirectory()) {
			throw new ServletException(DESTINATION_DIR_PATH+" is not a directory");
		}
	}
 
	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) throws ServletException, IOException {
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
			//while (iter.hasNext()) {
				FileItemStream item = iter.next();
				String fileName = item.getName();
				InputStream streamOfFile = item.openStream();

				File file = new File(destinationDir, fileName);
				fos = new FileOutputStream(file);
				byte[] buf = new byte[1024];
				while (true) {
					int j = streamOfFile.read(buf);
					if (j < 0)
						break;
					fos.write(buf, 0, j);
				}
				System.out.println("Received file " + fileName);
			//}
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
		out.close();
	}
}