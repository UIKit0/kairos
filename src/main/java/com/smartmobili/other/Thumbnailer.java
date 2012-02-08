/*
 *  Thumbnailer
 *  Kairos Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

package com.smartmobili.other;

import java.awt.Container;
import java.awt.Graphics2D;
import java.awt.Image;
import java.awt.MediaTracker;
import java.awt.RenderingHints;
import java.awt.Toolkit;
import java.awt.image.BufferedImage;
import java.io.ByteArrayOutputStream;
import java.io.IOException;

public abstract class Thumbnailer {
	static String justAnStaticObjectForLock_createThumbnail_Function = new String();
	/*
	 * 
	 * This function is based on code to create thumbnail from code snipped from here: 
	 * http://viralpatel.net/blogs/2009/05/20-useful-java-code-snippets-for-java-developers.html
	 * 
	 * This function can be rewrited to directly save data to output stream. This will require less memory 
	 * (no buffer-in-a-middle), but it will be not possible to show an error icon for user if
	 * something will goes wrong
	 * 
	 * TODO: check this function for memory leaks.
	 * TODO: many simultaneous requests for image attachments and conversion to create Thumbnail can overload
	 * memory. Perhaps need to create pool and separate conversion thread. There will be a processing queue.
	 * It will process images for DB and for requests (or everything will be trough DB). So, for example,
	 * it will be configured to not convert more than 5 images simultaneously. 
	 * Simplest way to implement is "mutexes" or semaphors with increased counter of simeltanous processing.
	 * And best if we limit automatically by processors (cores) count, so each core is processing image.
	 * Bellow for simplification we limit to process only using ONE core with "synchronized" keyword.
	 * 
	 * Returns byte array of result thumbnail image or null if some error occured.
	 */
	public static byte[] createThumbnail(byte[] sourceImage, int thumbWidth,
			int thumbHeight, int quality) throws InterruptedException,
			IOException {
		// Why "synchronized" is used please read above in TODO comment in
		// function header.
		synchronized (justAnStaticObjectForLock_createThumbnail_Function) {
			// load image from filename
			Image image = Toolkit.getDefaultToolkit().createImage(sourceImage);
			// Image image = Toolkit.getDefaultToolkit().getImage(filename);
			MediaTracker mediaTracker = new MediaTracker(new Container());
			mediaTracker.addImage(image, 0);
			mediaTracker.waitForID(0);

			// use this to test for errors at this point:
			// System.out.println(mediaTracker.isErrorAny());
			if (mediaTracker.isErrorAny())
				return null;

			// determine thumbnail size from WIDTH and HEIGHT
			double thumbRatio = (double) thumbWidth / (double) thumbHeight;
			int imageWidth = image.getWidth(null);
			int imageHeight = image.getHeight(null);
			double imageRatio = (double) imageWidth / (double) imageHeight;
			if (thumbRatio < imageRatio) {
				thumbHeight = (int) (thumbWidth / imageRatio);
			} else {
				thumbWidth = (int) (thumbHeight * imageRatio);
			}

			// draw original image to thumbnail image object and
			// scale it to the new size on-the-fly
			Graphics2D graphics2D = null;
			BufferedImage thumbImage = null;
			try {
				thumbImage = new BufferedImage(thumbWidth, thumbHeight,
						BufferedImage.TYPE_INT_RGB);
				graphics2D = thumbImage.createGraphics();
				graphics2D.setRenderingHint(RenderingHints.KEY_INTERPOLATION,
						RenderingHints.VALUE_INTERPOLATION_BILINEAR);
				graphics2D
						.drawImage(image, 0, 0, thumbWidth, thumbHeight, null);
			} catch (Exception ex) {
				return null;
			} finally {
				graphics2D.dispose();
			}

			// save thumbnail image
			ByteArrayOutputStream b = null;
			try {
				b = new ByteArrayOutputStream();

				/*
				 * JPEGImageEncoder encoder = JPEGCodec.createJPEGEncoder(b);
				 * JPEGEncodeParam param = encoder
				 * .getDefaultJPEGEncodeParam(thumbImage); quality = Math.max(0,
				 * Math.min(quality, 100)); param.setQuality((float) quality /
				 * 100.0f, false); encoder.setJPEGEncodeParam(param);
				 * encoder.encode(thumbImage);
				 */
				if (javax.imageio.ImageIO.write(thumbImage, "JPG", b) == false)
					return null;

				return b.toByteArray();
			} catch (Exception ex) {
				return null;
			} finally {
				b.close();
			}
		}
	}
}
