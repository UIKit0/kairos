/*
 *	SMMailContent.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@implementation SMMailContent : CPObject
{
    CPString from @accessors;
    CPString subject @accessors;
    CPDate date @accessors;
    CPString to @accessors;
    CPString toJoin @accessors;
    CPString cc @accessors;
    CPString bcc @accessors;
    CPString body @accessors;
    BOOL isSeen @accessors;
    CPArray  attachment @accessors;
}

@end

@implementation SMMailContent (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self=[super init];
    
    self.from = [aCoder decodeStringForKey:@"from"];
    self.subject = [aCoder decodeStringForKey:@"subject"];
    self.date = [aCoder decodeDateForKey:@"date"];
    self.to = [aCoder decodeStringForKey:@"to"];
    self.toJoin = [aCoder decodeStringForKey:@"toJoin"];
    self.cc = [aCoder decodeStringForKey:@"cc"];
    self.bcc = [aCoder decodeStringForKey:@"bcc"];
    self.body = [aCoder decodeStringForKey:@"body"];
    self.isSeen = [aCoder decodeBoolForKey:@"isSeen"];
    self.attachment = [aCoder decodeObjectForKey:@"attachment"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeString:self.from forKey:@"from"];
    [aCoder encodeString:self.subject forKey:@"subject"];
    [aCoder encodeDate:self.date forKey:@"date"];
    [aCoder encodeString:self.to forKey:@"to"];	
    [aCoder encodeString:self.toJoin forKey:@"toJoin"];	
    [aCoder encodeString:self.cc forKey:@"cc"];	
    [aCoder encodeString:self.bcc forKey:@"bcc"];	
    [aCoder encodeString:self.body forKey:@"body"];
    [aCoder encodeBool:self.isSeen forKey:@"isSeen"];
    [aCoder encodeObject:self.attachment forKey:@"attachment"];
}
@end
