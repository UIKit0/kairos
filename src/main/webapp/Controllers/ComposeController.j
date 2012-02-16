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
    @outlet id              customView1;
    @outlet id              textField1; //CPTextField  This is email body currently. Should be replaced to rich text editor
    @outlet id              textFieldToAddress; //CPTextField
    @outlet id              textFieldCCAddress; //CPTextField

    @outlet id              textFieldSubject; //CPTextField
    TextDisplay statusDisplay;
//	@outlet CPWebView		webView;

//	id						_prevDelegate;
//	Imap					_imap;
	//CPString				_messageID;
    ServerConnection    _serverConnection;
}

#pragma mark -
#pragma mark Window handlers

- (void) awakeFromCib
{
	[theWindow center];

	// TODO for GUI developer: this is not working (strange). We need modal window, but this making windows non-respondable:
    // [CPApp runModalForWindow:theWindow];
    
    var contentView = [theWindow contentView];
  
    var urlString = "uploadAttachment"; //"http://localhost:8080/uploadAttachment"
    
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
    
    _serverConnection = [[ServerConnection alloc] init];
        
    // Call this clear when starting to compose new email to clear. 
    // TODO: use this only when creatin new email. (not yet possible to DO).
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailClearAll"
           withFunctionParametersAsObject:nil
                                 delegate:self
                           didEndSelector:nil
                                    error:nil];
}

// TODO: this is not working (not called at all)
-(BOOL)windowShouldClose:(id)window
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
    alert("This button used for tests during development of compose window.");
}

- (IBAction)sendButtonClickedAction:(id)sender
{
    // TODO: for GUI developer: replace htmlOfEmail value with full html text of email from rich text editor.
    var htmlOfEmailVar = [self.textField1 objectValue];
    
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailSend"
           withFunctionParametersAsObject: { "htmlOfEmail":htmlOfEmailVar,
                                             "subject":[self.textFieldSubject objectValue],
                                             "to":[self.textFieldToAddress objectValue],
                                             "cc":[self.textFieldCCAddress objectValue] }
                                 delegate:self
                           didEndSelector:@selector(currentlyComposingEmailSendDidReceived:withParametersObject:)
                                    error:nil];
}

- (void)currentlyComposingEmailSendDidReceived:(id)sender withParametersObject:parametersObject 
{
    // TODO: for GUI developer: THINK: how it should work when email is sent - should window be closed or not and etc.
    if (parametersObject.emailIsSent == true) 
    {
        alert("Email is sent successfully");
        [theWindow close];
    }
    else
    {
        alert("Failed to send email. Error details: " + parametersObject.errorDetails);
    }
}

#pragma mark -
#pragma mark Client-Server API

// TODO for GUI developer: UNDONE: use this deleteAttachment function to delete attachments from list when user want to delete selected attachment from list. Also please handle "currentlyComposingEmailDeleteAttachmentDidReceived" function where is shown alert for user 
- (void)deleteAttachment:(CPString)webServerAttachmentIdToDelete
{
    //var value = [textField1 objectValue];
    var value = webServerAttachmentIdToDelete;
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailDeleteAttachment"
           withFunctionParametersAsObject:{ webServerAttachmentId:value }
                             delegate:self
                       didEndSelector:@selector(currentlyComposingEmailDeleteAttachmentDidReceived:withParametersObject:)
                                error:nil];
}

- (void)currentlyComposingEmailDeleteAttachmentDidReceived:(id)sender withParametersObject:parametersObject 
{
    // TODO for GUI developer:
    alert("Attachment deleted:\n deletedWebServerAttachmentId=" + 
          parametersObject.deletedWebServerAttachmentId + "\n" +
          "deletedSuccessfully=" + parametersObject.deletedSuccessfully + "\n" +
          "error=" + parametersObject.error);
    
    // update list of attachments.
    [self reDownloadListOfAttachments];
}

