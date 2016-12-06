module Hbc
  class CaskLoader
    def self.load_from_file(path)
      raise CaskError, "File '#{path}' does not exist"      unless path.exist?
      raise CaskError, "File '#{path}' is not readable"     unless path.readable?
      raise CaskError, "File '#{path}' is not a plain file" unless path.file?

      token = path.basename(".rb").to_s
      content = IO.read(path).force_encoding("UTF-8")

      new(token, content, path).load
    end

    def self.load_from_string(token, content)
      new(token, content).load
    end

    def load
      instance_eval(@content, __FILE__, __LINE__)
    rescue CaskError, StandardError, ScriptError => e
      e.message.concat(" while loading '#{@token}'")
      e.message.concat(" from '#{@path}'") unless @path.nil?
      raise e, e.message
    end

    private

    def initialize(token, content, path = nil)
      @token = token
      @content = content
      @path = path unless path.nil?
    end

    def cask(header_token, &block)
      @klass = Cask
      build_cask(header_token, &block)
    end

    def test_cask(header_token, &block)
      @klass = TestCask
      build_cask(header_token, &block)
    end

    def build_cask(header_token, &block)
      raise CaskTokenDoesNotMatchError.new(@token, header_token) unless @token == header_token

      if @path.nil?
        @klass.new(@token, &block)
      else
        @klass.new(@token, sourcefile_path: @path, &block)
      end
    end
  end
end
