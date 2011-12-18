/*
 *	Email.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>
//@import <CappuccinoResource/CRBase.j>

@implementation Email : CPObject
{
    CPString uid @accessors;
    CPString date @accessors;
    CPString subject @accessors;

    CPString fromName @accessors;
    CPString fromEmail @accessors;
    CPString senderName @accessors;
    CPString senderEmail @accessors;
    CPString replyToName @accessors;
    CPString replyToEmail @accessors;
    CPString emailToName @accessors;
    CPString emailToEmail @accessors;
    JSObject from;
    JSObject sender;
    JSObject replyTo;
    JSObject to;
}

- (id)init
{
    self = [super init];
    if (self) 
	{
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (CPString)formattedDate {
    CPLog.debug(@"%@", date);
    return date;
}

- (JSObject)attributes
{
    return {"email": {
            "uid": uid,
            "date": date,
            "subject": subject,
            "from": from,
            "sender": {
                "name": senderName,
                "email": senderEmail
            },
            "reply_to": {
                "name": replyToName,
                "email": replyToEmail
            },
            "to": {
                "name": emailToName,
                "email": emailToEmail
            }
        }
    }
}

//- (CPSortDescriptor)sortByName:(Object)other
//{
//    return [[self name] compare:[other name]];
//}

- (CPString)description {
    return [CPString stringWithFormat:@"uid: %@ %@", uid, from];
}

@end