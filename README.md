# DictionaryCoder
A Swift library for serializing `Codable` types to and from `[String: Any]` and `[Any]`

## Requirements
- iOS 10.0+
- Swift 4.2

## Usage

### Sample 1
```swift
struct S: Codable {
	struct Nested: Codable {
		var i: Int = 1
		}
	var s: String = "string"
	var b: Nested = Nested()
}

let result = try DictionaryEncoder().encode(S()) as! [String: Any]
```

### Sample 2
```swift
struct S: Codable, Equatable {
	struct Nested: Codable, Equatable {
		var i: Int = 1
	}
	var s: String = "string"
	var b: Nested = Nested()
}
let v: [String: Any] = ["s": "string", "b": ["i": 1]]
let result = try DictionaryDecoder().decode(S.self, from: v)
```
