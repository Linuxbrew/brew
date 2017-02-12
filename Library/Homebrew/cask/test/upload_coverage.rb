#!/usr/bin/env ruby
require "simplecov"
require "codecov"

formatter = SimpleCov::Formatter::Codecov.new
formatter.format SimpleCov::ResultMerger.merged_result
