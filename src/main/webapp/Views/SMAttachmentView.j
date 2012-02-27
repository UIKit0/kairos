/*
 *  SMAttachmentView.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

@implementation SMAttachmentView : CPView
{
    SMAttachment attachment @accessors;

    IBOutlet CPTextField    nameLabel;
    IBOutlet CPButton       downloadButton;
    IBOutlet CPButton       viewButton;
    IBOutlet CPButton       deleteButton;
}

- (void)_init
{
}

- (void)setRepresentedObject:(id)anObject
{
    [self setAttachment:anObject];
    [nameLabel setStringValue:[attachment fileName]];
}

- (IBAction)download:(id)sender
{
    [[CPWorkspace sharedWorkspace] openFile:[attachment downloadUrl]];
}

- (IBAction)view:(id)sender
{
    [[CPWorkspace sharedWorkspace] openFile:[attachment viewUrl]];
}

- (IBAction)delete:(id)sender
{
    [[[attachment email] mutableArrayValueForKey:"attachments"] removeObject:attachment];

    var _serverConnection = [ServerConnection new];
    [_serverConnection callRemoteFunction:@"currentlyComposingEmailDeleteAttachment"
           withFunctionParametersAsObject:{ webServerAttachmentId:[attachment pk] }
                             delegate:self
                       didEndSelector:nil
                                error:nil];
}

@end


var SMAttachmentViewNameLabelKey    = @"SMAttachmentViewNameLabelKey",
    SMAttachmentViewDownloadLabelKey  = @"SMAttachmentViewDownloadLabelKey";

@implementation SMAttachmentView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        nameLabel = [aCoder decodeObjectForKey:SMAttachmentViewNameLabelKey];
        downloadLabel = [aCoder decodeObjectForKey:SMAttachmentViewDownloadLabelKey];

        [self _init];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:nameLabel forKey:SMAttachmentViewNameLabelKey];
    [aCoder encodeObject:downloadLabel forKey:SMAttachmentViewDownloadLabelKey];
}

@end
