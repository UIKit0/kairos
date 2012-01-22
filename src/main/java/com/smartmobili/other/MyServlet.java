package com.smartmobili.other;

import javax.mail.*;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.*;
import java.lang.reflect.Method;
import java.util.Properties;
import org.apache.log4j.*;
import com.sun.mail.imap.IMAPFolder;
import net.sf.json.*;
//import org.eclipse.jetty.websocket.*;

@SuppressWarnings("serial")
public class MyServlet extends HttpServlet {
	final int SessionMaxInactiveInterval = 10*60;
	final boolean isDebuggingEnabled = true;
	final String mailHost = "mail.smartmobili.com"; // TODO: in future mail host perhaps will be user-editable setting, so this constant will be removed and in-place somewhere settings will be used.
	
	Logger log = Logger.getLogger(MyServlet.class);
/*	public WebSocket doWebSocketConnect(HttpServletRequest request, String protocol)
    {
        return null;//new ChatWebSocket();
    }*/

	protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
		try {
			resp.getOutputStream().print("Get method is not supported");
		} catch (Exception ex) {
		}
	}

	protected void doPost(HttpServletRequest request,
			HttpServletResponse response) {
		try {
			BufferedReader reader = request.getReader();
			StringBuilder sb = new StringBuilder();
			String line = reader.readLine();
			while (line != null) {
				sb.append(line + "\n");
				line = reader.readLine();
			}
			reader.close();
			String data = sb.toString();

			JSONObject jsonObject = (JSONObject) JSONSerializer.toJSON(data);
			String functionNameToCall = (String) jsonObject
					.get("functionNameToCall");
			String functionParametersAsJsonString = null;
			if (jsonObject.get("functionParameters") instanceof JSONNull == false)
				functionParametersAsJsonString = (String) jsonObject.get("functionParameters");
			JSONObject functionParametersAsJsonObject = null;
			if (functionParametersAsJsonString != null)
				functionParametersAsJsonObject = (JSONObject) JSONSerializer
					.toJSON(functionParametersAsJsonString);

			HttpSession session = request.getSession();
			session.setMaxInactiveInterval(SessionMaxInactiveInterval); // TODO: need to test, if between requests is more time, what application will do withoout all attributes from session? It should reload/re-request user login? Or silently reconnect with same credentials and continue to work (show folders and etc).

			Method method = MyServlet.class.getMethod(functionNameToCall,
					JSONObject.class, HttpSession.class);
			JSONObject res = (JSONObject) method.invoke(this,
					functionParametersAsJsonObject, session);

			response.getOutputStream().print(res.toString());
		} catch (Exception ex) {
			log.error("Exception in doPost()", ex);
			ex.printStackTrace(); 
		}
	}

	public JSONObject authenticate(JSONObject parameters, HttpSession session) {
		// We don't have our own DB and accounting system, we use IMAP system.
		/*
		 * NOTE: we don't cache authentication results (if it success) so each
		 * further call of "authenticate" with same session will still re-check
		 * credentials. In future need make TESTS/trace and if this
		 * "authenticate" is called several times during app run (not only at
		 * app start), then need to make same caching and re-check password only
		 * in intervals (e.g. one time per 2 hours).
		 */
		session.setAttribute("authenticationUserName",
				parameters.get("userName"));
		session.setAttribute("authenticationPassword",
				parameters.get("password"));
		

		// TODO: save opened IMAP connection to session. Later don't forget to
		// close it when session timeout expired, or used exited. (logged out).

		JSONObject res = new JSONObject();
		
		Store imapStore = imapConnect(session);
		if (imapStore != null) {
			res.put("status", "SMAuthenticationGranted");
			session.setAttribute("authenticatated", true);
			try
			{ imapStore.close(); }
			catch(Exception ex){}
		} else {
			res.put("status", "SMAuthenticationDenied");
			session.setAttribute("authenticatated", false);
		}	

		return res;
	}

	public JSONObject listMailfolders(JSONObject parameters, HttpSession httpSession) throws MessagingException {
		Store imapStore = imapConnect(httpSession); // TODO: get cached opened
													// and connected imapStore,
													// or reconnect.
		try {
			IMAPFolder defaultFolder = (IMAPFolder)imapStore.getDefaultFolder();
			Folder[] imapFolders = defaultFolder.list(); 

			// TODO: find way to speedup gettin attributes. Somekind of "fetch" for all folders from list. Perhaps "Fetch" command will work? If no, then split getting list of folder names and gettin folder attributes. And then in GUI first show list of folders, then show "loading" icon near each folder, and then load attributes for each folder in background, replacing loading icon with number of unread messages. Worse way: use some kind of cache, but it will show not actual information which can confuse user, and still we need show progress icon and reload attributes in background. So better way to not use cache.
			JSONArray jsonArrayOfFolders = new JSONArray();
			for (Folder f : imapFolders) {
				JSONObject folderAsJson = new JSONObject();
				folderAsJson.put("label", f.toString());// f.getFullName());
				folderAsJson.put("count", f.getMessageCount());
				folderAsJson.put("unread", f.getUnreadMessageCount());
				jsonArrayOfFolders.add(folderAsJson);
			}
			JSONObject result = new JSONObject();
			result.put("listOfFolders", jsonArrayOfFolders);
			return result;
		} finally {
			imapStore.close();
		}
	}
	
	
/* supporter functions */	
	

	public Store imapConnect(HttpSession httpSession) {
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
			store = imapSession.getStore("imap");
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
