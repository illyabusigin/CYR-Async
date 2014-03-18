Pod::Spec.new do |s|
  s.name         =  'CYR+Async'
  s.version      =  '0.2.0'
  s.license      =  { :type => 'MIT', :file => 'LICENSE' }
  s.summary      =  'Asynchronous GCD utilities for Objective-C inspired by https://github.com/caolan/async.'
  s.author       =  { 'Illya Busigin' => 'http://illyabusigin.com/' }
  s.source       =  { :git => 'https://github.com/illyabusigin/CYR-Async.git', :tag => '0.2.0' }
  s.homepage     =  'https://github.com/illyabusigin/CYR-Async'
  s.platform     =  :ios
  s.source_files =  'CYR+Async'
  s.requires_arc =  true
  s.ios.deployment_target = '6.0'
end
