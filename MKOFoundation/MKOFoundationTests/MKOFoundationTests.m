//
//  MKOFoundationTests.m
//  MKOFoundationTests
//
//  Created by Simon Taylor on 2/12/12.
//  Copyright (c) 2012 Mako Technology Ltd. All rights reserved.
//

#import "MKOFoundationTests.h"
#import "MKOJSONSchemaProcessor.h"

@interface MKOProduct : NSObject {
}
@property (nonatomic,retain) NSMutableDictionary* contents;
@end

@implementation MKOProduct

@synthesize contents;

- (id)init {
    self = [super init];
    if (self) {
        contents = [[NSMutableDictionary alloc] initWithCapacity:10];
    }
    return self;
}

- (void)setValue:(id)value forKey:(NSString *)key {
    [contents setValue:value forKey:key];
}

- (NSString*)description {
    return [contents description];
}

@end

@implementation MKOFoundationTests

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

- (void)testJsonSchemaProcessor
{
    NSError* error = nil;
    
    id schema = [[NSString stringWithContentsOfFile:@"product.schema.txt" usedEncoding:nil error:&error] JSONValue];
    id json = [[NSString stringWithContentsOfFile:@"product.json.txt" usedEncoding:nil error:&error] JSONValue];
    
    MKOJSONSchemaProcessor* proc = [[[MKOJSONSchemaProcessor alloc] initWithSchemaDictionary:schema classPrefix:@"MKO"] autorelease];
    
    id result = [proc objectWithDictionary:json entityName:@"Product" error:&error];
    
    NSLog(@"result = %@",result);
}

@end
