package com.smartmobili.other;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;

import javax.activation.DataSource;

import com.mongodb.gridfs.GridFSDBFile;

public class MongoDbImapDataSource implements DataSource {
	private String contentType;
	private String fileName;
	private GridFSDBFile file;
	
	public MongoDbImapDataSource(GridFSDBFile file, String contentType, String fileName) {
		this.contentType = contentType;
		this.fileName = fileName;
		this.file = file;
	}
	
	public String getContentType() {
		return this.contentType;
	}

	public InputStream getInputStream() throws IOException {
		
		//return this.inputStreamOfAttachmentFromDb;
		return file.getInputStream(); // TODO: // UNDONE: // THINK: is it closed somewhere by DataSource callers?
	}

	public String getName() {
		return this.fileName;
	}

	public OutputStream getOutputStream() throws IOException {
		throw new IOException("Outputting data is not supported in MongoDbImapDataSource.");
		//return null;
	}

	

}
