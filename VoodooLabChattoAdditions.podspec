Pod::Spec.new do |s|
  s.name         = "VoodooLabChattoAdditions"
  s.version      = "10.0.0"
  s.summary      = "UI componentes for Chatto"
  s.homepage     = "https://github.com/badoo/Chatto"
  s.license      = { :type => "MIT"}
  s.platform     = :ios, "9.0"
  s.authors      = { 'Diego Sanchez' => 'diego.sanchezr@gmail.com', 'Anton Schukin' => 'a.p.schukin@gmail.com' }
  s.source       = { :git => "https://github.com/VoodooTeam/Chatto.git", :tag => s.version.to_s }
  s.source_files = "ChattoAdditions/Source/**/*.{h,m,swift}"
  s.public_header_files = "ChattoAdditions/Source/**/*.h"
  s.requires_arc = true
  s.swift_version = '4.2'
  s.resources = ["ChattoAdditions/Source/**/*.xib", "ChattoAdditions/Source/**/*.storyboard", "ChattoAdditions/Source/**/*.xcassets"]
  s.dependency 'VoodooLabChatto'
end
