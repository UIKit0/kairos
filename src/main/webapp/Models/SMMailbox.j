/*
 *	SMMailbox.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@import "SMRemoteObject.j"

@import "../Controllers/MailSourceViewController.j" // for FolderEditModes enum.

// The order to display mailboxes. Any mailbox name not in this list goes at the end.
var MailboxSortPriorityList = [@"inbox", @"sent", @"drafts", @"junk", @"trash"];

@implementation SMMailbox : SMRemoteObject
{
    /*! The account the mailbox belongs to. */
    SMMailAccount   mailAccount @accessors;

    ServerConnection _serverConnection @accessors;

    // Headers of email within the box, if loaded.
    CPArray         mailHeaders @accessors;

    CPString        name @accessors;
    CPNumber        count @accessors;
    CPNumber        unread @accessors;
}

// Designated initializer
- (id)initWithName:(CPString)aName count:(int)total unread:(int)theUnread
{
    self = [super init];
    if (self)
    {
        mailHeaders = [CPArray array];

        name = aName;
        count = total;
        unread = theUnread;

        [self _init];
    }
    return self;
}

- (void)_init
{
    // FIXME Seems like a waste to have one 'imapServer' instance per mailbox, but every ServerConnection
    // can only have one, unchangable delegate.
    /*imapServer = [[HNRemoteService alloc] initForScalaTrait:@"com.smartmobili.service.ImapService"
                                       objjProtocol:nil
                                           endPoint:nil
                                           delegate:self];*/
    _serverConnection = [[ServerConnection alloc] init];
}

/*!
    An integer sort priority which can be used to sort mailboxes into a natural
    order with MailBoxSortPriorityList boxes on top.
*/
- (int)inverseDisplayPriority
{
    var result,
        lcFoldername = [[[self name] lowercaseString] stringByTrimmingWhitespace],
        index = [MailboxSortPriorityList indexOfObject:lcFoldername];
    return index != CPNotFound ? index : [MailboxSortPriorityList count] + 1;
}

- (int)compareInverseDisplayPriority:(id)other
{
    var left = [self inverseDisplayPriority],
        right = [other inverseDisplayPriority];
    return left - right;
}

- (BOOL)isSpecial
{
    return [self inverseDisplayPriority] < [MailboxSortPriorityList count];
}

- (void)loadHeadersAtPage:(int)pageToLoad
{
    [self setMailHeaders:[]];
    
    [_serverConnection callRemoteFunction:@"headersForFolder"
           withFunctionParametersAsObject:{ "folder" : [self name], "pageToLoad" : pageToLoad }
                                 delegate:self
                           didEndSelector:@selector(imapServerHeadersDidLoad:withParametersObject:)
                                    error:nil];
}

- (void)imapServerHeadersDidLoad:(id)sender withParametersObject:parametersObject
{
    var listOfMessagesHeaders = parametersObject.listOfHeaders;
    
    var result = [CPArray array]; // Result is an array with SMMailHeader elements
    if (listOfMessagesHeaders)
    {
        for (var i = 0; i < listOfMessagesHeaders.length; i++) 
        {
            var mailHeader= [[SMMailHeader alloc] init];
            [mailHeader setSubject:listOfMessagesHeaders[i].subject];
        
            var sd = listOfMessagesHeaders[i].sentDate;
            var date = [[CPDate alloc] initWithTimeIntervalSince1970:sd];
            [mailHeader setDate:date];
        
            [mailHeader setMessageId:listOfMessagesHeaders[i].messageId];
            [mailHeader setIsSeen:listOfMessagesHeaders[i].isSeen];
        
            [mailHeader setMd5:"undone"]; // TODO: why we need md5, where this field is used?
        
            var from_Array = listOfMessagesHeaders[i].from_Array;
       
            var fromName = @"";
            var fromEmail = @"";
       
            for (var j = 0; j < from_Array.length; j++) 
            {
                fromName = fromName + ", " + from_Array[j].personal;
                fromEmail = fromEmail + ", " + from_Array[j].address;
            }
        
            // TODO: if lentgh > 0 remove first 2 chars in fromName,fromEmail
            if (fromName.length > 2)
                fromName = [fromName substringFromIndex:2];
            else
                fromName = @"";
            if (fromEmail.length > 2)
                fromEmail = [fromEmail substringFromIndex:2];
            else
                fromEmail = @"";
        
            [mailHeader setFromName:fromName]; // TODO: wrong model. We should save pairs of name and email. But, where is this info used? To show table and column "from" ?
            [mailHeader setFromEmail:fromEmail];
        
            result = [result arrayByAddingObject:mailHeader];
        }
    }
    
    [self setMailHeaders:result];
}

