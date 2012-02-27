//
//  MKOJSONSchemaProcessor.m
//  MKOFoundation
//
//  Created by Simon Taylor on 29/12/2011.
//  Copyright (c) 2011 Mako Technology Ltd. All rights reserved.
//
//  Work in progress JSON schema processor; see http://tools.ietf.org/html/draft-zyp-json-schema-03

#import "MKOJSONSchemaProcessor.h"

@interface MKOJSONSchemaProcessor ()
@property (nonatomic,copy) NSString* prefix;
@property (nonatomic,retain) NSDictionary* schema;
- (id)processDictionary:(NSDictionary*)json usingDescription:(NSDictionary*)description error:(NSError**)error;
@end

@implementation MKOJSONSchemaProcessor

@synthesize prefix = _prefix;
@synthesize schema = _schema;

- (void)dealloc {
    [_prefix release];
    [_schema release];
    [super dealloc];
}

- (id)initWithSchemaDictionary:(NSDictionary*)schema classPrefix:(NSString*)prefix {
    self = [super init];
    if (self){
        self.prefix = prefix;
        self.schema = schema;
    }
    return self;
}

- (id)objectWithDictionary:(NSDictionary*)json entityName:(NSString*)name error:(NSError**)error {
    
    id result = nil;
    
    NSDictionary* description = self.schema; // [self.schema objectForKey:name];
    if (!description){
        NSLog(@"*** No description for %@",name);
    }
    else {
        result = [self processDictionary:json usingDescription:description error:error]; 
    }
    
    return result;
}

- (id)processDictionary:(NSDictionary*)json usingDescription:(NSDictionary*)description error:(NSError**)error {
    
    id result = nil;
    
    NSString* className = [description objectForKey:@"name"];
    if (self.prefix){
        className = [NSString stringWithFormat:@"%@%@",self.prefix,className];
    }
    
    Class klass = NSClassFromString(className);
    if (!klass){
        NSLog(@"** No class with name %@",className);
    }
    else {
        
        __block id instance = [[klass alloc] init];
        if (!instance){
            NSLog(@"** Failed to create instace of %@",className);
        }
        else {
            
            __block NSError* localError = nil;
            
            __block id (^valueForType)(id type,id key,id value) = ^(id type,id key,id value){

                if ([type isEqualToString:@"number"] || [type isEqualToString:@"integer"] || [type isEqualToString:@"boolean"]){
                    if (![value isKindOfClass:[NSNumber class]]){
                        if ([value isKindOfClass:[NSString class]]){
                            value = [NSNumber numberWithDouble:[value doubleValue]];
                        }
                        else {
                            NSLog(@"Value for key %@ should be a number",key);
                            value = nil;
                        }
                    }
                    // maximum, minimum, etc
                }
                else if ([type isEqualToString:@"string"]){
                    if (![value isKindOfClass:[NSString class]]){
                        NSLog(@"Value for key %@ should be a string",key);
                        value = nil;
                    }
                }
                else if ([type isEqualToString:@"array"]){
                    if (![value isKindOfClass:[NSArray class]]){
                        NSLog(@"Value for key %@ should be an array",key);
                        value = nil;
                    }
                    NSMutableArray* result = [NSMutableArray arrayWithCapacity:[value count]];
                    for (id v in value){
                        v = valueForType(@"string",nil,v);
                        if (v){
                            [result addObject:v];
                        }
                    }
                    value = [NSArray arrayWithArray:result];
                }
                else if ([type isEqualToString:@"object"]){
                    value = [self objectWithDictionary:value entityName:[value objectForKey:@"name"] error:error];
                }
                else if ([type isEqualToString:@"null"]){
                    value = nil;
                }
                else {
                    NSLog(@"Unknown type %@",type);
                    value = nil;
                }
                
                return value;
            };
            
            [[description objectForKey:@"properties"] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                                
                id value = [json objectForKey:key];
                if (value && value == [NSNull null]){
                    value = nil;
                }
                
                // optional
                if (!value){
                    id optional = [obj objectForKey:@"optional"];
                    if (optional && ![optional boolValue]){
                        if (stop) *stop = YES;
                        NSLog(@"Missing mandatory property %@",key);
                    }
                    return;
                }
                
                if (!localError){
                    
                    id type = [obj objectForKey:@"type"];
                    
                    value = valueForType(type,key,value);
                    if (value){
                        [instance setValue:value forKey:key];
                    }
                }
                
                if (localError){
                    if (stop) *stop = YES;
                }
            }];
            
            result = instance;
            
            if (localError && error){
                *error = localError;
            }
        }
    }
    
    return result;
}

@end

