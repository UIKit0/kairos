/*
 *  HNAuxiliarWindow.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright Ignacio Cases 2010. All rights reserved. Portions Copyright 280N Inc.
 *  Used with permission of the copyright holders.
 */

//@import <Foundation/Foundation.j>

@import <AppKit/CPWindow.j>

@implementation HNAuxiliarWindow : CPWindow
{
    @outlet CPTextField welcomeLabel @accessors;
    @outlet CPView      borderView @accessors;
    @outlet CPTextField errorMessageField @accessors;
    @outlet CPView      progressIndicator @accessors;
    @outlet CPButton    defaultButton @accessors;
    @outlet CPButton    cancelButton;
}

- (id)initWithContentRect:(CGRect)aRect styleMask:(unsigned)aMask
{
    //Alexander Ljungberg
    //Text fields can't accept input if your window is not the key window, and you've created a window which cannot become the key window.
    //Either create a CPPanel, a platform window, a window with CPTitledWindowMask or a custom window.
    if (self = [super initWithContentRect:aRect styleMask:CPTitledWindowMask])
    {
        [self center];
        [self setMovableByWindowBackground:YES];
    }

    return self;
}

- (@action)orderFront:(id)sender
{
    [super orderFront:sender];
    [errorMessageField setHidden:YES];
    [progressIndicator setHidden:YES];
}

- (void)setDefaultButton:(CPButton)aButton
{
    [super setDefaultButton:aButton];
    defaultButton = aButton;
}

@end
