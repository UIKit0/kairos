/*
 *  Compose.j
 *  Mail
 *
 *  Authors: Ariel Patschiki, Vincent Richomme
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>

@import "../Models/SMAttachment.j"

var CPAlertSaveAsDraft                          = 0,
    CPAlertContinueWriting                      = 1,
    CPAlertDiscard                              = 2;

var MAX_ATTACHMENTS_TO_SHOW = 3; // If there are more attachments than this, a scrollbar will be shown.

@implementation ComposeController: CPWindowController
{
    @outlet CPWindow                    theWindow;

    @outlet CPView                      toolbarSlot;
    @outlet CPView                      lowerContentView;
    @outlet CPView                      editorSlot;

    @outlet SMEditorToolbarController   editorToolbarController;
    @outlet WKTextView                  textView;
    @outlet id                          textFieldToAddress; //CPTextField
    @outlet id                          textFieldCCAddress; //CPTextField

    @outlet id                          textFieldSubject; //CPTextField

    IBOutlet CPCollectionView           attachmentList;

    /*! The email being composed. */
    SMEmail                             email @accessors;

//  id                                  _prevDelegate;
//  Imap                                _imap;
    //CPString                          _messageID;
    ServerConnection                    _serverConnection;

    boolean                             isSending;
}

#pragma mark -
#pragma mark Window handlers

- (void)awakeFromCib
{
    [self setEmail:[SMEmail new]];

    [theWindow center];

    // TODO for GUI developer: this is not working (strange). We need modal window, but this making windows non-respondable:
    // [CPApp runModalForWindow:theWindow];

    [textView setBackgroundColor:[CPColor whiteColor]];
    [textView setValue:CGInsetMake(8.0, 10.0, 8.0, 10.0) forThemeAttribute:@"content-inset"];
    [textView setAutohidesScrollers:NO];

    var attachmentPrototypeView = [[attachmentList itemPrototype] view];
    [attachmentList setMinItemSize:[attachmentPrototypeView frameSize]];
    [attachmentList setMaxItemSize:[attachmentPrototypeView frameSize]];

    var contentView = [theWindow contentView]; //"http://localhost:8080/uploadAttachment"

    _serverConnection = [[ServerConnection alloc] init];

    [_serverConnection setDefaultTimeout];
    // Call this clear when starting to compose new email to clear.
    // TODO: use this only when creatin new email. (not yet possible to DO).
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailClearAll"
           withFunctionParametersAsObject:nil
                                 delegate:self
                           didEndSelector:nil
                                    error:nil];

    [self addObserver:self forKeyPath:@"email.attachments" options:nil context:nil];

    [theWindow makeFirstResponder:textView];

    var toolbarView = [editorToolbarController view];
    [toolbarView setFrame:[toolbarSlot bounds]];
    [toolbarSlot addSubview:toolbarView];

    [self layoutSubviews];
}

- (void)observeValueForKeyPath:keyPath
    ofObject:anObject
    change:change
    context:context
{
    if (keyPath == @"email.attachments")
    {
        [self layoutSubviews];
    }
}

// TODO: this is not working (not called at all)
- (BOOL)windowShouldClose:(id)window
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

- (IBAction)attachmentUploaded:(id)sender
{
    //alert("This button used for tests during development of compose window.");

    [self reDownloadListOfAttachments];
}

- (IBAction)sendButtonClickedAction:(id)sender
{
    // TODO: for GUI developer: replace htmlOfEmail value with full html text of email from rich text editor.
    [self setIsSending:YES];

    var htmlOfEmailVar = [textView htmlValue];
    [_serverConnection setTimeout:60];

    console.log("emailing html ", htmlOfEmailVar);

    [_serverConnection callRemoteFunction:@"currentlyComposingEmailSend"
           withFunctionParametersAsObject: { "htmlOfEmail":htmlOfEmailVar,
                                             "subject":[self.textFieldSubject objectValue],
                                             "to":[self.textFieldToAddress objectValue],
                                             "cc":[self.textFieldCCAddress objectValue] }
                                 delegate:self
                           didEndSelector:@selector(currentlyComposingEmailSendDidReceived:withParametersObject:)
                                    error:@selector(currentlyComposingEmailSendTimeOutOrError:)];
}

- (void)setIsSending:(boolean)aFlag
{
    isSending = aFlag;
    [[theWindow toolbar] validateVisibleItems];
}

- (boolean)validateToolbarItem:(id)toolbarItem
{
    switch ([toolbarItem itemIdentifier])
    {
        case "toolbarSendItem":
            return !isSending;
            break;
    }
    return YES;
}

- (void)currentlyComposingEmailSendTimeOutOrError:(id)sender
{
    // TODO: for GUI developer: THINK: how it should work when email is failed to send by timeout.
    [self setIsSending:NO];

    alert("Error sending email: timeout");
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
        // TODO: how to show error for user?
        alert("Failed to send email. Error details: " + parametersObject.errorDetails);
    }
    [self setIsSending:NO];
}

#pragma mark -
#pragma mark Client-Server API

- (void)reDownloadListOfAttachments
{
    [_serverConnection setDefaultTimeout];
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailGetListOfAttachments"
           withFunctionParametersAsObject:nil
                                 delegate:self
                           didEndSelector:@selector(reDownloadListOfAttachmentsDidReceived:withParametersObject:)
                                    error:nil];
}

- (void)reDownloadListOfAttachmentsDidReceived:(id)sender withParametersObject:parametersObject
{
    var newAttachments = [];

    for (var i = 0; i < parametersObject.listOfAttachments.length; i++)
        newAttachments.push([[SMAttachment alloc] initWithAttachmentObject:parametersObject.listOfAttachments[i]]);

    [self setAttachments:newAttachments];
}

- (void)setAttachments:(CPArray)someAttachments
{
    [email setAttachments:someAttachments];
}

- (IBAction)toogleFormatBar:(id)sender
{
    [toolbarSlot setHidden:![toolbarSlot isHidden]];
    [self layoutSubviews];
}

- (void)layoutSubviews
{
    var contentFrame = [[theWindow contentView] bounds];
    if (![toolbarSlot isHidden])
    {
        contentFrame.origin.y += CGRectGetMaxY([toolbarSlot frame]);
        contentFrame.size.height -= contentFrame.origin.y;
    }
    [lowerContentView setFrame:contentFrame];

    var attachmentSize = [attachmentList minItemSize],
        attachmentsCount = [[email attachments] count],
        attachmentsToShow = MIN(attachmentsCount, MAX_ATTACHMENTS_TO_SHOW),
        attachmentScrollView = [attachmentList enclosingScrollView],
        frame = CGRectMakeCopy([attachmentScrollView frame]),
        editorView = editorSlot,
        editorFrame = CGRectMakeCopy([editorView frame]),
        heightBefore = frame.size.height,
        verticalMargin = [attachmentList verticalMargin];

    frame.size.height = attachmentsToShow * (verticalMargin + attachmentSize.height) + verticalMargin;
    [attachmentScrollView setFrame:frame];

    var showScrollbars = attachmentsCount > attachmentsToShow;
    [attachmentScrollView setBackgroundColor:showScrollbars ? [CPColor whiteColor] : [CPColor clearColor]];
    [attachmentScrollView setBorderType:showScrollbars ? CPLineBorder : CPNoBorder];
    [attachmentScrollView setHasVerticalScroller:showScrollbars];

    var delta = frame.size.height - heightBefore;

    editorFrame.origin.y += delta;
    editorFrame.size.height -= delta;
    [editorView setFrame:editorFrame];
}

@end

