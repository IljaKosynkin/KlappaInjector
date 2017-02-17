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
#import <UIKit/UIKit.h>

static NSString* prefix = @"injected";

@implementation KLPStandardInjector {
    NSMutableDictionary* registeredObjects;
    NSMutableDictionary* trackedObjects;
    NSMutableDictionary* excludedClasses;
    id<KLPValueSetter> valueSetter;
    id<KLPDependencyGraph> dependencyGraph;
}

- (id)init {
    self = [super init];
    self->registeredObjects = [[NSMutableDictionary alloc] init];
    self->valueSetter = [[KLPStandardValueSetter alloc] init];
    self->trackedObjects = [[NSMutableDictionary alloc] init];
    self->excludedClasses = [[NSMutableDictionary alloc] init];
    self->dependencyGraph = [[KLPStandardDependencyGraph alloc] init];
    
    [self addExcludedClass:[NSObject class]];
    [self addExcludedClass:[UIView class]];
    [self addExcludedClass:[UIViewController class]];
    [self addExcludedClass:[UINavigationController class]];
    
    return self;
}

- (void) addExcludedClass:(Class) excluded {
    excludedClasses[NSStringFromClass(excluded)] = @YES;
}

- (void) setValueSetter:(id<KLPValueSetter>)setter {
    self->valueSetter = setter;
}

- (NSString*)getPostfixWithId:(NSString*)identifier {
    return identifier != nil ? [separator stringByAppendingString: identifier] : @"";
}

- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier explicitRegistration:(BOOL)explicitRegistration {
    @synchronized (self) {
        NSString* typeString = type != nil ? NSStringFromClass(*type) : @"";
        NSString* postfix = [self getPostfixWithId:identifier];
        
        Class currentClass = [object class];
        while (YES) {
            NSString* key = [[NSStringFromClass(currentClass) stringByAppendingString: typeString] stringByAppendingString: postfix];
            registeredObjects[key] = object;
            currentClass = [currentClass superclass];
            if (excludedClasses[NSStringFromClass(currentClass)] != nil || !explicitRegistration || currentClass == nil) {
                break;
            }
        }
        
        
        if (explicitRegistration) {
            unsigned count;
            __unsafe_unretained Protocol **pl = class_copyProtocolList([object class], &count);
            
            for (unsigned i = 0; i < count; i++) {
                NSString* protocolName = [NSString stringWithUTF8String: protocol_getName(pl[i])];
                NSString* key = [[protocolName stringByAppendingString: typeString] stringByAppendingString: [self getPostfixWithId:identifier]];
                registeredObjects[key] = object;
            }
            
            free(pl);
        }
        
        return self;
    }
}

- (NSString*) extractSwiftRepresentation:(NSString*) type {
    NSString* projectName = [NSString stringWithUTF8String:getprogname()];
    NSRange range = [type rangeOfString:projectName];
    NSString* secondPart = [type substringFromIndex:range.location + range.length];
    NSRange projectOccurence = [secondPart rangeOfString:projectName];
    
    NSString* stringWithNumber;
    if (projectOccurence.location != NSNotFound) {
        stringWithNumber = [secondPart substringToIndex:projectOccurence.location];
    } else {
        stringWithNumber = secondPart;
    }
    
    NSRegularExpression* regex = [NSRegularExpression regularExpressionWithPattern:@"([0-9]+).*"                                                                           options:0 error:NULL];
    NSTextCheckingResult* match = [regex firstMatchInString:stringWithNumber options:0 range:NSMakeRange(0, [stringWithNumber length])];
    NSString* extractedNumber = [stringWithNumber substringWithRange:[match rangeAtIndex:1]];
    int parsedValue = [extractedNumber intValue];
    
    NSString* className = [secondPart substringWithRange:NSMakeRange([extractedNumber length], parsedValue)];
    return [[projectName stringByAppendingString:@"."] stringByAppendingString:className];
}

- (void) getTypeAndNameFromProperty:(objc_property_t) property name:(NSString**) name type:(NSString**) type {
    *name = [NSString stringWithUTF8String: property_getName(property)];
    if (![*name hasPrefix:prefix]) {
        return;
    }
    
    NSString* rawType = [NSString stringWithUTF8String: property_getAttributes(property)];
        
    NSArray * attributes = [rawType componentsSeparatedByString:@"\""];
    NSString * parsedType = [attributes objectAtIndex:1];
    parsedType = [[parsedType componentsSeparatedByString:@"\""] objectAtIndex:0];
        
    NSRegularExpression* protocolCheck = [NSRegularExpression regularExpressionWithPattern:@".*<(.*)>.*" options:NSRegularExpressionCaseInsensitive error:nil];
    NSTextCheckingResult *result = [protocolCheck firstMatchInString:parsedType options:NSMatchingReportCompletion range:NSMakeRange(0, parsedType.length)];
    
    if ([result numberOfRanges] > 0) {
        parsedType = [parsedType substringWithRange:[result rangeAtIndex:1]];
    }
        
    if ([parsedType hasPrefix:@"_Tt"]) {
        parsedType = [self extractSwiftRepresentation:parsedType];
    }
    
    *type = parsedType;
}

- (void) getFieldsOfClass:(Class)class names:(NSMutableArray**) names types:(NSMutableArray**) types {
    unsigned int count;
    
    objc_property_t* props = class_copyPropertyList(class, &count);
    for (int i = 0; i < count; i++) {
        objc_property_t property = props[i];
        
        NSString* name, *type;
        [self getTypeAndNameFromProperty:property name:&name type:&type];
        if ([name hasPrefix:prefix]) {
            [*names addObject:name];
            [*types addObject:type];
        }
    }
    
    free(props);
}

