//
//  NSObject+MKOFoundation.h
//  MKOFoundation
//
//  Created by Simon Taylor on 2/12/12.
//  Copyright (c) 2012 Mako Technology Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^MKOFoundationObserverCallback)(NSDictionary* change);

@protocol MKOFoundationObserverProxy <NSObject>

// Receptionist implementation similar to that described in https://developer.apple.com/library/ios/#documentation/Cocoa/Conceptual/CocoaFundamentals/CocoaDesignPatterns/CocoaDesignPatterns.html
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object callback:(MKOFoundationObserverCallback)callback;
- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object options:(NSKeyValueObservingOptions)options callback:(MKOFoundationObserverCallback)callback;
- (void)removeObserverForKeyPath:(NSString*)keyPath ofObject:(id)object;
- (void)removeObserverOfObject:(id)object;

// Similar utility for notifications
- (void)observeNotificationWithName:(NSString*)name object:(id)object queue:(NSOperationQueue*)queue usingBlock:(void (^)(NSNotification *note))block;
- (void)removeObserverForName:(NSString *)aName object:(id)anObject;

@end

@interface NSObject (MKOFoundation)

- (id)mko_observerProxy;

@end
