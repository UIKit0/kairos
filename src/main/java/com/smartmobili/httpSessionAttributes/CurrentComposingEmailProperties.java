package com.smartmobili.httpSessionAttributes;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.UUID;

import javax.servlet.http.HttpSession;

import org.bson.types.ObjectId;


public class CurrentComposingEmailProperties {
	public class OneAttachmentProperty
	{
		/**
		 * 
		 */
		//private static final long serialVersionUID = 1633908922694616566L;

		public boolean thisAttachmentFromExistingImapMessage;
		// id of attachment from imap
		// UNDONE:
		
		// id of attachment in DB
		public ObjectId dbAttachmentId;
		public boolean isThisAttachmentFromExistingImapMessage() {
			return thisAttachmentFromExistingImapMessage;
		}

		public void setThisAttachmentFromExistingImapMessage(
				boolean thisAttachmentFromExistingImapMessage) {
			this.thisAttachmentFromExistingImapMessage = thisAttachmentFromExistingImapMessage;
		}

		public ObjectId getDbAttachmentId() {
			return dbAttachmentId;
		}

		public void setDbAttachmentId(ObjectId dbAttachmentId) {
			this.dbAttachmentId = dbAttachmentId;
		}

		public String getFileName() {
			return fileName;
		}

		public void setFileName(String fileName) {
			this.fileName = fileName;
		}

		public long getSizeInBytes() {
			return sizeInBytes;
		}

		public void setSizeInBytes(long sizeInBytes) {
			this.sizeInBytes = sizeInBytes;
		}

		public String webServerAttachmentId;
		public String getWebServerAttachmentId() {
			return webServerAttachmentId;
		}

		public void setWebServerAttachmentId(String webServerAttachmentId) {
			this.webServerAttachmentId = webServerAttachmentId;
		}

		public String fileName;

		public long sizeInBytes;
	}
	
	boolean currentlyEditingAnExistingImapMessage;
	String currentlyEditingAnExistingImapMessageFolder;
	String currentlyEditingAnExistingImapMessageId;
	
	ArrayList<OneAttachmentProperty> listOfAttachmentProperties_useSynchronized = 
			new ArrayList<CurrentComposingEmailProperties.OneAttachmentProperty>();
	
	public String getCurrentlyEditingAnExistingImapMessageId() {
		return currentlyEditingAnExistingImapMessageId;
	}

	public void setCurrentlyEditingAnExistingImapMessageId(
			String currentlyEditingAnExistingImapMessageId) {
		this.currentlyEditingAnExistingImapMessageId = currentlyEditingAnExistingImapMessageId;
	}

	public String getCurrentlyEditingAnExistingImapMessageFolder() {
		return currentlyEditingAnExistingImapMessageFolder;
	}

	public void setCurrentlyEditingAnExistingImapMessageFolder(
			String currentlyEditingAnExistingImapMessageFolder) {
		this.currentlyEditingAnExistingImapMessageFolder = currentlyEditingAnExistingImapMessageFolder;
	}

	public boolean isCurrentlyEditingAnExistingImapMessage() {
		return currentlyEditingAnExistingImapMessage;
	}

	public void setCurrentlyEditingAnExistingImapMessage(
			boolean currentlyEditingAnExistingImapMessage) {
		this.currentlyEditingAnExistingImapMessage = currentlyEditingAnExistingImapMessage;
	}
	
	/*
	 * Singleton for CurrentComposingEmailProperties attribute for current http
	 * session.
	 */
	public static CurrentComposingEmailProperties getFromHttpSessionOrCreateNewDefaultInIt(
			HttpSession httpSession) {
		Object obj = httpSession.getAttribute("currentComposingEmail");
		CurrentComposingEmailProperties res = null;
		if (obj == null) {
			res = new CurrentComposingEmailProperties();
			httpSession.setAttribute("currentComposingEmail", res);
		}
		else
			res = (CurrentComposingEmailProperties) obj;
		return res;
	}

	public void newAttachmentAddedToTheDb(ObjectId dbAttachmentId, long sizeInBytes, String fileName) {
		synchronized (listOfAttachmentProperties_useSynchronized) {
			OneAttachmentProperty oap = new OneAttachmentProperty();
			oap.thisAttachmentFromExistingImapMessage = false;
			oap.dbAttachmentId = dbAttachmentId;
			
			oap.webServerAttachmentId = UUID.randomUUID().toString();
			
			oap.sizeInBytes = sizeInBytes;
			oap.fileName = fileName;
			
			listOfAttachmentProperties_useSynchronized.add(oap);
		}
	}

	// NOTE: elements is not copyied, only reference to it is used.
	public ArrayList<OneAttachmentProperty> getCopyOfListOfAttachments() {
		/*ArrayList<OneAttachmentProperty> res
		synchronized (listOfAttachmentProperties_useSynchronized) {
			for(OneAttachmentProperty oap : listOfAttachmentProperties_useSynchronized) {
				
			}
		} */
		@SuppressWarnings("unchecked")
		ArrayList<OneAttachmentProperty> clone = (ArrayList<OneAttachmentProperty>)listOfAttachmentProperties_useSynchronized.clone();
		return clone;
	}
}
