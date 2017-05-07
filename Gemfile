source "https://rubygems.org"

# brew *
gem "ruby-macho"

# brew cask
gem "plist"

# brew cask style
group :cask_style do
  gem "rubocop-cask", "~> 0.12.0"
end

# brew man
group :man do
  gem "ronn"
end

# brew style
group :style do
  gem "rubocop", "~> 0.47.1"
end

# brew tests
group :tests do
  gem "parallel_tests"
  gem "rspec"
  gem "rspec-its", require: false
  gem "rspec-wait", require: false
end

# brew tests --coverage
group :coverage do
  gem "codecov", require: false
  gem "simplecov", require: false
end
