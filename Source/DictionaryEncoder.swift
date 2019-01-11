//
//  DictionaryEncoder.swift
//  DictionaryCoder
//
//  Created by Artem Shimanski on 07/01/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import Foundation

open class DictionaryEncoder {
	public enum DataEncodingStrategy {
		case data
		case deferredToData
		case base64
		case custom((Data, Encoder) throws -> Void)
	}
	
	public enum DateEncodingStrategy {
		case deferredToDate
		case secondsSince1970
		case millisecondsSince1970
		case iso8601
		case formatted(DateFormatter)
		case custom((Date, Encoder) throws -> Void)
	}
	
	var dataEncodingStrategy: DataEncodingStrategy = .data
	var dateEncodingStrategy: DateEncodingStrategy = .deferredToDate
	
	open func encode<T: Encodable>(_ value: T) throws -> Any {
		let encoder = _Encoder(codingPath: [], userInfo: [:], dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
		return try encoder.encode(value, forCodingPath: []).asAny
	}
}

extension DictionaryEncoder {
	
	private class _Encoder: Encoder, EncodingContainer {
		var codingPath: [CodingKey]
		var userInfo: [CodingUserInfoKey : Any] = [:]
		var container: EncodingContainer?
		var dataEncodingStrategy: DataEncodingStrategy
		var dateEncodingStrategy: DateEncodingStrategy

		var asAny: Any {
			return container?.asAny ?? Any?.none as Any
		}
		
		init(codingPath: [CodingKey], userInfo: [CodingUserInfoKey : Any], dataEncodingStrategy: DataEncodingStrategy, dateEncodingStrategy: DateEncodingStrategy) {
			self.userInfo = userInfo
			self.codingPath = codingPath
			self.dataEncodingStrategy = dataEncodingStrategy
			self.dateEncodingStrategy = dateEncodingStrategy
		}
		
		func container<Key>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> where Key : CodingKey {
			assert(self.container == nil)
			let container = _KeyedEncodingContainer<Key>(codingPath: codingPath, encoder: self)
			self.container = container
			return KeyedEncodingContainer(container)
		}
		
		func unkeyedContainer() -> UnkeyedEncodingContainer {
			assert(self.container == nil)
			let container = _UnkeyedEncodingContainer(codingPath: codingPath, encoder: self)
			self.container = container
			return container
		}
		
		func singleValueContainer() -> SingleValueEncodingContainer {
			assert(self.container == nil)
			let container = _SingleValueEncodingContainer(codingPath: codingPath, encoder: self)
			self.container = container
			return container
		}
		
