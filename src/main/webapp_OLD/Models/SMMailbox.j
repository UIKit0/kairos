/*
 *	SMMailbox.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@implementation SMMailbox : CPObject
{
    CPString name @accessors;
    CPNumber count @accessors;
    CPNumber unread @accessors;
}

// Designated initializer
- (id)initWithName:(CPString)aName count:(int)total unread:(int)theUnread {
    self = [super init];
    if (self) {
        name = aName;
        count = total;
        unread = theUnread;
    }
    return self;
}

- (BOOL)isDefaultFolder
{    
    var result;
    var lcFoldername = [[self name] lowercaseString]; 
    
    if ([lcFoldername isEqualToString:@"inbox"]	    ||
        [lcFoldername isEqualToString:@"sent"]		||
        [lcFoldername isEqualToString:@"drafts"]	||
        [lcFoldername isEqualToString:@"junk"]		||
        [lcFoldername isEqualToString:@"trash"]) {
        result = YES;
    }
    else {
        result = NO;
    }
    return result;
}

- (CPString)locale {
    var localizedName;
    var locale = [[TNLocalizationCenter defaultCenter] localize:[self name]];
    
    if (locale) {
        localizedName = locale;
    } else {
        localizedName = name;
    }
    return localizedName;
}

@end

@implementation SMMailbox (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self=[super init];
    
    self.name = [aCoder decodeStringForKey:@"name"];
    self.count = [aCoder decodeNumberForKey:@"count"];
    self.unread = [aCoder decodeNumberForKey:@"unread"];
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeString:self.name forKey:@"name"];
	[aCoder encodeNumber:self.count forKey:@"count"];
    [aCoder encodeNumber:self.unread forKey:@"unread"];
}
@end
