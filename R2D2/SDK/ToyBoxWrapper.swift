//
//  SPRKToyBoxWrapper.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-17.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import Foundation

public class ToyBoxWrapper {
    
    public typealias ConnectionCallback = ((_ toy: ToyWrapper) -> Void)
    
    private var connectionCallbacks: [ConnectionCallback] = []
    
    public init() {}
    
    public func addConnectionCallback(callback: @escaping ConnectionCallback) {
        connectionCallbacks.append(callback)
    }
    
    public func readyToy() {
        print("ready toy")
    }
    
}
