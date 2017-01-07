//
//  KLPInjector.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 12/15/16.
//  Copyright © 2016 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPStandardInjector_h
#define KLPStandardInjector_h

#import <Foundation/Foundation.h>
#import "KLPStandardValueSetter.h"
#import "KLPInjector.h"

@interface KLPStandardInjector : NSObject<KLPInjector>
- (void) setValueSetter:(id<KLPValueSetter>)setter;
- (id<KLPInjector>)registerInjectable:(id)object forType:(Class*)type withId:(NSString*)identifier explicitRegistration:(BOOL)explicitRegistration;
- (void)inject:(id)into;
@end

#endif
