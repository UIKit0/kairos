import org.mortbay.jetty.Connector;
import org.mortbay.jetty.Server;
import org.mortbay.jetty.webapp.WebAppContext;
import org.mortbay.jetty.nio.*;

public class RunWebApp {

	/**
	 * @param args
	 */
	public static void main(String[] args) {
		Server server = new Server(8080);
		SelectChannelConnector scc = new SelectChannelConnector();

		scc.setPort(8080);
		server.setConnectors(new Connector[] { scc });

		WebAppContext context = new WebAppContext();
		context.setServer(server);
		context.setContextPath("/");
		context.setWar("src/main/webapp"); 
		// here. Need google on jetty and setWar function.
		server.addHandler(context);

		try {
			System.out
					.println(">>> STARTING EMBEDDED JETTY SERVER, PRESS ANY KEY TO STOP");
			server.start();
			while (System.in.available() == 0) {
				Thread.sleep(5000);
			}
			server.stop();
			server.join();
		} catch (Exception exc) {

			exc.printStackTrace();
			System.exit(100);

		}
	}

}
