/*
 *  SMMailUtilJava
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Contains portions of free code from Sun Microsystems, Inc.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */
 
package com.smartmobili.service;

import javax.mail.*;
import javax.mail.internet.*;
import javax.mail.search.*;
import com.sun.mail.imap.*;
import java.io.*;

class SMMailUtilJava {
  private boolean textIsHtml = false;

  public boolean isHtml = textIsHtml;

  /**
   * Return the primary text content of the message.
   */
  public String getText(Part p) throws MessagingException, IOException {  	
      if (p.isMimeType("text/*")) {
          String s = (String)p.getContent();
          textIsHtml = p.isMimeType("text/html");
          //System.out.println("It is text");
          return s;
      }
      if (p.isMimeType("multipart/alternative")) {
          // prefer html text over plain text
          Multipart mp = (Multipart)p.getContent();
          String text = null;
          //System.out.println("It is multipart alternative");
          for (int i = 0; i < mp.getCount(); i++) {
            Part part = mp.getBodyPart(i);
						String disposition = part.getDisposition();
            // System.out.println("Part #" + i + " " +part);
            // System.out.println("Disposition" + disposition);
							  // Part is image, so save it
						if ((disposition != null) &&
						    ((disposition.equals(Part.ATTACHMENT) || (disposition.equals(Part.INLINE))))) {
						    //String filename = saveFile(part.getFileName(), part.getInputStream());
						    File f = saveFile(part.getFileName(), part.getInputStream());
                System.out.println(f.getPath());						    
						  } else if (disposition == null) {
								// Part is text
                Part bp = mp.getBodyPart(i);
                if (bp.isMimeType("text/plain")) {
                    if (text == null)
                        text = getText(bp);
                    continue;
                } else if (bp.isMimeType("text/html")) {
                    String s = getText(bp);
                    if (s != null)
                        return s;
                } else {
                    return getText(bp);
                }
              }
          }
          return text;
      } else if (p.isMimeType("multipart/*")) {
        Multipart mp = (Multipart)p.getContent();
        for (int i = 0; i < mp.getCount(); i++) {                        
          String s = getText(mp.getBodyPart(i));	
          if (s != null)
            return s;			  
          }
      }
      return null;
  }

  // private String saveFile(String filename, InputStream in) throws IOException, FileNotFoundException{
  //  File file = new File(filename);
  //  for (int i = 0; file.exists(); i++) {
  //    file = new File(filename+i);
  //  }
  //  
  //  OutputStream out = new BufferedOutputStream(new FileOutputStream(file));
  // 
  //     // We can't just use p.writeTo( ) here because it doesn't
  //     // decode the attachment. Instead we copy the input stream 
  //     // onto the output stream which does automatically decode
  //     // Base-64, quoted printable, and a variety of other formats.
  // 
  //     //InputStream in = new BufferedInputStream(p.getInputStream( ));
  //     int b;
  //     while ((b = in.read()) != -1) out.write(b); 
  //     out.flush();
  //     out.close();
  //     //in.close();
  //     return filename;
  // }
	
	public static void handleMultipart(Multipart multipart) throws MessagingException, IOException {
    for (int i=0, n=multipart.getCount(); i<n; i++) {
      handlePart(multipart.getBodyPart(i));
    }
  }
  public static void handlePart(Part part) throws MessagingException, IOException {
    String disposition = part.getDisposition();
    String contentType = part.getContentType();
    if (disposition == null) { // When just body
      System.out.println("Null: "  + contentType);
      // Check if plain
      if ((contentType.length() >= 10) && (contentType.toLowerCase().substring(0, 10).equals("text/plain"))) {
        part.writeTo(System.out);
      } else { // Don't think this will happen
        System.out.println("Other body: " + contentType);
        part.writeTo(System.out);
      }
    } else if (disposition.equalsIgnoreCase(Part.ATTACHMENT)) {
      System.out.println("Attachment: " + part.getFileName() + " : " + contentType);
      saveFile(part.getFileName(), part.getInputStream());
    } else if (disposition.equalsIgnoreCase(Part.INLINE)) {
      System.out.println("Inline: " + part.getFileName() + " : " + contentType);
      saveFile(part.getFileName(), part.getInputStream());
    } else {  // Should never happen
      System.out.println("Other: " + disposition);
    }
  }
	
	
	
	public static File saveFile(String filename, InputStream input) throws FileNotFoundException, IOException {
      File file = new File(filename);
      for (int i = 0; file.exists(); i++) {
          file = new File(filename + i);
      }
      FileOutputStream fos = new FileOutputStream(file);
      BufferedOutputStream bos = new BufferedOutputStream(fos);

      BufferedInputStream bis = new BufferedInputStream(input);
      int aByte;
      while ((aByte = bis.read()) != -1) {
          bos.write(aByte);
      }
      bos.flush();
      bos.close();
      bis.close();
      return file;
  }
}