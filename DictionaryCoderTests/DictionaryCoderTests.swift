//
//  DictionaryCoderTests.swift
//  DictionaryCoderTests
//
//  Created by Artem Shimanski on 07/01/2019.
//  Copyright © 2019 Artem Shimanski. All rights reserved.
//

import XCTest
@testable import DictionaryCoder

class DictionaryCoderTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testEncodingBase() {
		func test<T: Codable & Equatable>(_ value: T) throws {
			try XCTAssertEqual(DictionaryEncoder().encode(value) as! T, value)
		}
		try! test("text".data(using: .utf8)!)

		try! test(Int(1))
		try! test(Int8(1))
		try! test(Int16(1))
		try! test(Int32(1))
		try! test(Int64(1))
		try! test(UInt(1))
		try! test(UInt8(1))
		try! test(UInt16(1))
		try! test(UInt32(1))
		try! test(UInt64(1))
		try! test(Double(1.5))
		try! test(Float(1.5))
		try! test("1")
		try! test(Int?.some(1))
		try! test([0, 1, 2, 3, 4, 5])
		try! test(["a": 1, "b": 2])
		try! test([0, 1, nil, 3])
		try! test("text".data(using: .utf8)!)
		try! test(["a": "text".data(using: .utf8)!])
		try! test(["text".data(using: .utf8)!])
	}

	func testEncodingStruct() {
		struct S: Codable {
			struct Nested: Codable {
				var i: Int = 1
			}
			var s: String = "string"
			var b: Nested = Nested()
		}
		
		let a = try! DictionaryEncoder().encode(S()) as! [String: Any]
		let b = ["s": "string", "b": ["i": 1]] as NSDictionary
		
		XCTAssertEqual(a as NSDictionary, b)
	}
	
	func testEncodingOptional() {
		struct S: Codable {
			var i: Int = 1
		}
		let v: [S?] = [S(), nil, S()]
		let a = try! DictionaryEncoder().encode(v) as! [[String: Int]?]
		let b: [[String: Int]?] = [["i": 1], nil, ["i": 1]]
		XCTAssertEqual(a, b)
	}
	
	func testEncodingData() {
		let data = "text".data(using: .utf8)!
		
		func test<T: Equatable>(_ strategy: DictionaryEncoder.DataEncodingStrategy, _ value: T) throws {
			let encoder = DictionaryEncoder()
			encoder.dataEncodingStrategy = strategy
			XCTAssertEqual(try encoder.encode(data) as? T, value)
		}
		try! test(.data, data)
		try! test(.deferredToData, [UInt8](data))
		try! test(.base64, data.base64EncodedString())
		try! test(.custom { data, encoder in
			var container = encoder.singleValueContainer()
			try container.encode(String(data: data, encoding: .utf8)!)
		}, "text")
	}
	
	func testEncodingDate() {
		let date = Date(timeIntervalSince1970: 3600*24*100)
		
		func test<T: Equatable>(_ strategy: DictionaryEncoder.DateEncodingStrategy, _ value: T) throws {
			let encoder = DictionaryEncoder()
			encoder.dateEncodingStrategy = strategy
			XCTAssertEqual(try encoder.encode(date) as? T, value)
		}
		try! test(.deferredToDate, date.timeIntervalSinceReferenceDate)
		try! test(.secondsSince1970, date.timeIntervalSince1970)
		try! test(.millisecondsSince1970, date.timeIntervalSince1970 * 1000)
		try! test(.iso8601, ISO8601DateFormatter().string(from: date))
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy.MM.dd hh:mm:ss"
		
		try! test(.formatted(formatter), formatter.string(from: date))
		try! test(.custom { date, encoder in
			var container = encoder.singleValueContainer()
			try container.encode(formatter.string(from: date))
		}, formatter.string(from: date))
	}
	
	func testDecodingBase() {
		func test<T: Decodable & Equatable>(_ value: T) throws {
			try XCTAssertEqual(DictionaryDecoder().decode(T.self, from: value), value)
		}
		try! test(Int(1))
		try! test(Int8(1))
		try! test(Int16(1))
		try! test(Int32(1))
		try! test(Int64(1))
		try! test(UInt(1))
		try! test(UInt8(1))
		try! test(UInt16(1))
		try! test(UInt32(1))
		try! test(UInt64(1))
		try! test(Double(1.5))
		try! test(Float(1.5))
		try! test("1")
		try! test(Int?.some(1))
		try! test([0, 1, 2, 3, 4, 5])
		try! test(["a": 1, "b": 2])
		try! test([0, 1, nil, 3])
		try! test("text".data(using: .utf8)!)
		try! test(["a": "text".data(using: .utf8)!])
		try! test(["text".data(using: .utf8)!])
	}
	
	func testDecodingStruct() {
		struct S: Codable, Equatable {
			struct Nested: Codable, Equatable {
				var i: Int = 1
			}
			var s: String = "string"
			var b: Nested = Nested()
		}
		let v: [String: Any] = ["s": "string", "b": ["i": 1]]
		let a = try! DictionaryDecoder().decode(S.self, from: v)
		let b = S()
		XCTAssertEqual(a, b)
	}
	
	func testDecodingData() {
		let data = "text".data(using: .utf8)!
		
		func test<T: Equatable>(_ strategy: DictionaryDecoder.DataDecodingStrategy, _ value: T) throws {
			let decoder = DictionaryDecoder()
			decoder.dataDecodingStrategy = strategy
			XCTAssertEqual(try decoder.decode(Data.self, from: value), data)
		}
		try! test(.data, data)
		try! test(.deferredToData, [UInt8](data))
		try! test(.base64, data.base64EncodedString())
		try! test(.custom { decoder in
			let container = try decoder.singleValueContainer()
			return try container.decode(String.self).data(using: .utf8)!
		}, "text")
	}
	
	func testDecodingDate() {
		let date = Date(timeIntervalSince1970: 3600*24*100)
		
		func test<T: Equatable>(_ strategy: DictionaryDecoder.DateDecodingStrategy, _ value: T) throws {
			let decoder = DictionaryDecoder()
			decoder.dateDecodingStrategy = strategy
			XCTAssertEqual(try decoder.decode(Date.self, from: value), date, "\(strategy)")
		}
		try! test(.deferredToDate, date.timeIntervalSinceReferenceDate)
		try! test(.secondsSince1970, date.timeIntervalSince1970)
		try! test(.millisecondsSince1970, date.timeIntervalSince1970 * 1000)
		try! test(.iso8601, ISO8601DateFormatter().string(from: date))
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy.MM.dd hh:mm:ss"
		
		try! test(.formatted(formatter), formatter.string(from: date))
		try! test(.custom { decoder in
			let container = try decoder.singleValueContainer()
			return try formatter.date(from: container.decode(String.self))!
		}, formatter.string(from: date))
	}
	
	func testDecodingOptional() {
		struct S: Codable, Equatable {
			var i: Int = 1
		}
		let v: [Any] = [["i": 1], Any?.none as Any, ["i": 1]]
		let a: [S?] = [S(), nil, S()]
		let b = try! DictionaryDecoder().decode([S?].self, from: v)
		XCTAssertEqual(a, b)
	}

}
