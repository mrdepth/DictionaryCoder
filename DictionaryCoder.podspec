Pod::Spec.new do |s|
  s.name         = "DictionaryCoder"
  s.version      = "1.0.0"
  s.summary      = "A Swift library for serializing Codable types to and from [String: Any] and [Any]"
  s.homepage     = "https://github.com/mrdepth/DictionaryCoder"
  s.license      = "MIT"
  s.author       = { "Shimanski Artem" => "shimanski.artem@gmail.com" }
  s.source       = { :git => "https://github.com/mrdepth/DictionaryCoder.git", :branch => "master" }
  s.source_files = "Source/*.swift"
  s.platform     = :ios
  s.ios.deployment_target = "10.0"
  s.swift_version = "4.2"
end