-(void)reDownloadListOfAttachments
{
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailGetListOfAttachments"
           withFunctionParametersAsObject:nil
                                 delegate:self
                           didEndSelector:@selector(reDownloadListOfAttachmentsDidReceived:withParametersObject:)
                                    error:nil];
}

- (void)reDownloadListOfAttachmentsDidReceived:(id)sender withParametersObject:parametersObject 
{
    // TODO for GUI developer: UNDONE: replace this with GUI showing list of attachments, where each attachment clickable to view it. (it should go to link of attachment to view/download it).
    [statusDisplay clearDisplay];
    [statusDisplay appendString:@"List of attachments"];
    
    for(var i = 0; i < parametersObject.listOfAttachments.length; i++)
    {
        var link = [[CPString alloc] initWithString:@"<a href=\"" + 
                    "GetComposingAttachment?webServerAttachmentId=" +
                    parametersObject.listOfAttachments[i].webServerAttachmentId + 
                    "&downloadMode=false\"" + " target=\"_blank\"" +
                    ">View</a>" + " " + 
                    "<a href=\"" + 
                    "GetComposingAttachment?webServerAttachmentId=" +
                    parametersObject.listOfAttachments[i].webServerAttachmentId + 
                    "&downloadMode=true\"" + " target=\"_blank\"" +
                    ">Download</a>"];
        
        [statusDisplay appendHtml:parametersObject.listOfAttachments[i].fileName + " size: " + parametersObject.listOfAttachments[i].sizeInBytes + 
         //" " + "webServerAttachmentId=" + parametersObject.listOfAttachments[i].webServerAttachmentId + 
         " " + link];
        
        // UNDONE  NOTE: bellow notes for future, not yet implemented at server side!!
        // TODO for GUI developer: to create downloadable link, use parametersObject.listOfAttachments[i].webServerAttachmentId field as "webServerAttachmentId" parameter in link GetComposingAttachment?webServerAttachmentId=webServerAttachmentId, e.g. http://anHost.com/GetComposingAttachment?webServerAttachmentId=123456asdf where in example webServerAttachmentId has value 123456asdf. 
        // Additional URL parameters &downloadMode=true When "false" it will return usual attachment, when "true" it will respond to download it (in Content-Disposition header in response will be "attachment" keyword).
        // Another additional URL parameter &asThumbnail=true If "true" returned image will be small thumbnail (converted at server side). For files it will fail, will work only for images. (THINK: Perhaps in future it can return icons of files by file extension?)
        // ---
        // Available fields in listOfAttachments[i] object:
        // 1. fileName (String)
        // 2. sizeInBytes (long)
        // 3. webServerAttachmentId (String)
        // 4. contentType (String)
    }
}

#pragma mark -
#pragma mark UploadButton Handlers

-(void) uploadButton:(UploadButton)button didChangeSelection:(CPArray)selection
{
    [button submit];
}

-(void) uploadButton:(UploadButton)button didFailWithError:(CPString)anError
{
    alert("Upload failed with this error: " + anError);
    [self reDownloadListOfAttachments];
     // TODO for GUI developer: hide loading indicator (e.g. ajax-loader.gif)
}

-(void) uploadButton:(UploadButton)button didFinishUploadWithData:(CPString)response
{
    [button resetSelection];
    [self reDownloadListOfAttachments];
    // TODO for GUI developer: hide loading indicator (e.g. ajax-loader.gif)
}

-(void)uploadButtonDidBeginUpload:(UploadButton)button
{
    // TODO for GUI developer: show loading indicator (e.g. ajax-loader.gif)
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

- (void)appendHtml:(CPString)aString
{
    currentString = currentString  + "<br>" +  aString;
    //[self loadHTMLString: currentString];
    [self loadHTMLString:[[CPString alloc] initWithFormat:@"<html><head></head><body style='font-family: Helvetica, Verdana; font-size: 12px;'>%@%@</body></html>", currentString, ""]];

}

-(void)clearDisplay
{
    currentString = "";
    [self loadHTMLString:""];
}

@end
