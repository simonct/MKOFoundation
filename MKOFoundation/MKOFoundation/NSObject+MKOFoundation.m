//
//  NSObject+MKOFoundation.m
//  MKOFoundation
//
//  Created by Simon Taylor on 2/12/12.
//  Copyright (c) 2012 Mako Technology Ltd. All rights reserved.
//

#import "NSObject+MKOFoundation.h"
#import <objc/runtime.h>

@interface _MKOFoundationObserverInfo : NSObject
@property (nonatomic,assign) id object;
@property (nonatomic,copy) NSString* keyPath;
@property (nonatomic,copy) MKOFoundationObserverCallback callback;
- (void)observe:(id)anObject keyPath:(NSString*)aKeyPath options:(NSKeyValueObservingOptions)options callback:(MKOFoundationObserverCallback)aCallback ;
- (void)unobserve;
@end
    
@implementation _MKOFoundationObserverInfo

@synthesize object, keyPath, callback;

- (void)dealloc {
    [self unobserve];
    [keyPath release];
    [callback release];
    [super dealloc];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)anObject change:(NSDictionary *)change context:(void *)context {
    if (context == self) {
        if (self.callback){
            self.callback(change);
        }
    } else {
        [super observeValueForKeyPath:aKeyPath ofObject:anObject change:change context:context];
    }
}

- (void)observe:(id)anObject keyPath:(NSString*)aKeyPath options:(NSKeyValueObservingOptions)options callback:(MKOFoundationObserverCallback)aCallback {
    self.object = anObject;
    self.keyPath = aKeyPath;
    self.callback = aCallback;
    [object addObserver:self forKeyPath:aKeyPath options:options context:self];
}

- (void)unobserve {
    [self.object removeObserver:self forKeyPath:self.keyPath context:self];
    self.callback = nil;
    self.object = nil;
    self.keyPath = nil;
}

@end
    
@interface _MKONotificationInfo : NSObject
@property (nonatomic,assign) id object;
@property (nonatomic,strong) id proxy;
@property (nonatomic,copy) NSString* name;
- (void)unobserve;
@end

@implementation _MKONotificationInfo

@synthesize object, proxy, name;

- (void)unobserve {
    [[NSNotificationCenter defaultCenter] removeObserver:self.proxy name:self.name object:self.object];
}

@end

@interface _MKOFoundationObserverProxy : NSObject<MKOFoundationObserverProxy>
@property (nonatomic,retain) NSMutableSet* observers;
@property (nonatomic,retain) NSMutableSet* notificationProxies;
@end
    
@implementation _MKOFoundationObserverProxy

@synthesize observers, notificationProxies;

- (void)dealloc {
        
    [self.observers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKOFoundationObserverInfo* info = obj;
        [info unobserve];
    }];
    [observers release];
    
    [self.notificationProxies enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKONotificationInfo* info = obj;
        [info unobserve];
    }];
    [notificationProxies release];
    
    [super dealloc];
}

- (NSSet*)observersForKeyPath:(NSString*)keyPath onObject:(id)object {
    
    __block NSMutableSet* result = [NSMutableSet setWithCapacity:[self.observers count]];
    [self.observers enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKOFoundationObserverInfo* info = obj;
        if (info.object == object && (!keyPath || [info.keyPath isEqualToString:keyPath])){
            [result addObject:info];
        }
    }];
    return [NSSet setWithSet:result];
}

- (NSSet*)observersForName:(NSString*)name onObject:(id)object {

    __block NSMutableSet* result = [NSMutableSet setWithCapacity:[self.observers count]];
    [self.notificationProxies enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKONotificationInfo* info = obj;
        if (info.object == object && (!name || [info.name isEqualToString:name])){
            [result addObject:info];
        }
    }];
    return [NSSet setWithSet:result];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object callback:(MKOFoundationObserverCallback)callback {
    [self observeValueForKeyPath:keyPath ofObject:object options:0 callback:callback];
}

- (void)observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object options:(NSKeyValueObservingOptions)options callback:(MKOFoundationObserverCallback)callback {
    
    if (!self.observers){
        self.observers = [NSMutableSet setWithCapacity:10];
    }
    
    if (![[self observersForKeyPath:keyPath onObject:object] count]){
        _MKOFoundationObserverInfo* info = [[[_MKOFoundationObserverInfo alloc] init] autorelease];
        [info observe:object keyPath:keyPath options:options callback:callback];
        [self.observers addObject:info];
    }
}

- (void)removeObserverForKeyPath:(NSString*)keyPath ofObject:(id)object {
    [[self observersForKeyPath:keyPath onObject:object] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKOFoundationObserverInfo* info = obj;
        [info unobserve];
        [self.observers removeObject:obj];
    }];
}

- (void)removeObserverOfObject:(id)object {
    [self removeObserverForKeyPath:nil ofObject:object];
}

- (void)observeNotificationWithName:(NSString*)name object:(id)object queue:(NSOperationQueue*)queue usingBlock:(void (^)(NSNotification *note))block {
    
    if (!self.notificationProxies){
        self.notificationProxies = [NSMutableSet setWithCapacity:10];
    }

    _MKONotificationInfo* info = [[[_MKONotificationInfo alloc] init] autorelease];
    info.object = object;
    info.name = name;
    info.proxy = [(NSNotificationCenter*)[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:queue usingBlock:block];

    [self.notificationProxies addObject:info];
}

- (void)removeObserverForName:(NSString *)aName object:(id)anObject {
    
    [[self observersForName:aName onObject:anObject] enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        _MKONotificationInfo* info = obj;
        [info unobserve];
        [self.notificationProxies removeObject:obj];
    }];
}

@end

@implementation NSObject (MKOFoundation)

- (id)mko_observerProxy {
    
    @synchronized(self){
        
        static const char* MKOFoundationObserverProxyKey = "MKOFoundationObserverProxyKey";
        id proxy = objc_getAssociatedObject(self, MKOFoundationObserverProxyKey);
        if (!proxy){
            proxy = [[[_MKOFoundationObserverProxy alloc] init] autorelease];
            objc_setAssociatedObject(self, MKOFoundationObserverProxyKey, proxy, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return proxy;
    }
}

@end
