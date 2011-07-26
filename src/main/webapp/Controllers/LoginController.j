/*
 *  LoginController.j
 *  Mail
 *
 *  Created by Ariel Patschiki on 05/03/11.
 *  Copyright __MyCompanyName__ 2011. All rights reserved.
*/

@import <AppKit/AppKit.j>
@import <Foundation/Foundation.j>
@import "../Controllers/MailController.j"

@implementation LoginController: CPViewController 
{
	MailController mailController;
    @outlet CPWindow theWindow;
    @outlet CPImageView imageView;
    @outlet CPTextField *labelTitle;
    @outlet CPTextField *labelServer;
    @outlet CPTextField *labelEmail;
    @outlet CPTextField *labelPassword;
    @outlet CPButton *buttonLogin;
    @outlet CPImageView spinner;
    @outlet CPButton *flag1;
    @outlet CPButton *flag2;
    @outlet CPButton *flag3;
}

- (IBAction) relocalizeWindow: (id) sender {
	[TNLocalizationCenter defaultCenter]._currentLanguage = sender._title;
	[self localizeWindow];
}

- (void) localizeWindow {
	[theWindow setTitle:[[TNLocalizationCenter defaultCenter] localize:@"Login"]];
	[labelTitle setObjectValue:[[TNLocalizationCenter defaultCenter] localize:@"Mail App"]];
	[labelServer setObjectValue:[[CPString alloc] initWithFormat:[[TNLocalizationCenter defaultCenter] localize:@"%@ Mail Server"], @"Smartmobili"]];
	[labelEmail setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"E-mail"]]];
	[labelPassword setObjectValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Password"]]];
	[buttonLogin setTitle:[[TNLocalizationCenter defaultCenter] localize:@"Login"]];
}
- (void) awakeFromCib {
	var mainBundle = [CPBundle mainBundle];
	[[TNLocalizationCenter defaultCenter] setLocale:GENERAL_LANGUAGE_REGISTRY forDomain:TNLocalizationCenterGeneralLocaleDomain];
	[self localizeWindow];
	
	// Put the Images
	var image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/MailApp.png"] size:CPSizeMake(128, 128)];
	[imageView setImage:image];

	image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/spinner.gif"] size:CPSizeMake(16, 16)];
	[spinner setImage:image];
	[spinner setHidden:YES];

	image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/Flags/us.png"] size:CPSizeMake(16, 11)];
	[flag1 setImage:image];
	image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/Flags/fr.png"] size:CPSizeMake(16, 11)];
	[flag2 setImage:image];
	image = [[CPImage alloc] initWithContentsOfFile:[mainBundle pathForResource:@"Icons/Flags/br.png"] size:CPSizeMake(16, 11)];
	[flag3 setImage:image];

	//[theWindow center];	
    //[self.theWindow orderOut:self];
}

- (IBAction) login: (id) sender 
{
	[sender setEnabled:NO];
	[spinner setHidden:NO];

	self.mailController.imap = [[Imap alloc] init];
	self.mailController.imap.delegate = self;
	[self.mailController.imap getMailboxes];

}

-(void) gotMailboxes:(Imap) aImap {
	[self.mailController.imap getMailHeaders:@"Inbox"];
	self.mailController.selectedMailBox = @"Inbox";

	[self showMain];
}
- (void) showMain {
	var cib = [[CPCib alloc] initWithContentsOfURL:[[CPBundle mainBundle] pathForResource:@"Mail.cib"]];
	[cib instantiateCibWithExternalNameTable:[CPDictionary dictionaryWithObject:self.mailController forKey:CPCibOwner]];
	
	// Yeah, this here is really wrong!
	document.body.style.backgroundColor = "#ffffff";
	
	[self.theWindow orderOut:self];
}

@end