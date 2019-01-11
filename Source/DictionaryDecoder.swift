//
//  DictionaryDecoder.swift
//  DictionaryCoder
//
//  Created by Artem Shimanski on 07/01/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

func unwrap<T>(_ x: Any) -> T {
	return x as! T
}

open class DictionaryDecoder {
	public enum DataDecodingStrategy {
		case data
		case deferredToData
		case base64
		case custom((Decoder) throws -> Data)
	}

	public enum DateDecodingStrategy {
		case deferredToDate
		case secondsSince1970
		case millisecondsSince1970
		case iso8601
		case formatted(DateFormatter)
		case custom((Decoder) throws -> Date)
	}
	
	var dataDecodingStrategy: DataDecodingStrategy = .data
	var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate

	open func decode<T>(_ type: T.Type, from container: Any) throws -> T where T : Decodable {
		return try _Decoder(codingPath: [], container: container, userInfo: [:], dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy).decode(T.self, from: container, forCodingPath: [])
	}
}

extension DictionaryDecoder {
	private struct _Decoder: Decoder {
		var codingPath: [CodingKey]
		
		var userInfo: [CodingUserInfoKey : Any]
		var container: Any
		var dataDecodingStrategy: DataDecodingStrategy = .data
		var dateDecodingStrategy: DateDecodingStrategy = .deferredToDate

		init(codingPath: [CodingKey], container: Any, userInfo: [CodingUserInfoKey : Any], dataDecodingStrategy: DataDecodingStrategy, dateDecodingStrategy: DateDecodingStrategy) {
			self.codingPath = codingPath
			self.userInfo = userInfo
			self.container = container
			self.dataDecodingStrategy = dataDecodingStrategy
			self.dateDecodingStrategy = dateDecodingStrategy
		}
		
		func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key : CodingKey {
			guard let container = container as? [String: Any] else {throw DecodingError.typeMismatch([String: Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
			return KeyedDecodingContainer(_KeyedDecodingContainer(codingPath: codingPath, container: container, decoder: self))
		}
		
		func unkeyedContainer() throws -> UnkeyedDecodingContainer {
			guard let container = container as? [Any] else {throw DecodingError.typeMismatch([Any].self, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
			return _UnkeyedDecodingContainer(codingPath: codingPath, container: container, decoder: self)
		}
		
		func singleValueContainer() throws -> SingleValueDecodingContainer {
			return _SingleValueDecodingContainer(codingPath: codingPath, container: container, decoder: self)
		}
		
		func decode<T>(_ type: T.Type, from container: Any, forCodingPath codingPath: [CodingKey]) throws -> T where T : Decodable {
			switch type {
			case is Data.Type:
				switch dataDecodingStrategy {
				case .data:
					guard let data = container as? T else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return data
				case .deferredToData:
					let decoder = _Decoder(codingPath: codingPath, container: container, userInfo: userInfo, dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
					return try T(from: decoder)
				case .base64:
					guard let string = container as? String, let data = Data(base64Encoded: string, options: []) else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return data as! T
				case let .custom(block):
					let decoder = _Decoder(codingPath: codingPath, container: container, userInfo: userInfo, dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
					return try block(decoder) as! T
				}
			case is Date.Type:
				switch dateDecodingStrategy {
				case .deferredToDate:
					let decoder = _Decoder(codingPath: codingPath, container: container, userInfo: userInfo, dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
					return try T(from: decoder)
				case .millisecondsSince1970:
					guard let t = container as? TimeInterval else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return Date(timeIntervalSince1970: t / 1000) as! T
				case .secondsSince1970:
					guard let t = container as? TimeInterval else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return Date(timeIntervalSince1970: t) as! T
				case .iso8601:
					guard let string = container as? String, let date = iso8601Formatter.date(from: string) else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return date as! T
				case let .formatted(formatter):
					guard let string = container as? String, let date = formatter.date(from: string) else {throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
					return date as! T
				case let .custom(block):
					let decoder = _Decoder(codingPath: codingPath, container: container, userInfo: userInfo, dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
					return try block(decoder) as! T
				}
			default:
				let decoder = _Decoder(codingPath: codingPath, container: container, userInfo: userInfo, dataDecodingStrategy: dataDecodingStrategy, dateDecodingStrategy: dateDecodingStrategy)
				return try T(from: decoder)
			}
		}
	}
	
	private struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
		var codingPath: [CodingKey]
		var container: [String: Any]
		var decoder: _Decoder
		
		var allKeys: [Key] {
			return container.keys.compactMap {Key(stringValue: $0)}
		}
		
		func contains(_ key: Key) -> Bool {
			return container[key.stringValue] != nil
		}
		
		private func get<T>(_ key: CodingKey) throws -> T {
			guard let value = container[key.stringValue].map({unwrap($0) as Any?}) else {throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath + [key], debugDescription: ""))}
			guard let result = value as? T else {throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath + [key], debugDescription: ""))}
			return result
		}
		
		func decodeNil(forKey key: Key) throws -> Bool {
			return try (get(key) as Any?) == nil
		}
		
		func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
			return try get(key)
		}
		
		func decode(_ type: String.Type, forKey key: Key) throws -> String {
			return try get(key)
		}
		
		func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
			return try get(key)
		}
		
		func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
			return try get(key)
		}
		
		func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
			return try get(key)
		}
		
		func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
			return try get(key)
		}
		
		func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
			return try get(key)
		}
		
