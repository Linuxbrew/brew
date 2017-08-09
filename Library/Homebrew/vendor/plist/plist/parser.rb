# encoding: utf-8

# = plist
#
# Copyright 2006-2010 Ben Bleything and Patrick May
# Distributed under the MIT License
#

# Plist parses Mac OS X xml property list files into ruby data structures.
#
# === Load a plist file
# This is the main point of the library:
#
#   r = Plist::parse_xml( filename_or_xml )
module Plist
# Note that I don't use these two elements much:
#
#  + Date elements are returned as DateTime objects.
#  + Data elements are implemented as Tempfiles
#
# Plist::parse_xml will blow up if it encounters a Date element.
# If you encounter such an error, or if you have a Date element which
# can't be parsed into a Time object, please send your plist file to
# plist@hexane.org so that I can implement the proper support.
  def Plist::parse_xml( filename_or_xml )
    listener = Listener.new
    #parser = REXML::Parsers::StreamParser.new(File.new(filename), listener)
    parser = StreamParser.new(filename_or_xml, listener)
    parser.parse
    listener.result
  end

  class Listener
    #include REXML::StreamListener

    attr_accessor :result, :open

    def initialize
      @result = nil
      @open   = Array.new
    end


    def tag_start(name, attributes)
      @open.push PTag::mappings[name].new
    end

    def text( contents )
      @open.last.text = contents if @open.last
    end

    def tag_end(name)
      last = @open.pop
      if @open.empty?
        @result = last.to_ruby
      else
        @open.last.children.push last
      end
    end
  end

  class StreamParser
    def initialize( plist_data_or_file, listener )
      if plist_data_or_file.respond_to? :read
        @xml = plist_data_or_file.read
      elsif File.exist? plist_data_or_file
        @xml = File.read( plist_data_or_file )
      else
        @xml = plist_data_or_file
      end

      @listener = listener
    end

    TEXT       = /([^<]+)/
    XMLDECL_PATTERN = /<\?xml\s+(.*?)\?>*/m
    DOCTYPE_PATTERN = /\s*<!DOCTYPE\s+(.*?)(\[|>)/m
    COMMENT_START = /\A<!--/
    COMMENT_END = /.*?-->/m


    def parse
      plist_tags = PTag::mappings.keys.join('|')
      start_tag  = /<(#{plist_tags})([^>]*)>/i
      end_tag    = /<\/(#{plist_tags})[^>]*>/i

      require 'strscan'

      @scanner = StringScanner.new( @xml )
      until @scanner.eos?
        if @scanner.scan(COMMENT_START)
          @scanner.scan(COMMENT_END)
        elsif @scanner.scan(XMLDECL_PATTERN)
          encoding = parse_encoding_from_xml_declaration(@scanner[1])
          next if encoding.nil?

          # use the specified encoding for the rest of the file
          next unless String.method_defined?(:force_encoding)
          @scanner.string = @scanner.rest.force_encoding(encoding)
        elsif @scanner.scan(DOCTYPE_PATTERN)
          next
        elsif @scanner.scan(start_tag)
          @listener.tag_start(@scanner[1], nil)
          if (@scanner[2] =~ /\/$/)
            @listener.tag_end(@scanner[1])
          end
        elsif @scanner.scan(TEXT)
          @listener.text(@scanner[1])
        elsif @scanner.scan(end_tag)
          @listener.tag_end(@scanner[1])
        else
          raise "Unimplemented element"
        end
      end
    end

    private

    def parse_encoding_from_xml_declaration(xml_declaration)
      return unless defined?(Encoding)

      xml_encoding = xml_declaration.match(/(?:\A|\s)encoding=(?:"(.*?)"|'(.*?)')(?:\s|\Z)/)

      return if xml_encoding.nil?

      begin
        Encoding.find(xml_encoding[1])
      rescue ArgumentError
        nil
      end
    end
  end

  class PTag
    @@mappings = { }
    def PTag::mappings
      @@mappings
    end

    def PTag::inherited( sub_class )
      key = sub_class.to_s.downcase
      key.gsub!(/^plist::/, '' )
      key.gsub!(/^p/, '')  unless key == "plist"

      @@mappings[key] = sub_class
    end

    attr_accessor :text, :children
    def initialize
      @children = Array.new
    end

    def to_ruby
      raise "Unimplemented: " + self.class.to_s + "#to_ruby on #{self.inspect}"
    end
  end

  class PList < PTag
    def to_ruby
      children.first.to_ruby if children.first
    end
  end

  class PDict < PTag
    def to_ruby
      dict = Hash.new
      key = nil

      children.each do |c|
        if key.nil?
          key = c.to_ruby
        else
          dict[key] = c.to_ruby
          key = nil
        end
      end

      dict
    end
  end

  class PKey < PTag
    def to_ruby
      CGI::unescapeHTML(text || '')
    end
  end

  class PString < PTag
    def to_ruby
      CGI::unescapeHTML(text || '')
    end
  end

  class PArray < PTag
    def to_ruby
      children.collect do |c|
        c.to_ruby
      end
    end
  end

  class PInteger < PTag
    def to_ruby
      text.to_i
    end
  end

  class PTrue < PTag
    def to_ruby
      true
    end
  end

  class PFalse < PTag
    def to_ruby
      false
    end
  end

  class PReal < PTag
    def to_ruby
      text.to_f
    end
  end

  require 'date'
  class PDate < PTag
    def to_ruby
      DateTime.parse(text)
    end
  end

  require 'base64'
  class PData < PTag
    def to_ruby
      data = Base64.decode64(text.gsub(/\s+/, '')) unless text.nil?
      begin
        return Marshal.load(data)
      rescue Exception
        io = StringIO.new
        io.write data
        io.rewind
        return io
      end
    end
  end
end
