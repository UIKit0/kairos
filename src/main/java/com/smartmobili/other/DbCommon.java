/*
 *  DbCommon
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili.other;

import java.net.UnknownHostException;

import javax.servlet.ServletException;

import com.mongodb.DB;
import com.mongodb.Mongo;
import com.mongodb.MongoException;
import com.mongodb.gridfs.GridFS;

public class DbCommon {
	public static DB connectToAttachmentsDb() throws ServletException {
		Mongo m = null;
		try {
			m = new Mongo( "127.0.0.1" );
		} catch (UnknownHostException e) {
			e.printStackTrace();
			throw new ServletException("Error acessing DB. Err: " + e.toString());
		} catch (MongoException e) {
			e.printStackTrace();
			throw new ServletException("Error acessing DB. Err: " + e.toString());
		}
		
		return m.getDB( "mailComposingAttachmentsDb" );
	}
	
	public static GridFS getGridFSforAttachmentsFiles(DB db) {
		GridFS gfsFileAttachment = new GridFS(db, "attachmentsFiles");
		return gfsFileAttachment;
	}
}
