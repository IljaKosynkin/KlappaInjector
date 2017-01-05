//
//  KLPValueSetter.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/27/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPValueSetter_h
#define KLPValueSetter_h

#import <Foundation/Foundation.h>

@protocol KLPValueSetter <NSObject>
- (void) setValue:(id)forObject forValue:(id)value forKey:(NSString*)key;
@end

#endif