		func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
			return try get(key)
		}
		
		func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
			return try get(key)
		}
		
		func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
			return try get(key)
		}
		
		func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
			return try get(key)
		}
		
		func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
			return try get(key)
		}
		
		func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
			return try get(key)
		}
		
		func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
			return try get(key)
		}
		
		func decode<T>(_ type: T.Type, forKey key: Key) throws -> T where T : Decodable {
			return try decoder.decode(type, from: get(key), forCodingPath: codingPath + [key])
		}
		
		func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
			let container = try _KeyedDecodingContainer<NestedKey>(codingPath: codingPath + [key], container: get(key), decoder: decoder)
			return KeyedDecodingContainer(container)
		}
		
		func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
			return try _UnkeyedDecodingContainer(codingPath: codingPath + [key], container: get(key), decoder: decoder)
		}
		
		func superDecoder() throws -> Decoder {
			let key = _CodingKey(stringValue: "super")!
			return try _Decoder(codingPath: codingPath + [key], container: get(key), userInfo: decoder.userInfo, dataDecodingStrategy: decoder.dataDecodingStrategy, dateDecodingStrategy: decoder.dateDecodingStrategy)
		}
		
		func superDecoder(forKey key: Key) throws -> Decoder {
			return try _Decoder(codingPath: codingPath + [key], container: get(key), userInfo: decoder.userInfo, dataDecodingStrategy: decoder.dataDecodingStrategy, dateDecodingStrategy: decoder.dateDecodingStrategy)
		}
		
		
	}
	
	private struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {
		var codingPath: [CodingKey]
		var decoder: _Decoder
		
		var count: Int? {
			return container.count
		}
		
		var isAtEnd: Bool {
			return currentIndex >= container.count
		}
		
		var currentIndex: Int = 0
		var container: [Any]
		
		init(codingPath: [CodingKey], container: [Any], decoder: _Decoder) {
			self.codingPath = codingPath
			self.container = container
			self.decoder = decoder
		}

		mutating private func get<T>() throws -> T {
			let value = unwrap(container[currentIndex]) as Any?
			guard let result = value as? T else {throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], debugDescription: ""))}
			currentIndex += 1
			return result
		}
		
		mutating func decodeNil() throws -> Bool {
			return try (get() as Any?) == nil
		}
		
		mutating func decode(_ type: Bool.Type) throws -> Bool {
			return try get()
		}
		
		mutating func decode(_ type: String.Type) throws -> String {
			return try get()
		}
		
		mutating func decode(_ type: Double.Type) throws -> Double {
			return try get()
		}
		
		mutating func decode(_ type: Float.Type) throws -> Float {
			return try get()
		}
		
		mutating func decode(_ type: Int.Type) throws -> Int {
			return try get()
		}
		
		mutating func decode(_ type: Int8.Type) throws -> Int8 {
			return try get()
		}
		
		mutating func decode(_ type: Int16.Type) throws -> Int16 {
			return try get()
		}
		
		mutating func decode(_ type: Int32.Type) throws -> Int32 {
			return try get()
		}
		
		mutating func decode(_ type: Int64.Type) throws -> Int64 {
			return try get()
		}
		
		mutating func decode(_ type: UInt.Type) throws -> UInt {
			return try get()
		}
		
		mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
			return try get()
		}
		
		mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
			return try get()
		}
		
		mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
			return try get()
		}
		
		mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
			return try get()
		}
		
		mutating func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
			return try decoder.decode(type, from: get(), forCodingPath: codingPath + [_CodingKey(intValue: currentIndex)!])
		}
		
		mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey : CodingKey {
			let container = try _KeyedDecodingContainer<NestedKey>(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], container: get(), decoder: decoder)
			return KeyedDecodingContainer(container)
		}
		
		mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
			return try _UnkeyedDecodingContainer(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], container: get(), decoder: decoder)
		}
		
		mutating func superDecoder() throws -> Decoder {
			return try _Decoder(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], container: get(), userInfo: decoder.userInfo, dataDecodingStrategy: decoder.dataDecodingStrategy, dateDecodingStrategy: decoder.dateDecodingStrategy)
		}
		
		
	}
	
	private struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
		var codingPath: [CodingKey]
		var container: Any
		var decoder: _Decoder
		
		private func get<T>() throws -> T {
			let value = unwrap(container) as Any?
			guard let result = value as? T else {throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: ""))}
			return result
		}

		
		func decodeNil() -> Bool {
			return unwrap(container) as Any? == nil
		}
		
		func decode(_ type: Bool.Type) throws -> Bool {
			return try get()
		}
		
		func decode(_ type: String.Type) throws -> String {
			return try get()
		}
		
		func decode(_ type: Double.Type) throws -> Double {
			return try get()
		}
		
		func decode(_ type: Float.Type) throws -> Float {
			return try get()
		}
		
		func decode(_ type: Int.Type) throws -> Int {
			return try get()
		}
		
		func decode(_ type: Int8.Type) throws -> Int8 {
			return try get()
		}
		
		func decode(_ type: Int16.Type) throws -> Int16 {
			return try get()
		}
		
		func decode(_ type: Int32.Type) throws -> Int32 {
			return try get()
		}
		
		func decode(_ type: Int64.Type) throws -> Int64 {
			return try get()
		}
		
		func decode(_ type: UInt.Type) throws -> UInt {
			return try get()
		}
		
		func decode(_ type: UInt8.Type) throws -> UInt8 {
			return try get()
		}
		
		func decode(_ type: UInt16.Type) throws -> UInt16 {
			return try get()
		}
		
		func decode(_ type: UInt32.Type) throws -> UInt32 {
			return try get()
		}
		
		func decode(_ type: UInt64.Type) throws -> UInt64 {
			return try get()
		}
		
		func decode<T>(_ type: T.Type) throws -> T where T : Decodable {
			return try decoder.decode(type, from: get(), forCodingPath: codingPath)
		}
		
	}
}
