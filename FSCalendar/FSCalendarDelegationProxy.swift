//
//  FSCalendarDelegationProxy.m
//  FSCalendar
//
//  Created by dingwenchao on 11/12/2016.
//  Copyright © 2016 Wenchao Ding. All rights reserved.
//

//#import "FSCalendarDelegationProxy.h"
//#import <objc/runtime.h>

class FSCalendarDelegationProxy : NSProxy {

    var delegation:AnyObject
    var protocol:Protocol
    var deprecations:NSDictionary

    init() {
        return self
    }

    func respondsToSelector(selector:SEL) -> Bool {
        var responds:Bool = self.delegation.respondsToSelector(selector)
        if !responds {responds = self.delegation.respondsToSelector(self.deprecatedSelectorOfSelector(selector))}
        if !responds {responds = super.respondsToSelector(selector)}
        return responds
    }

    func conformsToProtocol(protocol:Protocol!) -> Bool {
        return self.delegation.conformsToProtocol(protocol)
    }

    func forwardInvocation(invocation:NSInvocation!) {
        var selector:SEL = invocation.selector
        if !self.delegation.respondsToSelector(selector) {
            selector = self.deprecatedSelectorOfSelector(selector)
            invocation.selector = selector
        }
        if self.delegation.respondsToSelector(selector) {
            invocation.invokeWithTarget(self.delegation)
        }
    }

    func methodSignatureForSelector(sel:SEL) -> NSMethodSignature! {
        if self.delegation.respondsToSelector(sel) {
            return (self.delegation as! NSObject).methodSignatureForSelector(sel)
        }
        let selector:SEL = self.deprecatedSelectorOfSelector(sel)
        if self.delegation.respondsToSelector(selector) {
            return (self.delegation as! NSObject).methodSignatureForSelector(selector)
        }
#if TARGET_INTERFACE_BUILDER
        return NSObject.methodSignatureForSelector(Selector("init"))
#else
        let desc:$(type:struct:) = protocol_getMethodDescription(self.protocol, sel, false, true)
        let types:Int8! = desc.types
        return types?NSMethodSignature.signatureWithObjCTypes(types):NSObject.methodSignatureForSelector(Selector("init"))
#endif
    }

    func deprecatedSelectorOfSelector(selector:SEL) -> SEL {
        var selectorString:String! = NSStringFromSelector(selector)
        selectorString = self.deprecations[selectorString]
        return NSSelectorFromString(selectorString)
    }
}
