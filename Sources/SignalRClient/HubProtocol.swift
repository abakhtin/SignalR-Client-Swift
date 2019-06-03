//
//  HubProtocol.swift
//  SignalRClient
//
//  Created by Pawel Kadluczka on 8/27/17.
//  Copyright © 2017 Pawel Kadluczka. All rights reserved.
//

import Foundation

public enum ProtocolType: Int {
    case Text = 1
    case Binary
}

public protocol HubProtocol {
    var name: String { get }
    var version: Int { get }
    var type: ProtocolType { get }
    var typeConverter: TypeConverter { get }
    func parseMessages(input: Data) throws -> [HubMessage]
    func writeMessage(message: HubMessage) throws -> Data
}

public enum MessageType: Int, Codable {
    case Invocation = 1
    case StreamItem = 2
    case Completion = 3
    case StreamInvocation = 4
    case CancelInvocation = 5
    case Ping = 6
    case Close = 7
}

public protocol HubMessage {
    var type: MessageType { get }
}

public class InvocationMessage: HubMessage {
    public let type = MessageType.Invocation
    public let invocationId: String?
    public let target: String
    public let arguments: [Any?]

    convenience init(target: String, arguments: [Any?]) {
        self.init(invocationId: nil, target: target, arguments: arguments)
    }

    init(invocationId: String?, target: String, arguments: [Any?]) {
        self.invocationId = invocationId
        self.target = target
        self.arguments = arguments
    }
}

public class ServerInvocationMessage: HubMessage, Encodable {
    public let type = MessageType.Invocation
    public let invocationId: String?
    public let target: String
    public let arguments: [Encodable]

    convenience init(target: String, arguments: [Encodable]) {
        self.init(invocationId: nil, target: target, arguments: arguments)
    }

    init(invocationId: String?, target: String, arguments: [Encodable]) {
        self.invocationId = invocationId
        self.target = target
        self.arguments = arguments
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(target, forKey: .target)
        try container.encodeIfPresent(invocationId, forKey: .invocationId)

        var argumentsContainer = container.nestedUnkeyedContainer(forKey: .arguments)
        try arguments.forEach {
            try argumentsContainer.encode(AnyEncodable(value:$0))
        }
    }

    enum CodingKeys : String, CodingKey {
        case type
        case target
        case invocationId
        case arguments
    }
}

public class StreamItemMessage: HubMessage {
    public let type = MessageType.StreamItem
    public let invocationId: String
    public let item: Any?

    init(invocationId: String, item: Any?) {
        self.invocationId = invocationId
        self.item = item
    }
}

public class CompletionMessage: HubMessage {
    public let type = MessageType.Completion
    public let invocationId: String
    public let error: String?
    public let hasResult: Bool
    public let result: Any?

    init(invocationId: String) {
        self.invocationId = invocationId
        self.result = nil
        self.error = nil
        self.hasResult = false
    }

    init(invocationId: String, result: Any?) {
        self.invocationId = invocationId
        self.result = result
        self.error = nil
        self.hasResult = true
    }

    init(invocationId: String, error: String) {
        self.invocationId = invocationId
        self.error = error
        self.result = nil
        self.hasResult = false
    }
}

public class StreamInvocationMessage: HubMessage, Encodable {
    public let type = MessageType.StreamInvocation
    public let invocationId: String
    public let target: String
    public let arguments: [Encodable]

    init(invocationId: String, target: String, arguments: [Encodable]) {
        self.invocationId = invocationId
        self.target = target
        self.arguments = arguments
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(type, forKey: .type)
        try container.encode(target, forKey: .target)
        try container.encode(invocationId, forKey: .invocationId)
        var argumentsContainer = container.nestedUnkeyedContainer(forKey: .arguments)
        try arguments.forEach {
            try argumentsContainer.encode(AnyEncodable(value:$0))
        }
    }

    enum CodingKeys : String, CodingKey {
        case type
        case target
        case invocationId
        case arguments
    }
}

public class CancelInvocationMessage: HubMessage, Encodable {
    public let type = MessageType.CancelInvocation
    public let invocationId: String

    init(invocationId: String) {
        self.invocationId = invocationId
    }
}

public class PingMessage : HubMessage {
    public let type = MessageType.Ping
    private init() { }

    static let instance = PingMessage()
}

public class CloseMessage: HubMessage {
    public let type = MessageType.Close
    public let error: String?

    init(error: String?) {
        self.error = error
    }
}
