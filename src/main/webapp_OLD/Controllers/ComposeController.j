/*
 *  Compose.j
 *  Mail
 *
 *  Authors: Ariel Patschiki, Vincent Richomme
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>



var CPAlertSaveAsDraft							= 0,
    CPAlertContinueWriting						= 1,
    CPAlertDiscard								= 2;


@implementation ComposeController: CPWindowController
{
    @outlet CPWindow		theWindow;
	@outlet CPWebView		webView;

	id						_prevDelegate;
	Imap					_imap;
	//CPString				_messageID;
}

- (void) awakeFromCib
{
	[theWindow center];





	[CPApp runModalForWindow:theWindow];
}


- (void) gotMailContent:(Imap) aImap
{
	CPLog.trace(@"ComposeController - gotMailContent");
	/* we restore the main window as a delaget for the imap object */
	_imap.delegate = _prevDelegate;

	/* we display email content */
	[webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@</body></html>", aImap.mailContent.HTMLBody]];
}


- (void) setImap:(CPImap)aImap prevDelegate:(id)delegate
{
	_prevDelegate = delegate;
	_imap = aImap;
}


- (void) setMessageID:(CPString)messageID
{
	_messageID = messageID;
}


-(BOOL)windowShouldClose:(id)window;
{

    var confirmBox = [[CPAlert alloc] init];
	[confirmBox setTitle:nil];
	[confirmBox setAlertStyle:CPInformationalAlertStyle];
	[confirmBox setMessageText:[[TNLocalizationCenter defaultCenter] localize:@"Do you want to discard the changes in the email?"]];
	[confirmBox setInformativeText:[[TNLocalizationCenter defaultCenter] localize:@"Your changes will be lost if you discard them."]];
	[confirmBox addButtonWithTitle:[[TNLocalizationCenter defaultCenter] localize:@"Save as draft"]];
	[confirmBox addButtonWithTitle:[[TNLocalizationCenter defaultCenter] localize:@"Continue writing"]];
	[confirmBox addButtonWithTitle:[[TNLocalizationCenter defaultCenter] localize:@"Discard"]];
	[confirmBox beginSheetModalForWindow:theWindow modalDelegate:self didEndSelector:@selector(confirmEnd:returnCode:) contextInfo:nil];

	return NO;
}

- (void)confirmEnd:(CPAlert)confirm returnCode:(int)returnCode
{
	CPLog.trace(@"confirmEnd - returnCode = %d", returnCode);
	if (returnCode == CPAlertDiscard)
	{
		[CPApp stopModal];
		[theWindow close];
	}
}

@end