		func encode<T>(_ value: T, forCodingPath codingPath: [CodingKey]) throws -> EncodingContainer where T: Encodable {
			if let data = value as? Data {
				switch dataEncodingStrategy {
				case .data:
					return SingleValue(data)
				case .deferredToData:
					let encoder = _Encoder(codingPath: codingPath, userInfo: userInfo, dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
					try data.encode(to: encoder)
					return encoder
				case .base64:
					return SingleValue(data.base64EncodedString())
				case let .custom(block):
					let encoder = _Encoder(codingPath: codingPath, userInfo: userInfo, dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
					try block(data, encoder)
					return encoder
				}
			}
			else if let date = value as? Date {
				switch dateEncodingStrategy {
				case .deferredToDate:
					let encoder = _Encoder(codingPath: codingPath, userInfo: userInfo, dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
					try date.encode(to: encoder)
					return encoder
				case .millisecondsSince1970:
					return SingleValue(date.timeIntervalSince1970 * 1000)
				case .secondsSince1970:
					return SingleValue(date.timeIntervalSince1970)
				case .iso8601:
					return SingleValue(iso8601Formatter.string(from: date))
				case let .formatted(formatter):
					return SingleValue(formatter.string(from: date))
				case let .custom(block):
					let encoder = _Encoder(codingPath: codingPath, userInfo: userInfo, dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
					try block(date, encoder)
					return encoder
				}
			}
			else {
				let encoder = _Encoder(codingPath: codingPath, userInfo: userInfo, dataEncodingStrategy: dataEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy)
				try value.encode(to: encoder)
				return encoder
			}
		}
	}
	
	private class _KeyedEncodingContainer<Key: CodingKey>: KeyedEncodingContainerProtocol, EncodingContainer {
		var codingPath: [CodingKey]
		var container: [String: EncodingContainer] = [:]
		var encoder: _Encoder
		
		var asAny: Any {
			return container.mapValues {$0.asAny}
		}
		
		init(codingPath: [CodingKey], encoder: _Encoder) {
			self.codingPath = codingPath
			self.encoder = encoder
		}

		func encodeNil(forKey key: Key) throws {
			container[key.stringValue] = SingleValue(nil)
		}
		
		func encode(_ value: Bool, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: String, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Double, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Float, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Int, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Int8, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Int16, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Int32, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: Int64, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: UInt, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: UInt8, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: UInt16, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: UInt32, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode(_ value: UInt64, forKey key: Key) throws {
			container[key.stringValue] = SingleValue(value)
		}
		
		func encode<T>(_ value: T, forKey key: Key) throws where T : Encodable {
			container[key.stringValue] = try encoder.encode(value, forCodingPath: codingPath + [key])
		}
		
		func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
			let container = _KeyedEncodingContainer<NestedKey>(codingPath: codingPath + [key], encoder: encoder)
			self.container[key.stringValue] = container
			return KeyedEncodingContainer(container)
		}
		
		func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
			let container = _UnkeyedEncodingContainer(codingPath: codingPath + [key], encoder: encoder)
			self.container[key.stringValue] = container
			return container
		}
		
		func superEncoder() -> Encoder {
			let key = _CodingKey(stringValue: "super")!
			let encoder = _Encoder(codingPath: codingPath + [key], userInfo: self.encoder.userInfo, dataEncodingStrategy: self.encoder.dataEncodingStrategy, dateEncodingStrategy: self.encoder.dateEncodingStrategy)
			container[key.stringValue] = encoder
			return encoder
		}
		
		func superEncoder(forKey key: Key) -> Encoder {
			let encoder = _Encoder(codingPath: codingPath + [key], userInfo: self.encoder.userInfo, dataEncodingStrategy: self.encoder.dataEncodingStrategy, dateEncodingStrategy: self.encoder.dateEncodingStrategy)
			container[key.stringValue] = encoder
			return encoder
		}
		
		
	}
	
	private class _UnkeyedEncodingContainer: UnkeyedEncodingContainer, EncodingContainer {
		
		var codingPath: [CodingKey]
		
		var count: Int {
			return container.count
		}
		var currentIndex: Int = 0
		
		var container: [EncodingContainer] = []
		var encoder: _Encoder
		
		var asAny: Any {
			return container.map {$0.asAny}
		}
		
		init(codingPath: [CodingKey], encoder: _Encoder) {
			self.codingPath = codingPath
			self.encoder = encoder
		}

		private func append(_ container: EncodingContainer) {
			self.container.append(container)
			currentIndex += 1
		}
		
		private func append<T>(_ value: T) {
			append(SingleValue(value))
		}

		func encodeNil() throws {
			append(Any?.none as Any)
		}
		
		func encode(_ value: Bool) throws {
			append(value)
		}
		
		func encode(_ value: String) throws {
			append(value)
		}
		
		func encode(_ value: Double) throws {
			append(value)
		}
		
		func encode(_ value: Float) throws {
			append(value)
		}
		
		func encode(_ value: Int) throws {
			append(value)
		}
		
		func encode(_ value: Int8) throws {
			append(value)
		}
		
		func encode(_ value: Int16) throws {
			append(value)
		}
		
		func encode(_ value: Int32) throws {
			append(value)
		}
		
		func encode(_ value: Int64) throws {
			append(value)
		}
		
		func encode(_ value: UInt) throws {
			append(value)
		}
		
		func encode(_ value: UInt8) throws {
			append(value)
		}
		
		func encode(_ value: UInt16) throws {
			append(value)
		}
		
		func encode(_ value: UInt32) throws {
			append(value)
		}
		
		func encode(_ value: UInt64) throws {
			append(value)
		}
		
		func encode<T>(_ value: T) throws where T : Encodable {
			try append(encoder.encode(value, forCodingPath: codingPath + [_CodingKey(intValue: currentIndex)!]))
		}
		
		func nestedContainer<NestedKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> where NestedKey : CodingKey {
			let container = _KeyedEncodingContainer<NestedKey>(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], encoder: encoder)
			append(container)
			return KeyedEncodingContainer(container)
		}
		
		func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
			let container = _UnkeyedEncodingContainer(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], encoder: encoder)
			append(container)
			return container
		}
		
		func superEncoder() -> Encoder {
			let encoder = _Encoder(codingPath: codingPath + [_CodingKey(intValue: currentIndex)!], userInfo: self.encoder.userInfo, dataEncodingStrategy: self.encoder.dataEncodingStrategy, dateEncodingStrategy: self.encoder.dateEncodingStrategy)
			append(encoder)
			return encoder
		}
		
	}
	
	private class _SingleValueEncodingContainer: SingleValueEncodingContainer, EncodingContainer {
		var codingPath: [CodingKey]
		var container: Any?
		var encoder: _Encoder
		var asAny: Any {
			return container ?? Any?.none as Any
		}
		
		init(codingPath: [CodingKey], encoder: _Encoder) {
			self.codingPath = codingPath
			self.encoder = encoder
		}

		func encodeNil() throws {
			assert(container == nil)
			container = Any?.none as Any
		}
		
		func encode(_ value: Bool) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: String) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Double) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Float) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Int) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Int8) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Int16) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Int32) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: Int64) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: UInt) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: UInt8) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: UInt16) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: UInt32) throws {
			assert(container == nil)
			container = value
		}
		
		func encode(_ value: UInt64) throws {
			assert(container == nil)
			container = value
		}
		
		func encode<T>(_ value: T) throws where T : Encodable {
			assert(container == nil)
			container = try encoder.encode(value, forCodingPath: codingPath).asAny
		}
		
		
	}
	
	private struct SingleValue: EncodingContainer {
		var value: Any?
		var asAny: Any {
			return value ?? Any?.none as Any
		}
		init(_ value: Any?) {
			self.value = value
		}
	}
}

private protocol EncodingContainer {
	var asAny: Any {get}
}
