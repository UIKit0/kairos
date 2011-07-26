/*
 *  Imap.j
 *  Mail
 *
 *  Authors: Ariel Patschiki, Vincent Richomme.
 
 *  Copyright Smartmobili 2011. All rights reserved.
 */

@import <Foundation/Foundation.j>



var DefaultFolders = ["inbox", "sent", "drafts", "junk", "trash"];



@implementation Imap: CPObject 
{
	//id delegate;
	CPString urlBase;
	CPString whatIsLoading;
	JSObject mailboxes;
	JSObject mailboxesMain;
	JSObject mailboxesOthers;
	JSObject mailHeaders;
	JSObject mailContent;
}

- (id)init
{
	self = [super init];
	
	if (self)
	{
		//if (document.location.protocol == @"file:")
		self.urlBase = @"http://localhost/~tahiche/objj/kairos/Webservice/";
		//else
		//self.urlBase = @"../Webservice/";		 
	}
	
	//console.log(document.location.protocol);
	console.log(self.urlBase);
	
	return self;
}


+ (int) getFolderPos: (CPString)aFoldername
{
	var lcFoldername = [aFoldername lowercaseString]; 

	var i;	
	for (i = 0; i < [DefaultFolders count]; i++) 
	{
		if (lcFoldername == DefaultFolders[i])
			break;
	}	
	
	return i;
}

+ (BOOL) isDefaultFolder: (CPString)aFoldername
{
	/*
	var lcFoldername = [aFoldername lowercaseString]; 
	if ([lcFoldername isEqualToString:@"inbox"]		||
		[lcFoldername isEqualToString:@"sent"]		||
		[lcFoldername isEqualToString:@"drafts"]	||
		[lcFoldername isEqualToString:@"junk"]		||
		[lcFoldername isEqualToString:@"trash"]		)
	{
		return YES;
	}
	else 
	{
		return NO;
	}
	*/
	if ([Imap getFolderPos:aFoldername] < DefaultFolders.length)
		return YES;
	else 
		return NO;
} 



- (void) orderMailHeadersBy: (CPString) column: (BOOL) asc 
{
	//	console.log(column);
	//	console.log(asc);
}

- (void) getMailboxes 
{
	console.log("getMailboxes");
	self.whatIsLoading = @"Mailboxes";
	
//	var url = self.urlBase  + @"?class=FetchImap&method=getMailboxes"; 
//	var request = [CPURLRequest requestWithURL:url];
//	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
} 

- (void) getMailHeaders: (CPString) mailbox 
{
	self.whatIsLoading = @"MailHeaders";
	if (mailbox == @"Inbox") 
	{
		mailbox = @"INBOX";
	}
	
	//var url = self.urlBase  + @"?class=FetchImap&method=getMailHeaders&mailbox=" + mailbox; 
	//var request = [CPURLRequest requestWithURL:url];
	//var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void) getMailContent: (CPString) selectedEmail 
{
	self.whatIsLoading = @"MailContent";
	
//	var url = self.urlBase  + @"?class=FetchImap&method=getMailContent&email=" + selectedEmail; 
//	var request = [CPURLRequest requestWithURL:url];
//	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}

- (void) getMailContentFromMessageID: (CPString) messageID
{
	self.whatIsLoading = @"MailContentFromMessageID";
	
//	var url = self.urlBase  + @"?class=FetchImap&method=getMailContentFromMessageID&messageID=" + messageID; 
//	var request = [CPURLRequest requestWithURL:url];
//	var connection = [CPURLConnection connectionWithRequest:request delegate:self];
}



- (void)connection:(CPJSONPConnection)aConnection didReceiveData:(CPString)data 
{
	
	if ([data isJSONValid]) 
	{
		if ([self.whatIsLoading isEqualToString:@"Mailboxes"]) 
		{
			self.whatIsLoading = nil;
			// Separate the things
			self.mailboxes = [data objectFromJSON];
			mailboxesMain = [];
			mailboxesOthers = [];
			
			/* Parse received mailboxes */
			for (var i = 0; i < [self.mailboxes count]; i++) 
			{
				var mailbox = [self.mailboxes objectAtIndex:i];
				mailbox.name = [mailbox.name lowercaseAndCapitalized];
				
				if ([Imap isDefaultFolder:mailbox.name])
				{
					[mailboxesMain insertObject:mailbox atIndex:[Imap getFolderPos:mailbox.name]];
				}
				else
				{
					[mailboxesOthers addObject:mailbox];
				}
			}
			
			
			// Calls the callback
			if ([delegate respondsToSelector:@selector(gotMailboxes:)]) {
				[delegate gotMailboxes:self];
			}
		} 
		else if ([whatIsLoading isEqualToString:@"MailHeaders"]) 
		{
			self.whatIsLoading = nil;
			self.mailHeaders = [data objectFromJSON];
			if ([delegate respondsToSelector:@selector(gotMailHeaders:)]) {
				[delegate gotMailHeaders:self];
			}
		} 
		else if ([whatIsLoading isEqualToString:@"MailContent"]) 
		{
			self.whatIsLoading = nil;
			self.mailContent = [data objectFromJSON];
			if ([delegate respondsToSelector:@selector(gotMailContent:)]) {
				[delegate gotMailContent:self];
			}
		} 
		else if ([whatIsLoading isEqualToString:@"MailContentFromMessageID"]) 
		{
			self.whatIsLoading = nil;
			self.mailContent = [data objectFromJSON];
			if ([delegate respondsToSelector:@selector(gotMailContent:)]) {
				[delegate gotMailContent:self];
			}
		}
	}
	else 
	{
		console.log("didReceiveData : INVALID JSON");
		console.log(data);
		console.log("*********************************");
	}
}
	
@end