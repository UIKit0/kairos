/*
 *  Compose.j
 *  Mail
 *
 *  Authors: Ariel Patschiki, Vincent Richomme
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>
@import "../Components/FileUpload.j" // UploadButton component.



var CPAlertSaveAsDraft							= 0,
    CPAlertContinueWriting						= 1,
    CPAlertDiscard								= 2;


@implementation ComposeController: CPWindowController
{
    @outlet CPWindow		theWindow;
    @outlet id		customView1;
    TextDisplay statusDisplay;
//	@outlet CPWebView		webView;

//	id						_prevDelegate;
//	Imap					_imap;
	//CPString				_messageID;
}

#pragma mark -
#pragma mark Window handlers

- (void) awakeFromCib
{
	[theWindow center];

	// TODO: this is not working (strange). We need modal window, but this making windows non-respondable:
    // [CPApp runModalForWindow:theWindow];
    
    var contentView = [theWindow contentView];
  
    var urlString = "http://127.0.0.1:8080/uploadAttachment";        
    
    if (customView1)
    {
        var customView1Frame = customView1._bounds.size;  //CGFrame  
        var fileUploadButton = [[UploadButton alloc] initWithFrame:CGRectMake(0, 0, customView1Frame.width, customView1Frame.height)];
        [fileUploadButton setTitle:"Upload File1"];
        [fileUploadButton setBordered:YES];
        [fileUploadButton allowsMultipleFiles:YES];
        [fileUploadButton setURL:urlString];
        [fileUploadButton setDelegate:self];
    
        [customView1 addSubview:fileUploadButton];
        
        statusDisplay = [[TextDisplay alloc] initWithFrame:CGRectMake(10, 180, 500, 100)];
        [contentView addSubview:statusDisplay];
    }
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

#pragma mark -
#pragma mark Actions

- (IBAction)testAction1:(id)sender
{
    alert("asdf");
}

#pragma mark -
#pragma mark UploadButton Handlers

-(void) uploadButton:(UploadButton)button didChangeSelection:(CPArray)selection
{
    [statusDisplay clearDisplay];
    [statusDisplay appendString:"Selection has been made: " + selection];
    
    [button submit];
}

-(void) uploadButton:(UploadButton)button didFailWithError:(CPString)anError
{
    [statusDisplay appendString:"Upload failed with this error: " + anError];
}

-(void) uploadButton:(UploadButton)button didFinishUploadWithData:(CPString)response
{
    [statusDisplay appendString:"Upload finished with this response: " + response];
	alert("finished");
    [button resetSelection];
}

-(void) uploadButtonDidBeginUpload:(UploadButton)button
{
    [statusDisplay appendString:"Upload has begun with selection: " + [button selection]];
}


#pragma mark -
#pragma mark Old

//- (void) gotMailContent:(Imap) aImap
//{
//	CPLog.trace(@"ComposeController - gotMailContent");
//	/* we restore the main window as a delaget for the imap object */
//	_imap.delegate = _prevDelegate;
//
//	/* we display email content */
//	[webView loadHTMLString:[[CPString alloc] initWithFormat:@"<html><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@</body></html>", aImap.mailContent.HTMLBody]];
//}
/*
 
 - (void) setImap:(CPImap)aImap prevDelegate:(id)delegate
 {
 _prevDelegate = delegate;
 _imap = aImap;
 }
 
 
 - (void) setMessageID:(CPString)messageID
 {
 _messageID = messageID;
 }*/

@end

#pragma mark -
#pragma mark TextDisplay class implementation

@implementation TextDisplay: CPWebView
{
    CPString currentString;
}

- (id)initWithFrame:(CPRect)aFrame
{
    self = [super initWithFrame:aFrame];
    if(self)
    {
        currentString = "";
    }
    
    return self;
}

- (void)appendString:(CPString)aString
{
    currentString = currentString + "<pre>" + aString + "</pre>";
    [self loadHTMLString: currentString];
}


-(void)clearDisplay
{
    currentString = "";
    [self loadHTMLString:""];
}

@end
