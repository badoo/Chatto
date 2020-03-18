Pod::Spec.new do |s|
  s.name         = "VoodooLabChatto"
  s.version      = "10.0.5"
  s.summary      = "Chat framework in Swift"
  s.homepage     = "https://github.com/VoodooTeam/Chatto"
  s.license      = { :type => "MIT"}
  s.platform     = :ios, "9.0"
  s.authors      = { 'Diego Sanchez' => 'diego.sanchezr@gmail.com', 'Anton Schukin' => 'a.p.schukin@gmail.com' }
  s.source       = { :git => "https://github.com/VoodooTeam/Chatto.git", :tag => s.version.to_s }
  s.source_files = "Chatto/Source/**/*.{h,m,swift}"
  s.public_header_files = "Chatto/Source/**/*.h"
  s.requires_arc = true
  s.swift_version = '4.2'
end
