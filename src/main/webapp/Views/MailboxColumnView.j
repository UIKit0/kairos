/*
 *  MailboxColumnView.j
 *  Mail
 *
 *  Authors: Ariel Patschiki, Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>

@import "SMBadgeView.j"
@import "../Categories/LocalizedString.j"

var DEBUG_BADGES = NO,
    ExtraWidgetMargin = 3.0,
    IconSpace = 20.0;

@implementation MailboxColumnView : CPView
{
    id          delegate @accessors;
    CPTextView  label;

    SMBadgeView unread;
    CPImageView imageView;
    CPButton    button;

    id          target @accessors;
    id          action @accessors;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 4, 16, 16)];
        [self addSubview:imageView];

        label = [[CPTextField alloc] init];
        [label setAutoresizingMask:CPViewWidthSizable];
        [label setSendsActionOnEndEditing:YES];
        [self addSubview:label];

        unread = [[SMBadgeView alloc] initWithFrame:CGRectMake(150, 4.0, 15, 17)];
        [unread setHidden:YES];
        [self addSubview:unread];

        [label setTarget:self];
        [label setAction:@selector(labelAction:)];
    }
    return self;
}

- (void)layoutSubviews
{
    var mainBundle = [CPBundle mainBundle];
    if (label == nil)
        return;

    if ([self hasThemeState:CPThemeStateSelectedDataView])
    {
        [unread setThemeState:CPThemeStateSelectedDataView];
        // Selected
        if (label._tag == 1)
        {
            [label setTextColor:[CPColor whiteColor]];
            [label setTextShadowColor:[CPColor colorWithRed:103 / 255.0 green:110 / 255.0 blue:122 / 255.0 alpha:1]];
            [label setFont:[CPFont boldSystemFontOfSize:12.0]];
        }
    }
    else
    {
       [unread unsetThemeState:CPThemeStateSelectedDataView];
        // Not selected
        if (label._tag == 1)
        {
            [label setTextColor:[CPColor blackColor]];
            [label setTextShadowColor:nil];
            [label setFont:[CPFont systemFontOfSize:12.0]];
        }
    }

    // Right-align the badge - it might change size.
    [unread setFrameOrigin:CGPointMake(CGRectGetWidth([self bounds]) - ExtraWidgetMargin - CGRectGetWidth([unread bounds]), [unread frame].origin.y)];

    // Use a larger frame when editing.
    var x = [imageView image] ? IconSpace : 3.0;
    if ([label isBezeled])
        [label setFrame:CGRectMake(x, -2.0, CGRectGetWidth([self bounds]) - x - ExtraWidgetMargin, 28.0)];
    else
        [label setFrame:CGRectMake(x, 3.0, CGRectGetWidth([self bounds]) - x - ExtraWidgetMargin, 24)];

}

- (void)setObjectValue:(id)item
{
    var mainBundle = [CPBundle mainBundle],
        isHeader = [item isHeader];

    if (isHeader)
    {
        // Header Label
        [label setFont:[CPFont boldSystemFontOfSize:11.0]];
        [label setTextColor:[CPColor colorWithRed:127 / 255.0 green:140 / 255.0 blue:156 / 255.0 alpha:1]];
        [label setTextShadowOffset:CGSizeMake(0, 1)];
        [label setTextShadowColor:[CPColor whiteColor]];
        [label setTag:0];
        [label setObjectValue:[TNLocalizedString([item name], "Mail source view header") uppercaseString]];
    } else {
        // Mailbox Label
        [label setFont:[CPFont systemFontOfSize:12.0]];
        [label setTextColor:[CPColor blackColor]];
        [label setTextShadowOffset:CGSizeMake(0, 1)];
        [label setTextShadowColor:nil];
        [label setTag:1];
        [label setObjectValue:TNLocalizedString([item name], "Mailbox name")];
    }

    if (isHeader)
    {
        [imageView setHidden:YES];
        [imageView setImage:nil];
    }
    else
    {
        [imageView setHidden:NO];
        // TODO Icon stored in source view class.
        var icon;
        if ([item name] == @"Inbox" || [item name] == @"Sent" || [item name] == @"Trash" || [item name] == @"Drafts" || [item name] == @"Junk")
        {
            icon = [[item name] lowercaseString];
        }
        else
        {
            icon = @"folder";
        }
        var iconPath = [[CPString alloc] initWithFormat:@"Icons/Mailboxes/%@.png", icon],
            image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:iconPath] size:CPSizeMake(16, 16)];
        [imageView setImage:image];
    }

    if (isHeader)
    {
        // Header Label
        [unread setHidden:YES];
    }
    else
    {
        // Mailbox Label
        var count = [[item object] unread];
        [unread setHidden:count == 0];
        [unread setObjectValue:count];
    }

    if (DEBUG_BADGES && !isHeader)
    {
        [unread setObjectValue:9 * ([item name].length - 3)];
        [unread setHidden:NO];
    }

    // Headers can have an optional button.
    button = [item button];
    if (isHeader && button)
    {
        [button setFrameOrigin:CGPointMake(CGRectGetWidth([self bounds]) - ExtraWidgetMargin - CGRectGetWidth([button bounds]),  CGRectGetHeight([self bounds]) / 2.0 - CGRectGetHeight([button bounds]) / 2.0)];
        [button setAutoresizingMask:CPViewMinXMargin];
        [self addSubview:button];
    }

    [self setNeedsLayout];
}

- (BOOL)isKindOfClass:aClass
{
    // Pretend we're a text field so that column editing works.
    return [label isKindOfClass:aClass] || [super isKindOfClass:aClass];
}

- (void)setBezeled:(BOOL)aFlag
{
    [label setBezeled:aFlag];
    [self setNeedsLayout];
}

- (void)controlTextDidBlur:(CPNotification)aNotification	
{
    // Pretend we were the text field which just blurred.
    if ([delegate respondsToSelector:@selector(controlTextDidBlur:)])
        [delegate controlTextDidBlur:[CPNotification notificationWithName:CPTextFieldDidBlurNotification object:self userInfo:nil]];
}

- (void)setEditable:(BOOL)aFlag
{
    [label setEditable:aFlag];

    if (!aFlag)
        [label setSelectable:NO];

    [label setBezeled:aFlag];
}

- (void)setSendsActionOnEndEditing:(BOOL)aFlag
{
}

- (void)setSelectable:(BOOL)aFlag
{
    [label setSelectable:aFlag];
}

- (void)selectText:aSelection
{
    [label selectText:aSelection];
}

- (void)labelAction:(id)sender
{
    // Forward the text field's action to this view's action, for column editing support.
    [CPApp sendAction:action to:target from:self];
}

- (id)objectValue
{
    return [label stringValue];
}

@end

@implementation MailboxColumnView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    if (self = [super initWithCoder:aCoder])
    {
        label = [aCoder decodeObjectForKey:@"label"];
        imageView = [aCoder decodeObjectForKey:@"imageView"];
        unread = [aCoder decodeObjectForKey:@"unread"];
        
         [label setDelegate:self];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:label forKey:@"label"];
    [aCoder encodeObject:imageView forKey:@"imageView"];
    [aCoder encodeObject:unread forKey:@"unread"];
}

@end



