/*
 *  DemoContentReplacer
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili.other;

import java.io.UnsupportedEncodingException;
import java.util.Hashtable;

import javax.mail.Address;
import javax.mail.internet.InternetAddress;

/**
 * Replace some content and mail fields such as "from, to, cc" to fake to show 
 * Kairos mail in demo mode without real mail addresses.
 * @author Victor Kazarinov
 *
 */
public class DemoContentReplacer {

	class Element
	{
		public String fakePersonal;
		public String fakeAddress;
	}
	
	// Key is "real address".
	public Hashtable<String, Element> hashOfEmailReplacement = new Hashtable<String, Element>();
	
	int maxEmailReplaced = 0;
	
	public String replaceAllToFakeInPersonal(String personal, String address) {
		Element el = hashOfEmailReplacement.get(address);
		if (el == null) {
			el = createAndStoreToHashNewElement(address);
		}
		return el.fakePersonal;
	}

	private Element createAndStoreToHashNewElement(String address) {
		Element el = new Element();
		if (address.toLowerCase().contentEquals("webguest@smartmobili.com")) {
			el.fakeAddress = "webguest@smartmobili.com";
			el.fakePersonal = "Web Guest";
		}
		else {
			maxEmailReplaced++;
			el.fakeAddress = "user" + maxEmailReplaced + "@foobar.com";
			el.fakePersonal = "User" + maxEmailReplaced;
		}
		hashOfEmailReplacement.put(address, el);
		return el;
	}

	public String replaceAllToFakeInAddress(String address) {	
		Element el = hashOfEmailReplacement.get(address);
		if (el == null) {
			el = createAndStoreToHashNewElement(address);
		}
		return el.fakeAddress;
	}
	
	public static String explicitlyReplaceContent(String text) {
		text = text.replace("Vincent Richomme", "User");
		
		// bellow is make lowercase the whole text! It is for simplification.
		if (text.contains("v.richomme@gmail.com"))
			text = text.replace("v.richomme@gmail.com", "user@foobar.com");
		if (text.toLowerCase().contains("vincent richomme"))
			text = text.toLowerCase().replace("vincent richomme", "User");
		if (text.toLowerCase().contains("vincent"))
			text = text.toLowerCase().replace("vincent", "user");
		if (text.toLowerCase().contains("ignacio"))
			text = text.toLowerCase().replace("ignacio", "user");
		if (text.toLowerCase().contains("cases"))
			text = text.toLowerCase().replace("cases", "user");
		if (text.toLowerCase().contains("richomme"))
			text = text.toLowerCase().replace("richomme", "user");
		return text;
	}

	public String addressToString(Address[] from) throws UnsupportedEncodingException {
		String res = "";
		for(Address addr : from) {
			Address fakeAddrF = addressToFake(addr);
			InternetAddress fakeAddr = (InternetAddress)fakeAddrF;
			if (fakeAddr.getPersonal() != null)
				res = res + ", " + fakeAddr.getPersonal() + " <" + fakeAddr.getAddress() + ">";
			else
				res = res + ", " + " <" + fakeAddr.getAddress() + ">";
		}
		if (res.startsWith(", "))
			res = res.substring(2);
		return res;
	}
	
	public Address addressToFake(Address addr) throws UnsupportedEncodingException {
		InternetAddress ia = (InternetAddress)addr;
		ia.setAddress(replaceAllToFakeInAddress(ia.getAddress()));
		if (ia.getPersonal() != null)
			ia.setPersonal(replaceAllToFakeInPersonal(ia.getPersonal(), ia.getAddress()));
		return ia;
	}
}
