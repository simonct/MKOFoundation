//
//  MKOJSONSchemaProcessor.h
//  MKOFoundation
//
//  Created by Simon Taylor on 29/12/2011.
//  Copyright (c) 2011 Mako Technology Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MKOJSONSchemaProcessor : NSObject

- (id)initWithSchemaDictionary:(NSDictionary*)schema classPrefix:(NSString*)prefix;

- (id)objectWithDictionary:(NSDictionary*)json entityName:(NSString*)name error:(NSError**)error;

@end
