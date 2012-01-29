/*
 *  AppController.j
 *  Mail
 *
 *  Author: Victor Kazarinov <oobe@kazarinov.biz>
 *
 *  Copyright 2012 Smartmobili. All rights reserved.
 */

@import <AppKit/AppKit.j>


@implementation ServerConnection : CPObject
{
    id              _delegate;
    SEL             _didEndSelector;
}

#pragma mark -
#pragma mark CPURLConnecion 
-(void)connection:(CPURLConnection)connection didFailWithError:(id)error
{
    // TODO: (need send to error selector).
    alert("error connection");
}

-(void)connection:(CPURLConnection)connection didReceiveResponse:(CPHTTPURLResponse)response
{
//  alert("response");
}

-(void)connection:(CPURLConnection)connection didReceiveData:(CPString)data
{
    // TODO: what if didRecieveData will be called several times? Perhaps need to aggreggate data and use only at DidFinishLoading
    
    if (_delegate)
    if (_didEndSelector)
    {
        var jsObject = [data objectFromJSON];
                 objj_msgSend(_delegate, _didEndSelector, self, jsObject /*TODO accomodated data with severalDidrecieve data and call this in connectionDidFinishLoading?*/);
    }
}

-(void)connectionDidFinishLoading:(CPURLConnection)connection
{
//  alert("did finish");
}

#pragma mark -
#pragma mark Commands From Client to Server
- (void) callRemoteFunction:(CPString)functionNameToCall withFunctionParametersAsObject:functionParametersInObject delegate:(id)aDelegate didEndSelector:(SEL)aSelector error:(id)aError
{
    _delegate = aDelegate;
    _didEndSelector = aSelector;
    
    var request = [[CPURLRequest alloc] initWithURL:@"postRequest"]; // TODO: need add random subparameter to avoid caching ?
    [request setHTTPMethod:@"POST"];
    
    var functionParametersInJSON = nil;
    if (functionParametersInObject)
        functionParametersInJSON = [CPString JSONFromObject:functionParametersInObject];
    var jsonObjectToPost = { "functionNameToCall" : functionNameToCall,
        "functionParameters"  : functionParametersInJSON };
    
    [request setHTTPBody:[CPString JSONFromObject:jsonObjectToPost]];
    
    var urlConnection = [CPURLConnection connectionWithRequest:request delegate:self];
    [urlConnection start];
}

@end