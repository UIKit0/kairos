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
