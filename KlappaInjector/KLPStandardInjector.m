//
//  KLPInjector.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/15/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import "KLPStandardInjector.h"
#import <objc/runtime.h>

static NSString* separator = @"_";
static NSString* prefix = @"injected";

@implementation KLPStandardInjector {
    NSMutableDictionary* registeredObjects;
    id<KLPValueSetter> valueSetter;
}

- (id)init {
    self = [super init];
    self->registeredObjects = [[NSMutableDictionary alloc] init];
    self->valueSetter = [[KLPStandardValueSetter alloc] init];
    return self;
}

- (void) setValueSetter:(id<KLPValueSetter>)setter {
    self->valueSetter = setter;
}

+ (NSString*)getPostfixWithId:(NSString*)identifier {
    return identifier != nil ? [separator stringByAppendingString: identifier] : @"";
}

- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier {
    NSString* typeString = type != nil ? NSStringFromClass(*type) : @"";
    NSString* key = [[NSStringFromClass([object class]) stringByAppendingString: typeString] stringByAppendingString: [KLPStandardInjector getPostfixWithId:identifier]];
    registeredObjects[key] = object;
    return self;
}

+(void) getFieldsOfObject:(id)object names:(NSArray**) fieldNames types:(NSArray**) typesOfFields {
    NSMutableArray* names = [[NSMutableArray alloc] init];
    NSMutableArray* types = [[NSMutableArray alloc] init];
    
    unsigned int count;
    objc_property_t* props = class_copyPropertyList([object class], &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        
        NSString * name = [NSString stringWithUTF8String: property_getName(property)];
        NSString * type = [NSString stringWithUTF8String: property_getAttributes(property)];
        
        NSArray * attributes = [type componentsSeparatedByString:@"\""];
        NSString * parsedType = [attributes objectAtIndex:1];
        parsedType = [[parsedType componentsSeparatedByString:@"\""] objectAtIndex:0];
        
        [names addObject: name];
        [types addObject:parsedType];
    }
    
    free(props);
    
    *fieldNames = names;
    *typesOfFields = types;
}

- (NSString*) getIdFromKey:(NSString*)key {
    NSArray* array = [key componentsSeparatedByString:separator];
    return [array count] == 2 ? [array objectAtIndex:1] : nil;
}

- (void)inject:(id)into {
    NSArray* names, *types;
    [KLPStandardInjector getFieldsOfObject:into names:&names types:&types];
    
    for (NSUInteger i = 0; i < [names count]; i++) {
        NSString* name = [names objectAtIndex:i];
        NSString* type = [types objectAtIndex:i];
        
        if ([name hasPrefix:prefix]) {
            NSString* minimalKey = type;
            NSString* extendedKey = [type stringByAppendingString:NSStringFromClass([into class])];
            
            BOOL skip = NO;
            for (NSString* key in registeredObjects) {
                NSString* identifier = [self getIdFromKey:key];
                if (identifier != nil && [name localizedCaseInsensitiveContainsString:identifier]) {
                    [valueSetter setValue:into forValue:registeredObjects[key] forKey:name];
                    skip = YES;
                    break;
                }
            }
            
            if (skip) {
                continue;
            }
            
            if (registeredObjects[extendedKey] != nil) {
                [valueSetter setValue:into forValue:registeredObjects[extendedKey] forKey:name];
            } else if (registeredObjects[minimalKey] != nil) {
                [valueSetter setValue:into forValue:registeredObjects[minimalKey] forKey:name];
            } else {
                @throw [NSException
                        exceptionWithName:@"Unknown Object"
                        reason:@"Object wasn't registered"
                        userInfo:nil];
            }
        }
    }
    
}
@end
