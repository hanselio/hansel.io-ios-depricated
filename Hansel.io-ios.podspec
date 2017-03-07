Pod::Spec.new do |s|

  s.name         = "Hansel.io-ios"
  s.version      = "2.0.3"
  s.summary      = "Live bug fixing of ios app"
  s.description  = "pebbletrace-ios.framework powers developers to fix bugs at runtime"

  s.homepage     = "https://hansel.io/"
  s.license      = {"type" => "Commercial", "text" => "See http://www.hansel.io/"}
  s.authors      = {"hansel.io" => "hi@hansel.io"}
  s.documentation_url = "http://hansel.io/"
  s.requires_arc = true
  s.ios.vendored_frameworks = 'Hanselio/framework/Hanselio.framework'
  s.xcconfig = { 'FRAMEWORK_SEARCH_PATHS' => '$(inherited)' }
  s.weak_framework = 'JavaScriptCore'
  s.source       = { :git => "https://github.com/hanselio/hansel.io-ios.git", :tag => s.version}
  s.preserve_paths = "Hanselio/**/*"
  s.resource_bundles = {'PebbletraceBundle' => ["Hanselio/**/*.der", "Hanselio/**/PebbletraceInfo.plist"]}
  s.libraries = 'c++', 'z'
end
