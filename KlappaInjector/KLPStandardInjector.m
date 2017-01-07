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

- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier explicitRegistration:(BOOL)explicitRegistration {
    NSString* typeString = type != nil ? NSStringFromClass(*type) : @"";
    NSString* postfix = [KLPStandardInjector getPostfixWithId:identifier];
    
    Class currentClass = [object class];
    while (YES) {
        NSString* key = [[NSStringFromClass(currentClass) stringByAppendingString: typeString] stringByAppendingString: postfix];
        registeredObjects[key] = object;
        currentClass = [currentClass superclass];
        if (currentClass == [NSObject class] || !explicitRegistration) {
            break;
        }
    }
    
    
    if (explicitRegistration) {
        unsigned count;
        __unsafe_unretained Protocol **pl = class_copyProtocolList([object class], &count);
        
        for (unsigned i = 0; i < count; i++) {
            NSString* protocolName = [NSString stringWithUTF8String: protocol_getName(pl[i])];
            NSString* key = [[protocolName stringByAppendingString: typeString] stringByAppendingString: [KLPStandardInjector getPostfixWithId:identifier]];
            registeredObjects[key] = object;
        }
        
        free(pl);
    }
    
    return self;
}

+(NSString*) extractSwiftRepresentation:(NSString*) type {
    NSString* projectName = [NSString stringWithUTF8String:getprogname()];
    NSString* secondPart = [[type componentsSeparatedByString:projectName] objectAtIndex:1];
    
    NSRegularExpression* classOffset = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+).*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *result = [classOffset firstMatchInString:secondPart options:NSMatchingReportCompletion range:NSMakeRange(0, secondPart.length)];
    NSString* number = [secondPart substringWithRange:[result rangeAtIndex:1]];
    int parsed = [number intValue];
    NSString* className = [secondPart substringWithRange:NSMakeRange([number length], [number length] + parsed - 1)];
    return [[projectName stringByAppendingString:@"."] stringByAppendingString:className];
}

+(void) getFieldsOfClass:(Class)class names:(NSMutableArray**) names types:(NSMutableArray**) types {
    unsigned int count;
    
    objc_property_t* props = class_copyPropertyList(class, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        
        NSString * name = [NSString stringWithUTF8String: property_getName(property)];
        if ([name hasPrefix:prefix]) {
            NSString * type = [NSString stringWithUTF8String: property_getAttributes(property)];
            
            NSArray * attributes = [type componentsSeparatedByString:@"\""];
            NSString * parsedType = [attributes objectAtIndex:1];
            parsedType = [[parsedType componentsSeparatedByString:@"\""] objectAtIndex:0];
            
            NSRegularExpression* protocolCheck = [NSRegularExpression regularExpressionWithPattern:@".*<(.*)>.*" options:NSRegularExpressionCaseInsensitive error:nil];
            NSTextCheckingResult *result = [protocolCheck firstMatchInString:parsedType options:NSMatchingReportCompletion range:NSMakeRange(0, parsedType.length)];
            if ([result numberOfRanges] > 0) {
                parsedType = [parsedType substringWithRange:[result rangeAtIndex:1]];
            }
            
            if ([parsedType hasPrefix:@"_Tt"]) {
                parsedType = [KLPStandardInjector extractSwiftRepresentation:parsedType];
            }
            
            [*names addObject:name];
            [*types addObject:parsedType];
        }
    }
    
    free(props);
}

+(void) getFieldsOfObject:(id)object names:(NSArray**) fieldNames types:(NSArray**) typesOfFields objectTypes:(NSArray**) objectTypes {
    NSMutableArray* names = [[NSMutableArray alloc] init];
    NSMutableArray* types = [[NSMutableArray alloc] init];
    NSMutableArray* objTypes = [[NSMutableArray alloc] init];
    
    Class currentClass = [object class];
    while (YES) {
        [objTypes addObject:currentClass];
        [KLPStandardInjector getFieldsOfClass:currentClass names:&names types:&types];
        currentClass = [currentClass superclass];
        if (currentClass == [NSObject class]) {
            break;
        }
    }
    
    *fieldNames = names;
    *typesOfFields = types;
    *objectTypes = objTypes;
}

- (NSString*) getIdFromKey:(NSString*)key {
    NSArray* array = [key componentsSeparatedByString:separator];
    return [array count] == 2 ? [array objectAtIndex:1] : nil;
}

- (void)inject:(id)into {
    NSArray* names, *types, *objectTypes;
    [KLPStandardInjector getFieldsOfObject:into names:&names types:&types objectTypes:&objectTypes];
    
    for (NSUInteger i = 0; i < [names count]; i++) {
        NSString* name = [names objectAtIndex:i];
        NSString* type = [types objectAtIndex:i];
        
        if ([name hasPrefix:prefix]) {
            NSString* minimalKey = type;
            
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
            
            for (NSUInteger j = 0; j < [objectTypes count]; j++) {
                Class currentClass = [objectTypes objectAtIndex:j];
                NSString* extendedKey = [type stringByAppendingString:NSStringFromClass(currentClass)];
                if (registeredObjects[extendedKey] != nil) {
                    [valueSetter setValue:into forValue:registeredObjects[extendedKey] forKey:name];
                    skip = YES;
                    break;
                }
            }
            
            if (skip) {
                continue;
            }
            
            if (registeredObjects[minimalKey] != nil) {
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
