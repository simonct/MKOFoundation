//
//  MKODownloader.m
//  MKOFoundation
//
//  Created by Simon Taylor on 16/07/10.
//  Copyright (c) 2010 Mako Technology. All rights reserved.
//
//  Simple helper class to asynchronously download a URL to a stream

#import "MKODownloader.h"

#define MKO_VERBOSE_LOGGING 1

@interface MKODownloader ()
@property (nonatomic,retain) NSURLConnection* connection;
@property (nonatomic,retain) NSError* error;
@property (nonatomic,assign) BOOL complete;
@end

@implementation MKODownloader

@synthesize connection = _connection;
@synthesize error = _error;
@synthesize complete = _complete;
@synthesize output = _output;

static NSString* const kDownloaderRunLoopMode = @"kDownloaderRunLoopMode";

+ (NSSet*)keyPathsForValuesAffectingCompleted
{
	return [NSSet setWithObjects:@"complete",@"error",nil];
}

- (id)initWithURL:(NSURL*)url
{
	self = [super init];
	if (self){
		_request = [[NSURLRequest alloc] initWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:30];
		_connection = [[NSURLConnection alloc] initWithRequest:_request delegate:self startImmediately:NO];
	}
	return self;
}

- (void) dealloc
{
	[_request release];
	[_connection release];
	[_error release];
	[_output release];
	[super dealloc];
}

- (BOOL)completed
{
	return (self.complete || self.error);
}

- (NSURL*)url
{
	return _request.URL;
}

- (void)cancel
{
	[self.connection cancel];
}

- (void)download
{
	[self.output open];
	[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[self.connection start];
}

- (void)downloadSync
{
	[self.output open];
	[self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:kDownloaderRunLoopMode];
	[self.connection start];
	while (!_complete && !self.error && [[NSRunLoop currentRunLoop] runMode:kDownloaderRunLoopMode beforeDate:[NSDate distantFuture]]) {
#if MKO_VERBOSE_LOGGING
		NSLog(@"running");
#endif
	}
	[self.connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:kDownloaderRunLoopMode];
#if MKO_VERBOSE_LOGGING
	NSLog(@"completed");
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
#if MKO_VERBOSE_LOGGING
	if ([response isKindOfClass:[NSHTTPURLResponse class]]){
		NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
		NSLog(@"didReceiveResponse: %@ (%d)",[httpResp MIMEType],[httpResp statusCode]);
	}else {
		NSLog(@"didReceiveResponse: %@",[response MIMEType]);
	}
#endif
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
#if MKO_VERBOSE_LOGGING
	NSLog(@"didReceiveData: %d",[data length]);
#endif
	_total += [data length];
	NSInteger total = 0;
	if (self.output) while (total < [data length] && !self.error) {
		const NSInteger count = [self.output write:([data bytes] + total) maxLength:([data length] - total)];
		if (count < 0){
			self.error = [self.output streamError];
		}else {
			total += count;
		}
	}
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
#if MKO_VERBOSE_LOGGING
	NSLog(@"connectionDidFinishLoading");
#endif
	self.complete = YES;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
#if MKO_VERBOSE_LOGGING
	NSLog(@"didFailWithError: %@",error);
#endif
	self.error = error;
}

@end

