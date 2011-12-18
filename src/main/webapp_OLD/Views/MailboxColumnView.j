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

@implementation MailboxColumnView: CPView 
{
	UITextView label;
	UITextView unread;
	UIImageView unreadImageView;
	UIImageView imageView;
}

- (id)initWithFrame:(CGRect)frame 
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)layoutSubviews {
	var mainBundle = [CPBundle mainBundle];
	if (label == nil) {
		return;
	}
	if ([self hasThemeState:CPThemeStateSelectedDataView]) {
		// Selected
		if (label._tag == 1) {
			[label setTextColor:[CPColor whiteColor]];
			[label setTextShadowColor:[CPColor colorWithRed:103 / 255.0 green:110 / 255.0 blue:122 / 255.0 alpha:1]];
			[label setFont:[CPFont boldSystemFontOfSize:12.0]];
			//
			[unreadImageView setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/marker_selected.png"] size:CPSizeMake(24, 14)]];
			[unread setTextColor:[CPColor colorWithRed:62 / 255.0 green:142 / 255.0 blue:208 / 255.0 alpha:1]];
		}
	} else {
		// Not selected
		if (label._tag == 1) {
			[label setTextColor:[CPColor blackColor]];
			[label setTextShadowColor:[CPColor clearColor]];
			[label setFont:[CPFont systemFontOfSize:12.0]];
			//
			[unreadImageView setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/marker.png"] size:CPSizeMake(20, 14)]];
			[unread setTextColor:[CPColor whiteColor]];
		}
	}
}

- (void)setObjectValue:(id)anObject {

	var mainBundle = [CPBundle mainBundle];
	var isHeader = ([anObject name] == @"Mailboxes" || [anObject name] == @"Others");
	// Label
	if (label == nil) {
		label = [[CPTextField alloc] init];
		[self addSubview:label];
	}
	if (isHeader) {
		// Header Label
		[label setFrame:CGRectMake(3, 3, 500, 24)];
		[label setFont:[CPFont boldSystemFontOfSize:11.0]];
		[label setTextColor:[CPColor colorWithRed:127 / 255.0 green:140 / 255.0 blue:156 / 255.0 alpha:1]];
		[label setTextShadowOffset:CGSizeMake(1, 1)];
		[label setTextShadowColor:[CPColor whiteColor]];
		[label setTag:0];
        [label setObjectValue:[[anObject locale] uppercaseString]];
	} else {
		// Mailbox Label
		[label setFrame:CGRectMake(20, 3, 500, 24)];
		[label setFont:[CPFont systemFontOfSize:12.0]];
		[label setTextColor:[CPColor blackColor]];
		[label setTextShadowOffset:CGSizeMake(1, 1)];
		[label setTextShadowColor:[CPColor clearColor]];
		[label setTag:1];
        [label setObjectValue:[anObject locale]];
	}
	// Image
	if (imageView == nil) {
		var imageView = [[CPImageView alloc] initWithFrame:CGRectMake(0, 4, 16, 16)];
		[self addSubview:imageView];
	}
	if (isHeader) {
		[imageView setHidden:YES];
	} else {
		[imageView setHidden:NO];
		var icon;
		if ([anObject name] == @"Inbox" || [anObject name] == @"Sent" || [anObject name] == @"Trash" || [anObject name] == @"Drafts" || [anObject name] == @"Junk") {
			icon = [[anObject name] lowercaseString];
		} else {
			icon = @"folder";
		}
		var iconPath = [[CPString alloc] initWithFormat:@"Icons/Mailboxes/%@.png", icon];
		var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:iconPath] size:CPSizeMake(16, 16)];
		[imageView setImage:image];
	}
	// Unread marker
	if (unread == nil) {
		var unreadImageView = [[CPImageView alloc] initWithFrame:CGRectMake(145, 4, 20, 14)];
		[unreadImageView setAutoresizingMask: CPViewMinXMargin];
		[unreadImageView setImage:[[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/marker.png"] size:CPSizeMake(20, 14)]];
		[self addSubview:unreadImageView];
        
		unread = [[CPTextField alloc] init];
		[unread setAutoresizingMask: CPViewMinXMargin];
        //		[unread setValue:CPCenterTextAlignment forThemeAttribute:@"alignment"];
		[unread setFrame:CGRectMake(150, 3, 200, 20)];
		[unread setTextColor:[CPColor whiteColor]];
		[unread setFont:[CPFont boldSystemFontOfSize:10.0]];
		[self addSubview:unread];
	}
	
	if (isHeader || [anObject unread] == 0) {
		// Header Label
		[unread setHidden:YES];
		[unreadImageView setHidden:YES];
	} else {
		// Mailbox Label
		[unread setHidden:NO];
		[unreadImageView setHidden:NO];
		[unread setObjectValue:[anObject unread]];
	}
    
}

- (void)drawRect:(CPRect)aRect {
    // Drawing code here.
}

@end