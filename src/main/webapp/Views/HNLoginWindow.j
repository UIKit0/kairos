/*
 *  HNLoginWindow.j
 *  Mail
 *
 *  Author: Ignacio Cases
 *
 *  Copyright Ignacio Cases 2010. All rights reserved.
 *  Used with permission of the copyright holder.
 */

@import <Foundation/Foundation.j>
@import "../Views/HNAuxiliarWindow.j"

var SharedLoginWindow = nil;

@implementation HNLoginWindow : HNAuxiliarWindow
{
    @outlet CPTextField       usernameField @accessors;
    @outlet CPSecureTextField passwordField @accessors;
    @outlet CPTextField       emailLabel @accessors;
    @outlet CPTextField       passwordLabel @accessors;
}

+ (id)sharedLoginWindow
{
    return SharedLoginWindow;
}

- (void)awakeFromCib
{
    SharedLoginWindow = self;
    
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(loggedIn:)
                                                 name:HNUserAuthenticationDidChangeNotification
                                               object:nil];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateErrorField:)
                                                 name:HNUserAuthenticationErrorNotification
                                               object:nil];
    
    // The initial state of login is not enabled
    [defaultButton setEnabled:NO];
    [errorMessageField setTextColor:[CPColor redColor]];
    
    // Localization
	[self localizeWindow];
}

- (void) localizeWindow {
	//[theWindow setTitle:[[TNLocalizationCenter defaultCenter] localize:@"Login"]];
	//[labelTitle setObjectValue:[[TNLocalizationCenter defaultCenter] localize:@"Mail App"]];
	[welcomeLabel setObjectValue:[[CPString alloc] initWithFormat:[[TNLocalizationCenter defaultCenter] localize:@"%@ Mail Server"], @"Smartmobili"]];
	[emailLabel setStringValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"E-mail"]]];
	[passwordLabel setStringValue:[[CPString alloc] initWithFormat:@"%@:", [[TNLocalizationCenter defaultCenter] localize:@"Password"]]];
	[defaultButton setTitle:[[TNLocalizationCenter defaultCenter] localize:@"Login"]];
}

- (IBAction) relocalizeWindow: (id) sender {
	[TNLocalizationCenter defaultCenter]._currentLanguage = sender._title;
	[self localizeWindow];
}

- (@action)orderFront:(id)sender
{
    [super orderFront:sender];
    // FIXME: these values are for development only
    // change these values to none and defaultButton visibility to NO
    [usernameField setStringValue:@"webguest@smartmobili.com"];
    [passwordField setStringValue:@"webguest78"];
    [defaultButton setEnabled:YES];
}

- (@action)login:(id)sender
{
    var authenticationController = [HNAuthController sharedController];
    [authenticationController setUsername:[usernameField stringValue]];
    [authenticationController setPassword:[passwordField stringValue]];

    [progressIndicator setHidden:NO];
    [errorMessageField setHidden:YES];
    [authenticationController findWithUsername:[usernameField stringValue]
                                      password:[passwordField stringValue]];

    //var githubController = [GithubAPIController sharedController];
//    [githubController setUsername:[[self usernameField] stringValue]];
//    [githubController setAuthenticationToken:[[self apiTokenField] stringValue]];
//
//    [githubController authenticateWithCallback:function(success)
//    {
//        [progressIndicator setHidden:YES];
//        [errorMessageField setHidden:success];
//        [defaultButton setEnabled:YES];
//        [cancelButton setEnabled:YES];
//
//        if (success)
//        {
//            [[[NewRepoWindow sharedNewRepoWindow] errorMessageField] setHidden:YES];
//            [self orderOut:self];
//        }
//    }];
//    
//    [errorMessageField setHidden:YES];

//    [defaultButton setEnabled:NO];
//    [cancelButton setEnabled:NO];
}

- (void)loggedIn:(CPNotification)notification 
{
    [self orderOut:self];
}

- (void)controlTextDidChange:(CPNotification)aNote
{
    if ([aNote object] !== passwordField && [aNote object] !== usernameField)
        return;

    if (![usernameField stringValue] || ![passwordField stringValue])
        [defaultButton setEnabled:NO];
    else if ([usernameField stringValue] && [passwordField stringValue]){
        if (![self checkUsername]) {
            [defaultButton setEnabled:NO];
            [errorMessageField setStringValue:@"Please check your username"];
            [errorMessageField setHidden:NO];
        } else {
            [defaultButton setEnabled:YES];
            [errorMessageField setHidden:YES];
        }
    }
}

- (void)updateErrorField:(CPNotification)notification
{
    [progressIndicator setHidden:YES];
    [errorMessageField setStringValue:[[notification object] objectForKey:@"message"]];
    [errorMessageField setHidden:NO];
}

-(BOOL)checkUsername 
{
	var email = [[usernameField stringValue] lowercaseString];
	if ([email length] > 0) {
        return [self validateEmail:email compliantRFC2822:NO];
	}
	return NO;
}

-(BOOL)validateEmail:(CPString)email compliantRFC2822:(BOOL)compliant
{ 
    var emailRegExp;
    var isValid = NO;
    
    if (compliant) {
        // RFC2822 compliant 
        emailRegExp = new RegExp("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?");
    } else {
        //emailRegExp = new RegExp("^[a-zA-Z0-9._-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$");
        emailRegExp = new RegExp("^[a-zA-Z0-9._-]+@smartmobili.com");
    }
    
    if (email.match(emailRegExp)) {
        isValid = YES;
    }
    return isValid;
}

@end
