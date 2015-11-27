Pod::Spec.new do |s|
  s.name         = "ChattoAdditions"
  s.version      = "1.0.0"
  s.summary      = "UI componentes for Chatto"
  s.description  = <<-DESC
                   Text and photo bubbles
                   Input bar for text and photo messages
                   DESC
  s.homepage     = "https://github.com/badoo/Chatto"
  s.license      = { :type => "MIT"}
  s.platform     = :ios, "8.0"
  s.authors      = { 'Diego Sanchez' => 'diego.sanchezr@gmail.com' }
  s.source       = { :git => "https://github.com/badoo/Chatto.git", :tag => s.version.to_s }
  s.source_files = "ChattoAdditions/Source/**/*.{h,m,swift}"
  s.public_header_files = "ChattoAdditions/Source/**/*.h"
  s.requires_arc = true
  s.resources = ["ChattoAdditions/Source/**/*.xib", "ChattoAdditions/Source/**/*.storyboard", "ChattoAdditions/Source/**/*.xcassets"]
  s.dependency 'Chatto'
end
