# Klappa Injector
This lightweight framework is designed to help iOS developers introduce Dependency Injection, in a easy way, into their projects. It basically allows you to register any object with one method and then inject it into another object with another small method.    
You will find examples of usage below.

# Installation
Project is added to CocoaPods. Just add following line to the Podfile of your project:

    pod ‘KlappaInjector’
And run:
    
     pod install
And you are free to go.
# Property naming 
There is one quite important thing about naming of properties. You cannot give property any arbitrary name - **all injected properties have to start with "injected" keyword.** If there is no such prefix in property name - Injector will not recognise this property as Injectable. There are no other restrictions on properties naming.

## Code examples
### Objective-C
    @property NSObject<TestProtocol>* injectedPropertyProtocol;
    
### Swift
    var injectedNoLimit: Klp!

# Usage
## Objective-C
    #import "KLPStandardInjector.h"
    <...>
    //Object registration
    KLPStandardInjector* injector = [[KLPStandardInjector alloc] init];
    InjectedClass2* injected = [[InjectedClass2 alloc] init];
    [injector registerInjectable:injected forType:nil withId:nil explicitRegistration:YES];
    <...>
    //Injection
    TestObject7* object = [[TestObject7 alloc] init];
    [injector inject:object];
    
## Swift
    import KlappaInjector
    <...>
    //Object registration
    let injector = KLPStandardInjector()
    injector.registerInjectable(TestInjected(), forType: nil, withId: nil, explicitRegistration: true)
    injector.registerInjectable(TestObj(), forType: nil, withId: nil, explicitRegistration: true)
    <...>
    //Injection
    let view = View()
    injector.inject(view)
 
 Thats pretty much it. 
 
# Registration parameters
Examples above shows basic usage of registration. As you can see there are few additional parameters in function registerInjectable that needs to be explained. Let me go over it:

## Type registration
*(Class\*):forType* - defines on instances of which class allowed injection of registered object. It means that if you have, lets say, object of class A and registered it for type of class B - injection to object of class C will be impossible. 

### Code examples
#### Objective-C
    Class testClass2 = [TestObject2 class];
    [injector registerInjectable:class3 forType:&testClass2 withId:nil explicitRegistration:YES];
    
#### Swift
     var cls: AnyClass = View.self
     let pointer = AutoreleasingUnsafeMutablePointer<AnyClass?>.init(&cls)
     injector.registerInjectable(TestInjected(), forType: pointer, withId: nil, explicitRegistration: true)
     
Unfortunately, for Swift such strange syntax is necessary, you cannot omit or inline anything. 

## Object identificator
*(NSString\*):withId* - allows you to inject few objects of one type to one object. Lets say you have two objects of class A that you want to inject into object of class B. Such objects cannot be distinguished by type, so you have to provide explicit identifier that will help Injector to find out which object in which variable it have to inject. Identifier passed in *withId* parameter have to be somewhere in property name. 

### Code examples
#### Objective-C
    @interface TestObject3 : NSObject
    @property InjectedClass4* injectedPropertyFirst;
    @property InjectedClass4* injectedPropertySecond;
    @end

    @implementation TestObject3 
    @end
    <...>
    [injector registerInjectable:class41 forType:&testClass3 withId:@"first" explicitRegistration:YES];
    [injector registerInjectable:class42 forType:&testClass3 withId:@"second" explicitRegistration:YES];
    
#### Swift
    class View: UIView {
        var injectedNoLimitFirst: Klp!
        var injectedNoLimitSecond: Klp!
    }
    <...>
    var cls: AnyClass = View.self
    let pointer = AutoreleasingUnsafeMutablePointer<AnyClass?>.init(&cls)
    injector.registerInjectable(TestInjected(), forType: pointer, withId: "first", explicitRegistration: true)
    injector.registerInjectable(TestInjected(), forType: pointer, withId: "second", explicitRegistration: true)
    let view = View()
    injector.inject(view)
    
## Explicit registration
*(BOOL):explicitRegistration* - controls if object will be registered as it is or if its ancestors will also be taken into account. When YES is passed to explicitRegistration Injector will not only inject object into property of object's type, but also in properties that have object's ancestor type or protocol, to which object confirms, type. If NO was passed - object is registered only for its type. **Use this parameter with care - if two injectable objects have common ancestor and both was registered with explicitRegistration:YES, object that was registered later will override object of base class in Injector's memory.**

### Code examples
#### Objective-C
    @protocol TestProtocol <NSObject>

    @end
    
    @interface InjectedClass2 : NSObject<TestProtocol>

    @end

    @implementation InjectedClass2
    @end
    
    @interface InjectedClass5 : InjectedClass4
    @end

    @implementation InjectedClass5
    @end
    
    @interface TestObject7 : NSObject
    @property NSObject<TestProtocol>* injectedPropertyProtocol;
    @property InjectedClass4* injectedPropertyBaseClass;
    @end

    @implementation TestObject7
    @end
    <...>
    InjectedClass2* class2 = [[InjectedClass2 alloc] init];
    InjectedClass5* class5 = [[InjectedClass5 alloc] init];
    [injector registerInjectable:class2 forType:nil withId:nil explicitRegistration:YES];
    [injector registerInjectable:class5 forType:nil withId:nil explicitRegistration:YES];
    
    
#### Swift
    @objc protocol Klp {
    
    }

    class TestInjected: NSObject, Klp {
    
    }

    class TestObj: NSObject {
    
    }

    class View: UIView {
      var injectedNoLimitFirst: Klp!
      var injectedNoLimitSecond: Klp!
    }
    <...>
    var cls: AnyClass = View.self
    let pointer = AutoreleasingUnsafeMutablePointer<AnyClass?>.init(&cls)
    injector.registerInjectable(TestInjected(), forType: pointer, withId: "first", explicitRegistration: true)
    injector.registerInjectable(TestInjected(), forType: pointer, withId: "second", explicitRegistration: true)
    let view = View()
    injector.inject(view)
    
# Current limitations
If you're using KlappaInjector from Swift **you will have to inherit all your objects from NSObject or descendant from it classes (both injectable and objects to which you want to inject). All protocols have to be marked with @objc to make it compatible with Objective-C protocols.** Reason for this in fact that Swift doesn't have proper and stable reflection API yet. Once it will be released (if it will) - I will make proper version for Swift.    
There are some ways to set value for pure Swift protocol/class field, however I decided to don't do it, since all the ways are pretty fragile and shouldn't be used in production code.

# Errors
Currently there is only one situation in which Injector will throw exception - if there is no registered object for field starting with "injected" keyword.
Any other error is not stipulated. Please, if you get unexpected error or incorrect behaviour - make sure to throw it in issue section with steps to reproduce or sample project/snippet of code that illustrates issue.

# Contributing
All contributions are gratefully and thankfully welcome. If there are some features that you would like to have in KlappaInjector - write it down in issues. If you would like to write such feature by your own - fork project and make PR. Everything will be reviewed, tested and if it's ok - pushed to the main repo.   
There are only two rules that you have to follow while preparing PR:

* Make sure that all existing tests are passing without changes.
* Write at least one test that illustrates and tests new feature.

Thats all.

**Thank you for using KlappaInjector and may the Klappa be with you!**
![alt text](https://pbs.twimg.com/media/BsNAptdCAAEvg0U.png:large "Klappa")
