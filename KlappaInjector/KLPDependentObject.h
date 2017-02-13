//
//  KLPDependentObject.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/10/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface KLPDependentObject : NSObject
@property(weak) id object;
@property NSString* fieldName;
@end
