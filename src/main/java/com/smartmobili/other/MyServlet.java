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
			String functionParametersAsJsonString = (String) jsonObject
					.get("functionParameters");
			JSONObject functionParametersAsJsonObject = (JSONObject) JSONSerializer
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
