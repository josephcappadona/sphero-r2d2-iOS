//
//  CommandSequencerV2.swift
//  PlaygroundContent
//
//  Created by Jeff Payan on 2017-06-23.
//  Copyright © 2017 Sphero Inc. All rights reserved.
//

import Foundation

private struct CommandV2ResponseParser {
    func parseData(_ data: Data) -> CommandResponseV2? {
        
        let payload = data[5..<data.count-2]
        let deviceId = data[2]
        let commandId = data[3]
        
        switch deviceId {
        case DeviceId.sensor.rawValue:
            switch commandId {
            case SensorCommandIds.sensorResponse.rawValue:
                return SensorDataCommandResponseV2(data: Data(payload))
                
            case SensorCommandIds.collisionDetectedAsync.rawValue:
                return CollisionDataCommandResponse(data: [UInt8](payload))
                
            default:
                break
            }
            
        case DeviceId.systemInfo.rawValue:
            switch commandId {
            case SystemInfoCommandIds.mainApplicationVersion.rawValue:
                return VersionsCommandResponseV2(Data(payload))
            default:
                break
            }
            
        case DeviceId.powerInfo.rawValue:
            switch commandId {
            case PowerCommandIds.wake.rawValue:
                return WakeCommandResponse()
                
            case PowerCommandIds.batteryVoltage.rawValue:
                return BatteryVoltageResponse(Data(payload))
               
            case PowerCommandIds.sleep.rawValue:
                return DidSleepResponseV2()
                
            default:
                break
            }
        
        case DeviceId.animatronics.rawValue:
            switch commandId {
            case AnimatronicsCommandIds.shoulderActionComplete.rawValue:
                return ShouldActionCompleteResponse(Data(payload))
                
            default:
                break
            }
            
        default:
            break
        }
        
        return nil
    }
}

public final class CommandSequencerV2 {
    private enum ParsingState {
        case waitingForStartOfPacket
        case waitingForEndOfPacket
    }
    
    private var parsingState = ParsingState.waitingForStartOfPacket
    private var isEscaped = false
    private var currentData = [UInt8]()
    private var skippedData = false
    private var checksum: UInt8 = 0
    
    public typealias ParserCallback = ((_ sequencer: CommandSequencerV2, _ response: CommandResponseV2?) -> Void)
    
    fileprivate var commandSequenceNumber = UInt8(0)
    fileprivate func getNextSequenceNumber() -> UInt8 {
        let returnVal = commandSequenceNumber
        commandSequenceNumber = commandSequenceNumber &+ 1
        return returnVal
    }
    
    private var parserCallback: ParserCallback?
    private var parser: CommandV2ResponseParser = CommandV2ResponseParser()
    
    public func parseResponseFromToy(_ data: Data, callback: ParserCallback?) {
        parserCallback = callback
        for byte in [UInt8](data) {
            processByte(byte: byte)
        }
    }
    
    private func processByte(byte: UInt8) {
        var byteCopy = byte
        if currentData.count == 0 {
            if byte != APIV2Constants.startOfPacket {
                skippedData = true
                print("current data was empty but first byte was not SOP")
                return
            }
        }
        
        switch byte {
        case APIV2Constants.startOfPacket:
            if parsingState != .waitingForStartOfPacket {
                print("got SOP but parser state was not waiting for it")
                reset()
                return
            }
            
            if skippedData {
                skippedData = false
                print("skipped data, not sure what this means")
            }
            
            parsingState = .waitingForEndOfPacket
            checksum = 0
            currentData.append(byteCopy)
            return
            
        case APIV2Constants.endOfPacket:
            currentData.append(byteCopy)

            if parsingState != .waitingForEndOfPacket || currentData.count < 7 {
                print("got EOP but parser state was not waiting for it")
                reset()
                return
            }
            
            if checksum != 0xFF {
                reset()
                return
            }
            
            let data = Data(bytes: currentData)
            reset()
            
            let response = parser.parseData(data)
            parserCallback?(self, response)
            
            return
            
        case APIV2Constants.escape:
            if isEscaped {
                print("got an escape while already escaped. panic!")
                reset()
                return
            }
            
            isEscaped = true
            return
            
        case APIV2Constants.escapedStartOfPacket:
            fallthrough
            
        case APIV2Constants.escapedEndOfPacket:
            fallthrough
            
        case APIV2Constants.escapedEscape:
            if isEscaped {
                byteCopy = byte | APIV2Constants.escapeMask
                isEscaped = false
            }
            break
            
        default:
            break
        }
        
        if isEscaped {
            print("escaped when I shouldnt be!")
            reset()
            return
        }
        
        currentData.append(byteCopy)
        checksum =  checksum &+ byteCopy
    }
    
    
    private func reset() {
        parsingState = .waitingForStartOfPacket
        isEscaped = false
        currentData.removeAll()
    }
}

public protocol CommandResponseV2 {}

public struct CommandV2Flags: OptionSet {
    public let rawValue: UInt8
    
    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }
    
    static let isResponse = CommandV2Flags(rawValue: 1)
    static let requestsResponse = CommandV2Flags(rawValue: 2)
    static let requestsOnlyErrorResponse = CommandV2Flags(rawValue: 2 << 1)
    static let resetsInactivityTimeout = CommandV2Flags(rawValue: 2 << 2)
    
    static let defaultFlags: CommandV2Flags = [.requestsResponse, .resetsInactivityTimeout]
}

public struct APIV2Constants {
    static let escape: UInt8 = 0xAB
    static let startOfPacket: UInt8 = 0x8D
    static let endOfPacket: UInt8 = 0xD8
    
    static let escapeMask: UInt8 = 0x88
    static let escapedEscape = APIV2Constants.escape & ~APIV2Constants.escapeMask
    static let escapedStartOfPacket = APIV2Constants.startOfPacket & ~APIV2Constants.escapeMask
    static let escapedEndOfPacket = APIV2Constants.endOfPacket & ~APIV2Constants.escapeMask
}

extension CommandSequencerV2 {
    public func encodeBytes(_ data: inout [UInt8], byte: UInt8) {
        switch byte {
        case APIV2Constants.startOfPacket:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedStartOfPacket)
            
        case APIV2Constants.endOfPacket:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedEndOfPacket)
            
        case APIV2Constants.escape:
            data.append(APIV2Constants.escape)
            data.append(APIV2Constants.escapedEscape)
            
        default:
            data.append(byte)
        }
    }
    
    public func data(from command: CommandV2) -> Data {
        var bytes = [UInt8]()
        bytes.append(APIV2Constants.startOfPacket)
        
        var checksum: UInt8 = 0x00
        encodeBytes(&bytes, byte: command.commandFlags.rawValue)
        checksum += command.commandFlags.rawValue
        
        encodeBytes(&bytes, byte: command.deviceId)
        checksum += command.deviceId
        
        encodeBytes(&bytes, byte: command.commandId)
        checksum += command.commandId
        
        let sequenceNumber = getNextSequenceNumber()
        encodeBytes(&bytes, byte: sequenceNumber)
        checksum = checksum &+ sequenceNumber
        
        if let commandPayload = command.payload {
            let dataBytes = [UInt8](commandPayload)
            for byte in dataBytes {
                encodeBytes(&bytes, byte: byte)
                checksum = checksum &+ byte
            }
        }
        
        checksum = ~checksum
        encodeBytes(&bytes, byte: checksum)
        bytes.append(APIV2Constants.endOfPacket)
        
        return Data(bytes)
    }
}
