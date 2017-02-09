//
//  KLPInjector.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/15/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import "KLPStandardInjector.h"
#import <objc/runtime.h>
#import "KLPStandardDependencyGraph.h"

static NSString* prefix = @"injected";

@implementation KLPStandardInjector {
    NSMutableDictionary* registeredObjects;
    NSMutableDictionary* registeredValues;
    NSMutableDictionary* trackedObjects;
    id<KLPValueSetter> valueSetter;
    id<KLPDependencyGraph> dependencyGraph;
}

- (id)init {
    self = [super init];
    self->registeredObjects = [[NSMutableDictionary alloc] init];
    self->registeredValues = [[NSMutableDictionary alloc] init];
    self->valueSetter = [[KLPStandardValueSetter alloc] init];
    self->dependencyGraph = [[KLPStandardDependencyGraph alloc] init];
    return self;
}

- (void) setValueSetter:(id<KLPValueSetter>)setter {
    self->valueSetter = setter;
}

+ (NSString*)getPostfixWithId:(NSString*)identifier {
    return identifier != nil ? [separator stringByAppendingString: identifier] : @"";
}

- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier explicitRegistration:(BOOL)explicitRegistration {
    @synchronized (self) {
        NSString* typeString = type != nil ? NSStringFromClass(*type) : @"";
        NSString* postfix = [KLPStandardInjector getPostfixWithId:identifier];
        
        Class currentClass = [object class];
        while (YES) {
            NSString* key = [[NSStringFromClass(currentClass) stringByAppendingString: typeString] stringByAppendingString: postfix];
            registeredObjects[key] = object;
            currentClass = [currentClass superclass];
            if (currentClass == [NSObject class] || !explicitRegistration || currentClass == nil) {
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
}

+(NSString*) extractSwiftRepresentation:(NSString*) type {
    NSString* regString = @"_Tt.[0-9]+(.+)[0-9]+(.+)";
    NSRegularExpression* extraction = [NSRegularExpression regularExpressionWithPattern:regString options:0 error:NULL];
    
    NSArray* matches = [extraction matchesInString:type options:0 range:NSMakeRange(0, [type length])];
    NSTextCheckingResult* matchesResult = [matches objectAtIndex:0];
    
    NSRange nameRange = [matchesResult rangeAtIndex:1];
    NSRange classRange = [matchesResult rangeAtIndex:2];
    
    NSString* projectName = [type substringWithRange:nameRange];
    NSString* className = [type substringWithRange:classRange];
    
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
        if (currentClass == [NSObject class] || currentClass == nil) {
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

- (void) registerObject:(id) dependentObject withValue:(id) value mainClass:(Class) main forField:(NSString*) field   {
    Class currentClass = main;
    do {
        if (trackedObjects[NSStringFromClass(currentClass)] != nil) {
            NSString* key = [[NSStringFromClass(currentClass) stringByAppendingString:separator] stringByAppendingString:field];
            registeredValues[key] = value;
            [dependencyGraph registerDependency:dependentObject forClass:main forField:field];
        }
        currentClass = [currentClass superclass];
    } while(currentClass != [NSObject class] && currentClass != nil);
}

- (void)inject:(id)into {
    @synchronized (self) {
        NSArray* names, *types, *objectTypes;
        [KLPStandardInjector getFieldsOfObject:into names:&names types:&types objectTypes:&objectTypes];
        
        for (NSUInteger i = 0; i < [names count]; i++) {
            NSString* name = [names objectAtIndex:i];
            NSString* type = [types objectAtIndex:i];
            
            Class typeClass = NSClassFromString(type);
            
            if ([name hasPrefix:prefix]) {
                NSString* minimalKey = type;
                
                BOOL skip = NO;
                for (NSString* key in registeredObjects) {
                    NSString* identifier = [self getIdFromKey:key];
                    if (identifier != nil && [name localizedCaseInsensitiveContainsString:identifier]) {
                        [valueSetter setValue:into forValue:registeredObjects[key] forKey:name];
                        [self registerObject:into withValue:registeredObjects[key] mainClass:typeClass forField:name];
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
                        [self registerObject:into withValue:registeredObjects[extendedKey] mainClass:typeClass forField:name];
                        skip = YES;
                        break;
                    }
                }
                
                if (skip) {
                    continue;
                }
                
                if (registeredObjects[minimalKey] != nil) {
                    [valueSetter setValue:into forValue:registeredObjects[minimalKey] forKey:name];
                    [self registerObject:into withValue:registeredObjects[minimalKey] mainClass:typeClass forField:name];
                } else {
                    @throw [NSException
                            exceptionWithName:@"Unknown Object"
                            reason:@"Object wasn't registered"
                            userInfo:nil];
                }
            }
        }
    }
    
}

- (void) setDependencyTracking:(BOOL) active forClass:(Class) objectType explicit:(BOOL) explicitTracking {
    Class objectClass = [objectType class];
    do {
        NSString* key = NSStringFromClass(objectClass);
        trackedObjects[key] = active ? [NSNumber numberWithBool:active] : nil;
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && explicitTracking && objectClass != nil);
}

- (void) setDependencyGraph:(id<KLPDependencyGraph>) graph {
    self->dependencyGraph = graph;
}

- (void) reinjectObjectIntoDependentObjects:(Class) objectType explicitReinjection:(BOOL) explicitReinjection {
    NSDictionary* dependentObjects = [dependencyGraph getDependentObjects:objectType];
    Class objectClass = [objectType class];
    
    NSMutableArray* classes = [[NSMutableArray alloc] init];
    NSMutableArray* fieldNames = [[NSMutableArray alloc] init];
    NSMutableArray* originalKeys = [[NSMutableArray alloc] init];
    
    for (NSString* key in dependentObjects) {
        [originalKeys addObject:key];
        
        NSArray* splitted = [key componentsSeparatedByString:separator];
        
        NSString* cls = splitted[0];
        NSString* field = splitted[1];
        
        [classes addObject:NSClassFromString(cls)];
        [fieldNames addObject:field];
    }
    
    do {
        NSString* key = NSStringFromClass(objectClass);
        if (trackedObjects[key] == nil) {
            continue;
        }
        
        for (NSUInteger i = 0; i < [fieldNames count]; i++) {
            Class cls = classes[i];
            NSString* field = fieldNames[i];
            
            if (cls == objectClass) {
                NSString* originalKey = originalKeys[i];
                NSString* key = [[NSStringFromClass(cls) stringByAppendingString:separator] stringByAppendingString:field];
                [valueSetter setValue:dependentObjects[originalKey] forValue:registeredValues[key] forKey:field];
            }
        }
        
        objectClass = [objectClass superclass];
    } while(objectClass != [NSObject class] && explicitReinjection && objectClass != nil);
}
@end
