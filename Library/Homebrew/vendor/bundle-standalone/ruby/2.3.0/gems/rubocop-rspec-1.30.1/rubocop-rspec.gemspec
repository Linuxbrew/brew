$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'rubocop/rspec/version'

Gem::Specification.new do |spec|
  spec.name = 'rubocop-rspec'
  spec.summary = 'Code style checking for RSpec files'
  spec.description = <<-DESCRIPTION
    Code style checking for RSpec files.
    A plugin for the RuboCop code style enforcing & linting tool.
  DESCRIPTION
  spec.homepage = 'https://github.com/rubocop-hq/rubocop-rspec'
  spec.authors = ['John Backus', 'Ian MacLeod', 'Nils Gemeinhardt']
  spec.email = [
    'johncbackus@gmail.com',
    'ian@nevir.net',
    'git@nilsgemeinhardt.de'
  ]
  spec.licenses = ['MIT']

  spec.version = RuboCop::RSpec::Version::STRING
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = '>= 2.2.0'

  spec.require_paths = ['lib']
  spec.files = Dir[
    '{config,lib,spec}/**/*',
    '*.md',
    '*.gemspec',
    'Gemfile',
    'Rakefile'
  ]
  spec.test_files = spec.files.grep(%r{^spec/})
  spec.extra_rdoc_files = ['MIT-LICENSE.md', 'README.md']

  spec.metadata = {
    'changelog_uri' => 'https://github.com/rubocop-hq/rubocop-rspec/blob/master/CHANGELOG.md',
    'documentation_uri' => 'https://rubocop-rspec.readthedocs.io/'
  }

  spec.add_runtime_dependency 'rubocop', '>= 0.60.0'

  spec.add_development_dependency 'rack'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec', '>= 3.4'
  spec.add_development_dependency 'simplecov'
  spec.add_development_dependency 'yard'
end