- (void) getFieldsOfObject:(id)object names:(NSArray**) fieldNames types:(NSArray**) typesOfFields objectTypes:(NSArray**) objectTypes {
    NSMutableArray* names = [[NSMutableArray alloc] init];
    NSMutableArray* types = [[NSMutableArray alloc] init];
    NSMutableArray* objTypes = [[NSMutableArray alloc] init];
    
    Class currentClass = [object class];
    while (YES) {
        [objTypes addObject:currentClass];
        [self getFieldsOfClass:currentClass names:&names types:&types];
        currentClass = [currentClass superclass];
        if (excludedClasses[NSStringFromClass(currentClass)] != nil || currentClass == nil) {
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

- (void) registerObject:(id) dependentObject encodedType:(NSString*) encodedType forField:(NSString*) field   {
    Class currentClass = NSClassFromString(encodedType);
    if (currentClass == nil) {
        if (trackedObjects[encodedType] != nil) {
            [dependencyGraph registerObject:dependentObject encodedType:encodedType forField:field];
        }
        return;
    }
    
    NSString* key = NSStringFromClass(currentClass);
    do {
        if (trackedObjects[key] != nil) {
            [dependencyGraph registerDependency:dependentObject forClass:currentClass forField:field];
        }
        currentClass = [currentClass superclass];
        key = NSStringFromClass(currentClass);
    } while(excludedClasses[key] == nil && currentClass != nil);
}

- (void) injectToProperty:(id) object type:(NSString*) type fieldName:(NSString*) name objectTypes:(NSArray*) objectTypes {
    if ([name hasPrefix:prefix]) {
        NSString* minimalKey = type;
        
        BOOL skip = NO;
        for (NSString* key in registeredObjects) {
            NSString* identifier = [self getIdFromKey:key];
            if (identifier != nil && [name localizedCaseInsensitiveContainsString:identifier]) {
                [valueSetter setValue:object forValue:registeredObjects[key] forKey:name];
                [self registerObject:object encodedType:type forField:name];
                skip = YES;
                break;
            }
        }
        
        if (skip) {
            return;
        }
        
        for (NSUInteger j = 0; j < [objectTypes count]; j++) {
            Class currentClass = [objectTypes objectAtIndex:j];
            NSString* extendedKey = [type stringByAppendingString:NSStringFromClass(currentClass)];
            if (registeredObjects[extendedKey] != nil) {
                [valueSetter setValue:object forValue:registeredObjects[extendedKey] forKey:name];
                [self registerObject:object encodedType:type forField:name];
                skip = YES;
                break;
            }
        }
        
        if (skip) {
            return;
        }
        
        if (registeredObjects[minimalKey] != nil) {
            [valueSetter setValue:object forValue:registeredObjects[minimalKey] forKey:name];
            [self registerObject:object encodedType:type forField:name];
        } else {
            @throw [NSException
                    exceptionWithName:@"Unknown Object"
                    reason:@"Object wasn't registered"
                    userInfo:nil];
        }
    }

}

- (void) inject:(id)into {
    @synchronized (self) {
        NSArray* names, *types, *objectTypes;
        [self getFieldsOfObject:into names:&names types:&types objectTypes:&objectTypes];
        
        for (NSUInteger i = 0; i < [names count]; i++) {
            NSString* name = [names objectAtIndex:i];
            NSString* type = [types objectAtIndex:i];
            
            [self injectToProperty:into type:type fieldName:name objectTypes:objectTypes];
        }
    }
    
}

- (void) setDependencyTracking:(BOOL) active forClass:(Class) objectType explicit:(BOOL) explicitTracking {
    Class objectClass = [objectType class];
    NSString* key = NSStringFromClass(objectClass);
    do {
        trackedObjects[key] = active ? [NSNumber numberWithBool:active] : nil;
        
        if (explicitTracking) {
            unsigned count;
            __unsafe_unretained Protocol **pl = class_copyProtocolList(objectClass, &count);
            
            for (unsigned i = 0; i < count; i++) {
                NSString* protocolName = [NSString stringWithUTF8String: protocol_getName(pl[i])];
                trackedObjects[protocolName] = active ? [NSNumber numberWithBool:active] : nil;
            }
            
            free(pl);
        }
        
        objectClass = [objectClass superclass];
        key = NSStringFromClass(objectClass);
    } while(excludedClasses[key] == nil && explicitTracking && objectClass != nil);
}

- (void) setDependencyGraph:(id<KLPDependencyGraph>) graph {
    self->dependencyGraph = graph;
}

- (void) reinjectObjectIntoDependentObjects:(Class) objectType explicitReinjection:(BOOL) explicitReinjection {
    Class objectClass = [objectType class];
    
    NSMutableArray* objectTypes = [[NSMutableArray alloc] init];
    NSString* key = NSStringFromClass(objectClass);
    do {
        if (trackedObjects[key] == nil) {
            objectClass = [objectClass superclass];
            continue;
        }
        
        [objectTypes addObject:objectClass];
        objectClass = [objectClass superclass];
        key = NSStringFromClass(objectClass);
    } while(excludedClasses[key] == nil && explicitReinjection && objectClass != nil);
    
    for (Class objectType in objectTypes) {
        NSArray* dependentObjects = [dependencyGraph getDependentObjects:objectType];
        for (KLPDependentObject* dependent in dependentObjects) {
            objc_property_t property = class_getProperty([dependent.object class], [dependent.fieldName UTF8String]);
        
            NSString* name, *type;
            [self getTypeAndNameFromProperty:property name:&name type:&type];
            [self injectToProperty:dependent.object type:type fieldName:name objectTypes:objectTypes];
        }
    }
}
@end
