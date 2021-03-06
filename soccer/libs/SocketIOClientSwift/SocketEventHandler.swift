//
//  EventHandler.swift
//  Socket.IO-Client-Swift
//
//  Created by Erik Little on 1/18/15.
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

private func emitAckCallback(_ socket: SocketIOClient, num: Int?) -> SocketAckEmitter? {
    return num != nil ? SocketAckEmitter(socket: socket, ackNum: num!) : nil
}

struct SocketEventHandler {
    let event: String
    let callback: NormalCallback
    let id: UUID
    
    init(event: String, id: UUID = UUID(), callback: @escaping NormalCallback) {
        self.event = event
        self.id = id
        self.callback = callback
    }
    
    func executeCallback(_ items: [AnyObject], withAck ack: Int? = nil, withAckType type: Int? = nil,
        withSocket socket: SocketIOClient) {
                self.callback(items, emitAckCallback(socket, num: ack))
    }
}
