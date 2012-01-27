/*
 *  ImapSession
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kzarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili;

import java.util.Properties;

import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.Store;
import javax.servlet.http.HttpSession;

public class ImapSession {
		
	final static boolean isDebuggingEnabled = true;
	final static String mailHost = "mail.smartmobili.com"; //"imap.gmail.com"; // TODO: in future mail host perhaps will be user-editable setting, so this constant will be removed and in-place somewhere settings will be used.
	final static String imapProtocol = "imap"; // "imaps"; 

	/*
	 * Return: NOTE: take care of closing returned value when it is no more needed by callid Store.close();
	 */
	public static Store imapConnect(HttpSession httpSession) {
		Store store = null;
		try {
			Properties props = new Properties();
			/*
			 * props.put("mail.imap.connectionpoolsize", imapConnectionPoolSize)
			 * props.put("mail.imap.connectionpooltimeout",
			 * imapConnectionPoolTimeout) props.put("mail.imap.timeout",
			 * imapTimeout) props.put("mail.imap.connectiontimeout",
			 * imapConnectionTimeout)
			 */

			final Session imapSession = Session.getDefaultInstance(props);
			imapSession.setDebug(isDebuggingEnabled);
			store = imapSession.getStore(imapProtocol);
			store.connect(
					/* credentials.host */mailHost,
					(String) httpSession.getAttribute("authenticationUserName"),
					(String) httpSession.getAttribute("authenticationPassword"));

			// TODO: in future save opened session and re-use it later always
			// (and re-connect if failed). and also disconnect somewhere when
			// session time-outed or logged-out (Need find place - perhaps add
			// thread which will check dead session via interval?)
			return store;
		} catch (MessagingException mex) {
			if (store != null) {
				try {
					if (store.isConnected())
						store.close();
				} catch (MessagingException e) {
					/*none*/
				}
			}
			return null;
		}
	}
}
