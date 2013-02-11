
/*
 *  AboutPanelController.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@import <AppKit/CPWindowController.j>

@implementation AboutPanelController : CPWindowController
{
    @outlet CPButton northButton;
    @outlet CPButton cappuccinoButton;
    @outlet CPButton cardanoButton;
    @outlet CPButton scalaButton;
    @outlet CPButton liftButton;
}

- (void)awakeFromCib
{
    var panel = [self window],
    contentView = [panel contentView];

    var buttons = [northButton, cappuccinoButton, cardanoButton, scalaButton, liftButton],
    bundle = [CPBundle mainBundle],
    arrowImage = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"AboutBoxArrow.png"] size:CGSizeMake(16, 16)],
    arrowImageHighlighted = [[CPImage alloc] initWithContentsOfFile:[bundle pathForResource:"AboutBoxArrowHighlighted.png"] size:CGSizeMake(16, 16)];

    for (var i = 0, count = buttons.length; i < count; i++)
    {
        var button = buttons[i];
        [button setBordered:NO];
        [button setAlignment:CPLeftTextAlignment];
        [button setFont:[CPFont boldSystemFontOfSize:12.0]];
        [button setImage:arrowImage];
        [button setAlternateImage:arrowImageHighlighted];
        [button setImagePosition:CPImageRight];
    }
}

- (IBAction)open280north:(id)sender
{
    OPEN_LINK("http://280north.com");
}

- (IBAction)openCappuccino:(id)sender
{
    OPEN_LINK("http://cappuccino.org");
}

- (IBAction)openCardano:(id)sender
{
    OPEN_LINK("http://github.com/ignaciocases");
}

- (IBAction)openScala:(id)sender
{
    OPEN_LINK("http://scala-lang.org");
}

- (IBAction)openLift:(id)sender
{
    OPEN_LINK("http://liftweb.net");
}


@end

OPEN_LINK = function(link)
{
    if ([CPPlatform isBrowser])
        window.open(link);
    else
        window.location = link;
}
