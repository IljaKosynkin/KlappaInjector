//
//  KLPStandardValueSetter.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPStandardValueSetter_h
#define KLPStandardValueSetter_h

#import <Foundation/Foundation.h>
#import "KLPValueSetter.h"

@interface KLPStandardValueSetter : NSObject<KLPValueSetter>
- (void) setValue:(id)forObject forValue:(id)value forKey:(NSString*)key;
@end

#endif
