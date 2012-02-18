/*
 *  SMEmailSubjectView
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <Foundation/Foundation.j>

@import <AppKit/CPImage.j>
@import <AppKit/CPImageView.j>
@import <AppKit/CPTextField.j>

@implementation SMEmailSubjectView : CPView
{
    IBOutlet CPTextField emailFrom @accessors;
    IBOutlet CPTextField emailSubject @accessors;
    IBOutlet CPTextField emailDate @accessors;
}

- (void)setObjectValue:(id)anEmail
{
    if (!anEmail)
        return;

    [emailFrom setStringValue:[anEmail from]];
    [emailSubject setStringValue:[anEmail subject]];
    [emailDate setStringValue:[anEmail date]];

//    [emailFrom setValue:[CPColor colorWithHexString:@"929496"] forThemeAttribute:@"text-color"];
//    [emailFrom setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
//
//    [emailDate setValue:[CPColor colorWithHexString:@"929496"] forThemeAttribute:@"text-color"];
//    [emailDate setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
//
//    [emailSubject setValue:[CPColor blackColor] forThemeAttribute:@"text-color"];
//    [emailSubject setValue:[CPColor whiteColor] forThemeAttribute:@"text-color" inState:CPThemeStateSelectedDataView];
//    [emailSubject setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font" inState:CPThemeStateSelectedDataView];

}

- (void)drawRect:(CGRect)aRect
{
    var color = [CPColor whiteColor];
    var subjectColor = [CPColor whiteColor];

    if (![self hasThemeState:CPThemeStateSelectedDataView]) {
        color = [CPColor colorWithRed:176/255 green:178/255 blue:180/255 alpha:1.0];
        subjectColor = [CPColor blackColor];
    }
    [emailSubject setTextColor:subjectColor];
    [emailFrom setTextColor:color];
    [emailDate setTextColor:color];
    //    [emailSubject setValue:[CPFont boldSystemFontOfSize:12] forThemeAttribute:@"font"];
}

#pragma mark -
#pragma mark CPCoding protocol

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        emailFrom = [aCoder decodeObjectForKey:@"emailFrom"];
        emailSubject = [aCoder decodeObjectForKey:@"emailSubject"];
        emailDate = [aCoder decodeObjectForKey:@"emailDate"];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:emailFrom forKey:@"emailFrom"];
    [aCoder encodeObject:emailSubject forKey:@"emailSubject"];
    [aCoder encodeObject:emailDate forKey:@"emailDate"];
}
@end
