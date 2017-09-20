//
//  SocketParser.swift
//  Socket.IO-Client-Swift
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import Foundation

class SocketParser {
    
    fileprivate static func isCorrectNamespace(_ nsp: String, _ socket: SocketIOClient) -> Bool {
        return nsp == socket.nsp
    }
    
    fileprivate static func handleEvent(_ p: SocketPacket, socket: SocketIOClient) {
        guard isCorrectNamespace(p.nsp, socket) else { return }
        
        socket.handleEvent(p.event, data: p.args ?? [],
            isInternalMessage: false, wantsAck: p.id)
    }
    
    fileprivate static func handleAck(_ p: SocketPacket, socket: SocketIOClient) {
        guard isCorrectNamespace(p.nsp, socket) else { return }
        
        socket.handleAck(p.id, data: p.data)
    }
    
    fileprivate static func handleBinary(_ p: SocketPacket, socket: SocketIOClient) {
        guard isCorrectNamespace(p.nsp, socket) else { return }
        
        socket.waitingData.append(p)
    }
    
    fileprivate static func handleConnect(_ p: SocketPacket, socket: SocketIOClient) {
        if p.nsp == "/" && socket.nsp != "/" {
            socket.joinNamespace()
        } else if p.nsp != "/" && socket.nsp == "/" {
            socket.didConnect()
        } else {
            socket.didConnect()
        }
    }
    
    static func parseString(_ message: String) -> SocketPacket? {
        var parser = SocketStringReader(message: message)
        
        guard let type = SocketPacket.PacketType(str: parser.read(1))
            else {return nil}
        
        if !parser.hasNext {
            return SocketPacket(type: type, nsp: "/")
        }
        
        var namespace: String?
        var placeholders = -1
        
        if type == .binaryEvent || type == .binaryAck {
            if let holders = Int(parser.readUntilStringOccurence("-")) {
                placeholders = holders
            } else {
               return nil
            }
        }
        
        if parser.currentCharacter == "/" {
            namespace = parser.readUntilStringOccurence(",") ?? parser.readUntilEnd()
        }
        
        if !parser.hasNext {
            return SocketPacket(type: type, id: -1,
                nsp: namespace ?? "/", placeholders: placeholders)
        }
        
        var idString = ""
        
        while parser.hasNext {
            if let int = Int(parser.read(1)) {
                idString += String(int)
            } else {
                parser.advanceIndexBy(-2)
                break
            }
        }
        
        let d = message[<#T##Collection corresponding to your index##Collection#>.index(parser.currentIndex, offsetBy: 1)..<message.endIndex]
        let noPlaceholders = d["(\\{\"_placeholder\":true,\"num\":(\\d*)\\})"] ~= "\"~~$2\""
        let data = parseData(noPlaceholders) as? [AnyObject] ?? [noPlaceholders]
        
        return SocketPacket(type: type, data: data, id: Int(idString) ?? -1,
            nsp: namespace ?? "/", placeholders: placeholders)
    }
    
    // Parses data for events
    static func parseData(_ data: String) -> AnyObject? {
        let stringData = data.data(using: String.Encoding.utf8, allowLossyConversion: false)
        do {
            return try JSONSerialization.jsonObject(with: stringData!,
                        options: JSONSerialization.ReadingOptions.mutableContainers)
        } catch {
            Logger.error("Parsing JSON: %@", type: "SocketParser", args: data)
            return nil
        }
    }
    
    // Parses messages recieved
    static func parseSocketMessage(_ message: String, socket: SocketIOClient) {
        guard !message.isEmpty else { return }
        
        Logger.log("Parsing %@", type: "SocketParser", args: message)
        
        guard let pack = parseString(message) else {
            Logger.error("Parsing message: %@", type: "SocketParser", args: message)
            return
        }
        
        Logger.log("Decoded packet as: %@", type: "SocketParser", args: pack.description)
        
        switch pack.type {
        case .event:
            handleEvent(pack, socket: socket)
        case .ack:
            handleAck(pack, socket: socket)
        case .binaryEvent:
            handleBinary(pack, socket: socket)
        case .binaryAck:
            handleBinary(pack, socket: socket)
        case .connect:
            handleConnect(pack, socket: socket)
        case .disconnect:
            socket.didDisconnect("Got Disconnect")
        case .error:
            socket.didError("Error: \(pack.data)")
        }

    }
    
    static func parseBinaryData(_ data: Data, socket: SocketIOClient) {
        guard !socket.waitingData.isEmpty else {
            Logger.error("Got data when not remaking packet", type: "SocketParser")
            return
        }
        
        let shouldExecute = socket.waitingData[socket.waitingData.count - 1].addData(data)
        
        guard shouldExecute else {
            return
        }
        
        var packet = socket.waitingData.removeLast()
        packet.fillInPlaceholders()
        
        if packet.type != .binaryAck {
            socket.handleEvent(packet.event, data: packet.args ?? [],
                isInternalMessage: false, wantsAck: packet.id)
        } else {
            socket.handleAck(packet.id, data: packet.args)
        }
    }
}
