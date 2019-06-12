//
//  SPRKToyBoxWrapper.swift
//  spheroArcade
//
//  Created by Anthony Blackman on 2017-03-17.
//  Copyright © 2018 Sphero Inc. All rights reserved.
//

import PlaygroundSupport
import Foundation

public class ToyBoxWrapper: SpheroPlaygroundRemoteLiveViewProxyDelegate {
    
    public typealias ConnectionCallback = ((_ toy: ToyWrapper) -> Void)
    
    private var connectionCallbacks: [ConnectionCallback] = []
    
    public init() {}
    
    public func addConnectionCallback(callback: @escaping ConnectionCallback) {
        connectionCallbacks.append(callback)
    }
    
    public func readyToy() {
        PlaygroundHelpers.setLiveViewProxyDelegate(self)
        
        PlaygroundHelpers.sendMessageToLiveView(
            .dictionary([
                MessageKeys.type: MessageTypeId.connect.playgroundValue()
                ])
        )
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard let dict = message.dictValue(),
            let typeIdValue = dict[MessageKeys.type],
            let typeId = MessageTypeId(value: typeIdValue) else { return }
        
        if typeId == .toyReady,
            let descriptor = dict[MessageKeys.descriptor]?.stringValue() {
            let wrapper = ToyWrapper(descriptor: descriptor)
            wrapper.addCommandListener(ToyMessageSender())
            PlaygroundHelpers.setLiveViewProxyDelegate(wrapper)
            connectionCallbacks.forEach {
                $0(wrapper)
            }
        }
    }
    
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
    }
    
}
