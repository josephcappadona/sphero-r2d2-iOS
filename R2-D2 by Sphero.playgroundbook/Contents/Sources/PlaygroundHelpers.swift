//
//  PageHelper.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-16.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//
// Helper functions to abstract out differences between running in playgrounds app and as an iOS app.


import Foundation
import PlaygroundSupport

// Outside of the switft playgrounds app we don't have a proxy to pass to the proxy delegate
// Instead, have delegates conform to this protocol which doesn't take a proxy,
// and use an extension to implement the method that takes a proxy.
public protocol SpheroPlaygroundRemoteLiveViewProxyDelegate: PlaygroundRemoteLiveViewProxyDelegate {
    func receive(_ message: PlaygroundValue)
    
}

extension SpheroPlaygroundRemoteLiveViewProxyDelegate {
    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        receive(message)
    }
}

// For running outside of swift playgrounds, keep a global delegate
fileprivate var liveViewProxyDelegate: SpheroPlaygroundRemoteLiveViewProxyDelegate? = nil
fileprivate var playgroundQueue: DispatchQueue? = nil

public struct PlaygroundHelpers {
    public static func sendMessageToLiveView(_ message: PlaygroundValue) {
        // For swift playgrounds, pass the message to the proxy.
        if let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy {
            return proxy.send(message)
        }
        
        // For standalone app, pass message directly to the message handler.
        if let handler = PlaygroundPage.current.liveView as? PlaygroundLiveViewMessageHandler {
            DispatchQueue.main.async {
                handler.receive(message)
            }
        }
    }

    public static func setLiveViewProxyDelegate(_ delegate: SpheroPlaygroundRemoteLiveViewProxyDelegate) {
        // For swift playgrounds, set the live view's delegate
        if let proxy = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy {
            proxy.delegate = delegate
            return
        }
        
        // For standalone app, keep the delegate here.
        if let _ = PlaygroundPage.current.liveView as? PlaygroundLiveViewMessageHandler {
            liveViewProxyDelegate = delegate
        }
    }
    
    public static func setPlaygroundDispatchQueue(_ queue: DispatchQueue) {
        playgroundQueue = queue
    }
    
}

// For swift playgrounds, send the message.
extension PlaygroundLiveViewMessageHandler {
    public func sendMessageToContents(_ message: PlaygroundValue) {
        send(message)
    }
}

public protocol PlaygroundSupportMockLiveViewMessageHandler {}

// For standalone app, pass the message to the delegate directly.
extension PlaygroundLiveViewMessageHandler where Self: PlaygroundSupportMockLiveViewMessageHandler {
    public func sendMessageToContents(_ message: PlaygroundValue) {
        if let delegate = liveViewProxyDelegate {
            if let queue = playgroundQueue {
                queue.async { delegate.receive(message) }
            } else {
                delegate.receive(message)
            }
        }
    }
}
