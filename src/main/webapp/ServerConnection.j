/*
 *  AppController.j
 *  Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>


//var defaultServerConnection = nil;


@implementation ServerConnection : CPObject
{
    id              _delegate;
    SEL             _didEndSelector;
}


#pragma mark -
#pragma mark Class methods

/*! return the default ServerConnection controller
    @return default ServerConnection
*/
/*+ (ServerConnection)defaultServerConnection
{
    if (!defaultServerConnection)
        defaultServerConnection = [[ServerConnection alloc] init];

    return defaultServerConnection;
}*/


#pragma mark -
#pragma mark Initialization

/*! initialize a new TNLocalizationCenter
*/
- (TNLocalizationCenter)init
{
    if (self = [super init])
    {
       /* _defaultLanguage    = @"en-us";
        _currentLanguage    = [TNLocalizationCenter navigatorLocale];
        _locales            = [CPDictionary dictionary];

        [self setLocale:GENERAL_LANGUAGE_REGISTRY forDomain:TNLocalizationCenterGeneralLocaleDomain];*/
    }

    return self;
}

#pragma mark -
#pragma mark CPURLConnecion 
-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    // TODO: (need send to errror selector).
    alert("error connection");
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response
{
    alert("response");
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    // TODO: what if didRecieveData will be called several times? Perhaps need to aggreggate data and use only at DidFinishLoading.
    alert(data);
    if (_delegate)
    if (_didEndSelector)
                 objj_msgSend(_delegate, _didEndSelector, self, data /*TODO accomodated data?*/);
}

-(void)connectionDidFinishLoading:(CPURLConnection)connection
{
    alert("did finish");
    
}


#pragma mark -
#pragma mark Commands From Client to Server
- (void) authenticateUser:user withPassword:aPassword delegate:(id)aDelegate didEndSelector:(SEL)aSelector error:(id)aError
{
    _delegate = aDelegate; // THINK: move to common "init" ?
    _didEndSelector = aSelector;
    
    var request = [[CPURLRequest alloc] initWithURL:@"/hi"]; // TODO: random subparameter to avoid caching ?
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:@"aPostData"];
    var urlConnection = [CPURLConnection connectionWithRequest:request delegate:self];
    [urlConnection start];
    
   // if ([_delegate respondsToSelector:@selector(connection:didFailWithError:)])
   //                  [_delegate connection:self didFailWithError:anException];
}


@end