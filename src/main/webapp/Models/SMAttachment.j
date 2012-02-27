/*
 *  SMAttachment.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

/*!
    An SMEmail may have zero or more file attachments.
*/
@implementation SMAttachment : SMRemoteObject
{
    SMEmail     email @accessors;

    CPString    pk @accessors;
    CPString    fileName @accessors;
    int         sizeInBytes @accessors;
    CPString    contentType @accessors;
}

- (id)initWithAttachmentObject:(Object)anObject
{
    if (self = [super init])
    {
        pk = anObject.webServerAttachmentId;
        fileName = anObject.fileName;
        sizeInBytes = anObject.sizeInBytes;
        contentType = anObject.contentType;
    }
    return self;
}

- (CPString)url
{
    return "GetComposingAttachment?webServerAttachmentId=" + pk;
}

- (CPString)downloadUrl
{
    return [self url] + "&downloadMode=true";
}

- (CPString)viewUrl
{
    return [self url] + "&downloadMode=false";
}

- (CPString)description
{
    return "<SMAttachment {pk: " + pk + ", fileName: '" + fileName + "', sizeInBytes: " + sizeInBytes + ", contentType: '" + contentType + "' }>";
}

- (BOOL)isEqual:(id)anObject
{
    return self === anObject || (anObject && anObject.isa && [anObject isKindOfClass:SMAttachment] && pk && pk == [anObject pk]);
}

@end