- (void)setFolderName:(CPString)aName withFolderEditMode:(FolderEditModes)folderEditMode
{
    if (name == aName)
        return;

    var oldName = name;
    [self setName:aName];

   /* OLD CODE:
     if ([self isNew])
        [self save];
    else {
        //  Not implemented.
        //[imapServer renameFolder:oldName
        //                      to:name
        //                delegate:@selector(imapServerDidRenameFolder:)
        //                   error:nil];
    }*/

    if (folderEditMode == FolderEditModes.RenameFolder)
    {
        // rename
        /*[_serverConnection renameFolder:oldName toName:aName
                        delegate:@selector(imapServerDidRenameFolder:)
                           error:nil];*/
        [_serverConnection callRemoteFunction:@"renameFolder"
               withFunctionParametersAsObject:{"oldFolderName":oldName, "toName" : aName}
                                     delegate:self
                               didEndSelector:@selector(imapServerDidRenameFolder:withParametersObject:)
                                        error:nil];
    }
    else
    {
        // create
        [_serverConnection callRemoteFunction:@"createFolder"
               withFunctionParametersAsObject:{"folderNameToCreate":aName}
                                     delegate:self
                               didEndSelector:@selector(imapServerDidCreateFolder:withParametersObject:)
                                        error:nil];
    }
    
    [self save];
}

- (void)imapServerDidRenameFolder:(id)sender withParametersObject:parametersObject
{
    if (withParametersObject.err != "")
    {
        // Output error to user
        alert(withParametersObject.err);
    } 
}

- (void)imapServerDidCreateFolder:(id)sender withParametersObject:parametersObject
{ 
    if (withParametersObject.err != "")
    {
        // Output error to user
        alert(withParametersObject.err);
        // remove folder from screen
        [self remove];
    } 
}

- (void)remove
{
    [[self mailAccount] removeMailbox:self];
}

- (void)save
{
    CPLog("SMMailbox Save called");
    [super save]; 
    // Obevic comment: no need to call create folder here, this is not good. 
    // We call "renameOrCreateFolder" each time when renameTo ends. 
    // Old code (was also commented before):
    // [imapServer createFolder:name
    //                delegate:@selector(imapServerDidCreateFolder:)
    //                   error:nil];
}

- (BOOL)isEqual:(id)anOther
{
    if (self === anOther)
        return YES;

    if (!anOther || ![anOther isKindOfClass:SMMailbox])
        return NO;

    return [self isEqualToMailbox:anOther];
}

- (BOOL)isEqualToMailbox:(SMMailbox)aMailbox
{
    if (!aMailbox)
        return NO;

    return [[self name] isEqual:[aMailbox name]] && [[self mailAccount] isEqual:[aMailbox mailAccount]];
}

@end

@implementation SMMailbox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super init])
    {
        mailHeaders = [aCoder decodeObjectForKey:@"mailHeaders"];

        self.name = [aCoder decodeStringForKey:@"name"];
        self.count = [aCoder decodeNumberForKey:@"count"];
        self.unread = [aCoder decodeNumberForKey:@"unread"];

        [self _init];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:mailHeaders forKey:@"mailHeaders"];

    [aCoder encodeString:self.name forKey:@"name"];
    [aCoder encodeNumber:self.count forKey:@"count"];
    [aCoder encodeNumber:self.unread forKey:@"unread"];
}
@end
