/*
 *  SMPagerView.j
 *  Mail
 *
 *  Author: Alexander Ljungberg, SlevenBits Ltd.
 *
 *  Copyright 2011 Smartmobili. All rights reserved.
 */

@implementation SMPagerView : CPView
{
    CPSegmentedControl  navigationSegmentedControl;

    int                 page @accessors;
    int                 pages @accessors;

    id                  delegate @accessors;
}

- (id)initWithFrame:(CGRect)aRect
{
    if (self = [super initWithFrame:aRect])
    {
        navigationSegmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMakeZero()];
        [navigationSegmentedControl setTrackingMode:CPSegmentSwitchTrackingMomentary];
        [navigationSegmentedControl setSegmentCount:3];
        [self addSubview:navigationSegmentedControl];

        [navigationSegmentedControl setLabel:@"<" forSegment:0];
        [navigationSegmentedControl setLabel:@"1 of 1" forSegment:1];
        [navigationSegmentedControl setLabel:@">" forSegment:2];

        [navigationSegmentedControl setTarget:self];
        [navigationSegmentedControl setAction:@selector(pageWithSegmentedControl:)];

        pages = 40;
        // TODO Just for testing purposes.
        [self setPage:1];
        [self setNeedsLayout];
    }
    return self;
}

- (void)pageWithSegmentedControl:(id)sender
{
    var selectedSegment = [sender selectedSegment];
    if (selectedSegment == 0)
        [self setPage:MAX(0, (page - 1))];
    else if (selectedSegment == 2)
        [self setPage:MIN(pages - 1, (page + 1))];
    alert("Display page " + (1 + page) + " of " + pages);
}

- (void)setPage:(int)aPage
{
    if (page == aPage)
        return;

    page = aPage;
    [self setNeedsLayout];
}

- (void)setPages:(int)pageCount
{
    if (pages == pageCount)
        return;

    pages = pageCount;
    [self setNeedsLayout];
}

- (void)layoutSubviews
{
    [super layoutSubviews];

    [navigationSegmentedControl setLabel:@"" + (1 + page) + " of " + pages forSegment:1];

    [navigationSegmentedControl setFrame:CGRectMake(0, 2, [self frame].size.width, 28)];

    // Allocate space to the middle segment.
    var width = [self bounds].size.width;
    [navigationSegmentedControl setWidth:24.0 forSegment:0];
    [navigationSegmentedControl setWidth:width - 50.0 forSegment:1];
    [navigationSegmentedControl setWidth:24.0 forSegment:2];

    // For some reason the above causes the frame to become slightly too wide, so we have to set
    // it one more time.
    [navigationSegmentedControl setFrame:CGRectMake(0, 2, [self frame].size.width, 28)];

    [navigationSegmentedControl setEnabled:(page > 0) forSegment:0];
    [navigationSegmentedControl setEnabled:(page < pages - 1) forSegment:2];
}

@end

#pragma mark -
#pragma mark CPCoding protocol

@implementation SMPagerView (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super initWithCoder:aCoder];

    if (self)
    {
        navigationSegmentedControl = [aCoder decodeObjectForKey:@"navigationSegmentedControl"];
        pages = [aCoder decodeIntForKey:@"pages"];
        [self setPage:[aCoder decodeIntForKey:@"page"]];

        [self setNeedsLayout];
    }
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [super encodeWithCoder:aCoder];

    [aCoder encodeObject:navigationSegmentedControl forKey:@"navigationSegmentedControl"];
    [aCoder encodeInt:page forKey:@"page"];
    [aCoder encodeInt:pages forKey:@"pages"];
}

@end
