# -*- coding: UTF-8 -*-

require "testing_env"
require "language/go"

class LanguageGoTests < Homebrew::TestCase
  def test_stage_deps_empty
    if ARGV.homebrew_developer?
      Language::Go.expects(:odie).once
    else
      Language::Go.expects(:opoo).once
    end
    mktmpdir do |path|
      shutup { Language::Go.stage_deps [], path }
    end
  end
end
