//
//  MKODownloader.m
//  MKOFoundation
//
//  Created by Simon Taylor on 16/07/10.
//  Copyright (c) 2010 Mako Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKODownloader : NSObject
{
	NSURLRequest* _request;
	NSURLConnection* _connection;
	NSError* _error;
	BOOL _complete;
	NSOutputStream* _output;
	unsigned long long _total;
}

@property (nonatomic,retain) NSOutputStream* output;
@property (nonatomic,readonly) BOOL completed;
@property (nonatomic,retain,readonly) NSError* error;
@property (nonatomic,retain,readonly) NSURL* url;

- (id)initWithURL:(NSURL*)url;

- (void)download;

- (void)cancel;

@end
