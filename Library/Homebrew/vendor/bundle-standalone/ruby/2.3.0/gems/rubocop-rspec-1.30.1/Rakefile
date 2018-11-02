require 'open3'

require 'bundler'
require 'bundler/gem_tasks'

begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  warn e.message
  warn 'Run `bundle install` to install missing gems'
  exit e.status_code
end

require 'rspec/core/rake_task'

Dir['tasks/**/*.rake'].each { |t| load t }

RSpec::Core::RakeTask.new(:spec) do |spec|
  spec.pattern = FileList['spec/**/*_spec.rb']
end

desc 'Run RSpec with code coverage'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task['spec'].execute
end

desc 'Run RuboCop over this gem'
task :internal_investigation do
  sh('bundle exec rubocop --require rubocop-rspec')
end

desc 'Build config/default.yml'
task :build_config do
  sh('bin/build_config')
end

desc 'Confirm config/default.yml is up to date'
task confirm_config: :build_config do
  _, stdout, _, process =
    Open3.popen3('git diff --exit-code config/default.yml')

  unless process.value.success?
    raise "default.yml is out of sync:\n\n#{stdout.read}\nRun bin/build_config"
  end
end

desc 'Confirm documentation is up to date'
task confirm_documentation: :generate_cops_documentation do
  _, _, _, process =
    Open3.popen3('git diff --exit-code manual/')

  unless process.value.success?
    raise 'Please run `rake generate_cops_documentation` ' \
          'and add manual/ to the commit.'
  end
end

task default: %i[build_config coverage
                 internal_investigation
                 confirm_config
                 documentation_syntax_check
                 confirm_documentation]

desc 'Generate a new cop template'
task :new_cop, [:cop] do |_task, args|
  require 'rubocop'

  cop_name = args.fetch(:cop) do
    warn 'usage: bundle exec rake new_cop[Department/Name]'
    exit!
  end

  github_user = `git config github.user`.chop
  github_user = 'your_id' if github_user.empty?

  generator = RuboCop::Cop::Generator.new(cop_name, github_user)

  generator.write_source
  generator.write_spec
  generator.inject_require(root_file_path: 'lib/rubocop/cop/rspec_cops.rb')
  generator.inject_config(config_file_path: 'config/default.yml')

  puts generator.todo
end
