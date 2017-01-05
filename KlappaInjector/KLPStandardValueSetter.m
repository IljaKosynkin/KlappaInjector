//
//  KLPStandardValueSetter.m
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#import "KLPStandardValueSetter.h"

@implementation KLPStandardValueSetter
- (void) setValue:(id)forObject forValue:(id)value forKey:(NSString*)key {
    if ([forObject isKindOfClass:[NSObject class]]) {
        NSObject* object = (NSObject*) forObject;
        
        @try {
            [object setValue:value forKey:key];
        } @catch (NSException *exception) {
            
        }
    }
}
@end
