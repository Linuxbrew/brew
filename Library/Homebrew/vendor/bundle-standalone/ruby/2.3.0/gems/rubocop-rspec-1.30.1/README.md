# RuboCop RSpec

[![Join the chat at https://gitter.im/rubocop-rspec/Lobby](https://badges.gitter.im/rubocop-rspec/Lobby.svg)](https://gitter.im/rubocop-rspec/Lobby)
[![Gem Version](https://badge.fury.io/rb/rubocop-rspec.svg)](https://rubygems.org/gems/rubocop-rspec)
[![CircleCI](https://circleci.com/gh/rubocop-hq/rubocop-rspec.svg?style=svg)](https://circleci.com/gh/rubocop-hq/rubocop-rspec)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8ffaabf633c968c22bdd/test_coverage)](https://codeclimate.com/github/rubocop-hq/rubocop-rspec/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/8ffaabf633c968c22bdd/maintainability)](https://codeclimate.com/github/rubocop-hq/rubocop-rspec/maintainability)

RSpec-specific analysis for your projects, as an extension to
[RuboCop](https://github.com/rubocop-hq/rubocop).

## Installation

Just install the `rubocop-rspec` gem

```bash
gem install rubocop-rspec
```

or if you use bundler put this in your `Gemfile`

```
gem 'rubocop-rspec'
```

## Usage

You need to tell RuboCop to load the RSpec extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```
require: rubocop-rspec
```

Now you can run `rubocop` and it will automatically load the RuboCop RSpec
cops together with the standard cops.

### Command line

```bash
rubocop --require rubocop-rspec
```

### Rake task

```ruby
RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rspec'
end
```

### Code Climate

rubocop-rspec is available on Code Climate as part of the rubocop engine. [Learn More](https://codeclimate.com/changelog/55a433bbe30ba00852000fac).

## Documentation

You can read more about RuboCop-RSpec in its [official manual](http://rubocop-rspec.readthedocs.io).

## Inspecting files that don't end with `_spec.rb`

By default, `rubocop-rspec` only inspects code within paths ending in `_spec.rb` or including `spec/`. You can override this setting in your config file by specifying one or more patterns:

```yaml
# Inspect all files
AllCops:
  RSpec:
    Patterns:
    - '.+'
```

```yaml
# Inspect only files ending with `_test.rb`
AllCops:
  RSpec:
    Patterns:
    - '_test.rb$'
```

## The Cops

All cops are located under
[`lib/rubocop/cop/rspec`](lib/rubocop/cop/rspec), and contain
examples/documentation.

In your `.rubocop.yml`, you may treat the RSpec cops just like any other
cop. For example:

```yaml
RSpec/FilePath:
  Exclude:
    - spec/my_poorly_named_spec_file.rb
```

## Non-goals of RuboCop RSpec

### Enforcing `should` vs. `expect` syntax

Enforcing

```ruby
expect(calculator.compute(line_item)).to eq(5)
```

over

```ruby
calculator.compute(line_item).should == 5
```

is a feature of RSpec itself – you can read about it in the [RSpec Documentation](https://relishapp.com/rspec/rspec-expectations/docs/syntax-configuration#disable-should-syntax)

### Enforcing an explicit RSpec receiver for top-level methods (disabling monkey patching)

Enforcing

```ruby
Rspec.describe MyClass do
  ...
end
```

over

```ruby
describe MyClass do
  ...
end
```

can be achieved using RSpec's `disable_monkey_patching!` method, which you can read more about in the [RSpec Documentation](https://relishapp.com/rspec/rspec-core/v/3-7/docs/configuration/zero-monkey-patching-mode#monkey-patched-methods-are-undefined-with-%60disable-monkey-patching!%60). This will also prevent `should` from being defined on every object in your system.

Before disabling `should` you will need all your specs to use the `expect` syntax. You can use [Transpec](http://yujinakayama.me/transpec/), which will do the conversion for you.

## Contributing

Checkout the [contribution guidelines](.github/CONTRIBUTING.md).

## License

`rubocop-rspec` is MIT licensed. [See the accompanying file](MIT-LICENSE.md) for
the full text.
