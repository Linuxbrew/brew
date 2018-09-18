require 'rbconfig'
# ruby 1.8.7 doesn't define RUBY_ENGINE
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/concurrent-ruby-1.0.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/i18n-1.1.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/minitest-5.11.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/thread_safe-0.3.6/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/tzinfo-1.2.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/activesupport-5.2.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/backports-3.11.4/lib"
$:.unshift "#{path}/"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/plist-3.4.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/ruby-macho-2.0.0/lib"
