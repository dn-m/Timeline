//
//  Power.swift
//  ArithmeticTools
//
//  Created by James Bean on 3/2/16.
//  Copyright © 2016 James Bean. All rights reserved.
//

import Foundation

/**
 >`closestPowerOfTwo(to: 13) -> 16`
 
 - note: If two values are equidistant from the target value, the lesser value is returned.
 
 >`closestPowerOfTwo(to: 12) -> 8 (not 16)`
 
 - returns: Power-of-two value closest to target value
 */
public func closestPowerOfTwo(to target: Int) -> Int? {
    return closestPowerOfTwo(withCoefficient: 2, to: target)
}


/**
 - returns: Power-of-two value closest to and less than target value
 */
public func closestPowerOfTwo(under target: Int) -> Int? {
    return closestPowerOfTwo(withCoefficient: 2, under: target)
}

/**
 >`closestPowerOfTwo(withCoefficient: 3, to: 22) -> 24`

 - note: If two values are equidistant from the target value, the lesser value is returned.
 
 >`closestPowerOfTwo(withCoefficient: 3, to: 18) -> 12 (not 24)`
 
 - parameter coefficient: Coefficient of exponential expression
 - parameter target:      Value to check for closest power-of-two
 
 - returns: Power-of-two value (with coefficient) closest to target value
 */
public func closestPowerOfTwo(withCoefficient coefficient: Int, to target: Int) -> Int? {
    
    let pseq = Array(PowerSequence(coefficient: coefficient, max: target, doOvershoot: true))
    
    guard !pseq.isEmpty else {
        return nil
    }
    
    guard let lastPair = pseq.last(amount: 2) else {
        return pseq.first!
    }
    
    return closer(to: target, a: lastPair[0], b: lastPair[1])
}

/**
 - returns: Power-of-two (with coefficient) closest to and less than target value
 */
public func closestPowerOfTwo(withCoefficient coefficient: Int, under target: Int) -> Int? {
    
    let pseq = Array(PowerSequence(coefficient: coefficient, max: target, doOvershoot: false))
    
    guard !pseq.isEmpty else {
        return nil
    }
    
    guard let lastPair = pseq.last(amount: 2) else {
        return pseq.first!
    }
    
    return closer(to: target, a: lastPair[0], b: lastPair[1])
}
