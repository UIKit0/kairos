/*
 *  CurrentComposingEmailProperties
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 *  
 */

package com.smartmobili.httpSessionAttributes;

import java.util.ArrayList;
import java.util.UUID;
import javax.servlet.http.HttpSession;
import org.bson.types.ObjectId;

import com.smartmobili.other.MailTextAndAttachmentsProcesser.AttachmentInMessageProperties;

public class CurrentComposingEmailProperties {
	public class OneAttachmentProperty
	{
		private boolean thisAttachmentFromExistingImapMessage;
		
		// id of attachment in DB
		private ObjectId dbAttachmentId;
		
		private String webServerAttachmentId;
		private String fileName;
		private long sizeInBytes;
		private String contentType;

		// id of attachment from imap
		public String imapAttachmentId_folderInWhichMessage;
		public String imapAttachmentId_emailId;
		public String imapAttachment_linkToGetThumbnail;
		public String imapAttachment_linkToGetFullsize;

		public String getImapAttachmentId_folderInWhichMessage() {
			return imapAttachmentId_folderInWhichMessage;
		}

		public void setImapAttachmentId_folderInWhichMessage(
				String imapAttachmentId_folderInWhichMessage) {
			this.imapAttachmentId_folderInWhichMessage = imapAttachmentId_folderInWhichMessage;
		}

		public String getImapAttachmentId_emailId() {
			return imapAttachmentId_emailId;
		}

		public void setImapAttachmentId_emailId(String imapAttachmentId_emailId) {
			this.imapAttachmentId_emailId = imapAttachmentId_emailId;
		}
			
		public String getImapAttachment_linkToGetThumbnail() {
			return imapAttachment_linkToGetThumbnail;
		}

		public void setImapAttachment_linkToGetThumbnail(
				String imapAttachment_linkToGetThumbnail) {
			this.imapAttachment_linkToGetThumbnail = imapAttachment_linkToGetThumbnail;
		}

		public String getImapAttachment_linkToGetFullsize() {
			return imapAttachment_linkToGetFullsize;
		}

		public void setImapAttachment_linkToGetFullsize(
				String imapAttachment_linkToGetFullsize) {
			this.imapAttachment_linkToGetFullsize = imapAttachment_linkToGetFullsize;
		}

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

		public String getWebServerAttachmentId() {
			return webServerAttachmentId;
		}

		public void setWebServerAttachmentId(String webServerAttachmentId) {
			this.webServerAttachmentId = webServerAttachmentId;
		}
		
		public String getContentType() {
			return contentType;
		}

		public void setContentType(String contentType) {
			this.contentType = contentType;
		}
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
	
	public static void clearItFromSession(HttpSession httpSession) {
		httpSession.removeAttribute("currentComposingEmail");
	}

	public void newAttachmentAddedToTheDb(ObjectId dbAttachmentId, long sizeInBytes, String fileName,
			String contentType) {
		synchronized (listOfAttachmentProperties_useSynchronized) {
			OneAttachmentProperty oap = new OneAttachmentProperty();
			oap.thisAttachmentFromExistingImapMessage = false;
			oap.dbAttachmentId = dbAttachmentId;
			
			oap.webServerAttachmentId = UUID.randomUUID().toString();
			
			oap.sizeInBytes = sizeInBytes;
			oap.fileName = fileName;
			oap.contentType = contentType;
			
			listOfAttachmentProperties_useSynchronized.add(oap);
		}
	}

	// NOTE: elements is not copied, only reference to it is used.
	public ArrayList<OneAttachmentProperty> getCopyOfListOfAttachments() {		
		synchronized(listOfAttachmentProperties_useSynchronized) {
			@SuppressWarnings("unchecked")
			ArrayList<OneAttachmentProperty> clone = 
					(ArrayList<OneAttachmentProperty>)listOfAttachmentProperties_useSynchronized.clone();
			return clone;
		}
	}

	public boolean deleteAttachment(String webServerAttachmentIdToDelete) {
		synchronized(listOfAttachmentProperties_useSynchronized) {
			OneAttachmentProperty foundOap = null;
			for(OneAttachmentProperty oap : listOfAttachmentProperties_useSynchronized) {
				if (oap.webServerAttachmentId.contentEquals(webServerAttachmentIdToDelete)) {
					foundOap = oap;
					break;
				}
			}
			if (foundOap != null) {
				listOfAttachmentProperties_useSynchronized.remove(foundOap);
				return true;
			}
			else
				return false;
		}
	}

	public OneAttachmentProperty getAttachmentProperty(
			String webServerAttachmentId) {
		synchronized(listOfAttachmentProperties_useSynchronized) {
			for(OneAttachmentProperty oap : listOfAttachmentProperties_useSynchronized) {
				if (oap.webServerAttachmentId.contentEquals(webServerAttachmentId)) {
					return oap;
				}
			}
		}
		return null;
	}

	public void insertImapAttachment(AttachmentInMessageProperties aim) {
		synchronized (listOfAttachmentProperties_useSynchronized) {
			OneAttachmentProperty oap = new OneAttachmentProperty();
			oap.thisAttachmentFromExistingImapMessage = true;
			//oap.dbAttachmentId = dbAttachmentId;
			oap.imapAttachmentId_folderInWhichMessage = aim.imapEmailFolder;
			oap.imapAttachmentId_emailId = aim.imapEmailId;
						
			oap.webServerAttachmentId = UUID.randomUUID().toString();
			
			oap.sizeInBytes = aim.fileSize;
			oap.fileName = aim.fileName;
			oap.contentType = aim.contentType;
			
			oap.imapAttachment_linkToGetFullsize = aim.linkToServletToDownloadFullSize;
			oap.imapAttachment_linkToGetThumbnail = aim.linkToServletToDownloadThumbnail;
			
			listOfAttachmentProperties_useSynchronized.add(oap);
		}
	}
}
