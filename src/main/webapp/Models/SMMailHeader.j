/*
 *	SMMailHeader.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>
@import "../Categories/CPDate+Formatting.j"

@implementation SMMailHeader : CPObject
{
    CPString messageId @accessors;
    CPString subject @accessors;
    CPString fromName @accessors;
    CPString fromEmail @accessors;
    CPDate date @accessors;
    BOOL isSeen @accessors;
    CPString md5 @accessors;
}

- (id)init
{
    self = [super init];
    if (self)
	{
        // Initialization code here.
    }

    return self;
}

@end

@implementation SMMailHeader (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self=[super init];

    self.messageId = [aCoder decodeStringForKey:@"messageId"];
    self.subject = [aCoder decodeStringForKey:@"subject"];
    self.fromName = [aCoder decodeStringForKey:@"fromName"];
    self.fromEmail = [aCoder decodeStringForKey:@"fromEmail"];
    self.date = [aCoder decodeDateForKey:@"date"];
    self.isSeen = [aCoder decodeBoolForKey:@"isSeen"];
    self.md5 = [aCoder decodeStringForKey:@"md5"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeString:self.messageId forKey:@"messageId"];
    [aCoder encodeString:self.subject forKey:@"subject"];
    [aCoder encodeString:self.fromName forKey:@"fromName"];
    [aCoder encodeString:self.fromEmail forKey:@"fromEmail"];
    [aCoder encodeDate:self.date forKey:@"date"];
    [aCoder encodeBool:self.isSeen forKey:@"isSeen"];
    [aCoder encodeString:self.md5 forKey:@"md5"];
}
@end
