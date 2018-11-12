require 'rbconfig'
# ruby 1.8.7 doesn't define RUBY_ENGINE
ruby_engine = defined?(RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
ruby_version = RbConfig::CONFIG["ruby_version"]
path = File.expand_path('..', __FILE__)
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/concurrent-ruby-1.0.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/i18n-1.1.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/minitest-5.11.3/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/thread_safe-0.3.6/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/tzinfo-1.2.5/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/activesupport-5.2.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/ast-2.4.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/backports-3.11.4/lib"
$:.unshift "#{path}/"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/extensions/universal-darwin-18/2.3.0/jaro_winkler-1.5.1"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/jaro_winkler-1.5.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/parallel-1.12.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/parser-2.5.3.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/plist-3.4.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/powerpack-0.1.2/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rainbow-3.0.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/ruby-progressbar-1.10.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/unicode-display_width-1.4.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rubocop-0.60.0/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/rubocop-rspec-1.30.1/lib"
$:.unshift "#{path}/../#{ruby_engine}/#{ruby_version}/gems/ruby-macho-2.1.0/lib"
