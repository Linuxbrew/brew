#!/usr/bin/env ruby
#
# = plist
#
# This is the main file for plist. Everything interesting happens in
# Plist and Plist::Emit.
#
# Copyright 2006-2010 Ben Bleything and Patrick May
# Distributed under the MIT License
#

require 'base64'
require 'cgi'
require 'stringio'

require_relative 'plist/generator'
require_relative 'plist/parser'

module Plist
  VERSION = '3.1.0'
end
