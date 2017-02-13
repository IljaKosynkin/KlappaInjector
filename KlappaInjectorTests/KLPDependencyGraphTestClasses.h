//
//  KLPDependencyGraphTestClasses.h
//  KlappaInjector
//
//  Created by Ilja Kosynkin on 2/11/17.
//  Copyright © 2017 Ilja Kosynkin. All rights reserved.
//

#ifndef KLPDependencyGraphTestClasses_h
#define KLPDependencyGraphTestClasses_h

@protocol KLPGraphTestingProtocol <NSObject>

@end

@interface KLPGInjectedBaseClass : NSObject

@end

@implementation KLPGInjectedBaseClass

@end

@interface KLPGInjectedSimpleClass : NSObject

@end

@implementation KLPGInjectedSimpleClass

@end


@interface KLPGInjectedClass : KLPGInjectedBaseClass

@end

@implementation KLPGInjectedClass

@end

@interface KLPProtocolClass : NSObject<KLPGraphTestingProtocol>

@end

@implementation KLPProtocolClass

@end

@interface KLPDependentClass : NSObject
@property KLPGInjectedBaseClass* injectedBaseClass;
@property id<KLPGraphTestingProtocol> injectedProtocol;
@property KLPGInjectedSimpleClass* injectedSimpleClass;
@end

@implementation KLPDependentClass

@end

static KLPDependentClass* dependentClass;

#endif /* KLPDependencyGraphTestClasses_h */
