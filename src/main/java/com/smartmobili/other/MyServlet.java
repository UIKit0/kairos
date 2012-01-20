package com.smartmobili.other;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.ServletException;
import java.io.*;
//import org.eclipse.jetty.websocket.*;

public class MyServlet extends HttpServlet {
/*	public WebSocket doWebSocketConnect(HttpServletRequest request, String protocol)
    {
        return null;//new ChatWebSocket();
    }*/
 /* protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
  	try
  	{
  		resp.getOutputStream().print("asdf");
  		resp.getOutputStream().flush();
  		Thread.sleep(2000);
  		resp.getOutputStream().print("qwer");
  	}
  	catch(Exception ex){}
  }*/


/*
Example 5-2. A servlet using persistent connections
http://docstore.mik.ua/orelly/java-ent/servlet/ch05_03.htm
*/
 /* public void doGet(HttpServletRequest req, HttpServletResponse res)
                               throws ServletException, IOException {

    res.setContentType("text/html");

    // Set up a PrintStream built around a special output stream
    ByteArrayOutputStream bytes = new ByteArrayOutputStream(1024);
    PrintWriter out = new PrintWriter(bytes, true);  // true forces flushing

    out.println("<HTML>");
    out.println("<HEAD><TITLE>Hello World</TITLE></HEAD>");
    out.println("<BODY>");
    out.println("<BIG>Hello World</BIG>");
    out.println("</BODY></HTML>");

    // Set the content length to the size of the buffer
    res.setContentLength(bytes.size());

    // Send the buffer
    bytes.writeTo(res.getOutputStream());
  }*/

/* public void doGet(HttpServletRequest req, HttpServletResponse res)
                               throws ServletException, IOException {

    res.setContentType("text/html");
    res.setHeader("Connection", "Keep-Alive");

    // Set up a PrintStream built around a special output stream
    int len1;
    {
    ByteArrayOutputStream bytes = new ByteArrayOutputStream(1024);
    PrintWriter out = new PrintWriter(bytes, true);  // true forces flushing

    out.println("<HTML>");
    out.println("<HEAD><TITLE>Hello World</TITLE></HEAD>");
    out.println("<BODY>");
    out.println("<BIG>Hello World</BIG>");
    //out.println("</BODY></HTML>");

    // Set the content length to the size of the buffer
    //res.setContentLength();
    len1 = bytes.size();

    // Send the buffer
    bytes.writeTo(res.getOutputStream());
    res.getOutputStream().flush();
	}
	try
	{
	Thread.sleep(3000);
	}catch(Exception ex){}
	{
    ByteArrayOutputStream bytes = new ByteArrayOutputStream(1024);
    PrintWriter out = new PrintWriter(bytes, true);  // true forces flushing

    //out.println("<HTML>");
    //out.println("<HEAD><TITLE>Hello World</TITLE></HEAD>");
    //out.println("<BODY>");
    out.println("<BIG>Hello World Two</BIG>");
    out.println("</BODY></HTML>");

    // Set the content length to the size of the buffer
    res.setContentLength(bytes.size() + len1);

    // Send the buffer
    bytes.writeTo(res.getOutputStream());
	}
  }*/

  protected void doGet(HttpServletRequest req, HttpServletResponse resp) {
    try
    {
      resp.getOutputStream().print("asdf");
    }
    catch(Exception ex){}
  }

  protected void doPost(HttpServletRequest req, HttpServletResponse resp) {
    try
    {
      resp.getOutputStream().print("qwer");
      // TODO: parse incoming command (one of functions is called from cappuccino, and need call one function here and pass parameters)
    }
    catch(Exception ex){}
  }
}
