class Module
  def attr_rw(*attrs)
    file, line, = caller.first.split(":")
    line = line.to_i

    attrs.each do |attr|
      module_eval <<-EOS, file, line
        def #{attr}(val=nil)
          @#{attr} ||= nil
          return @#{attr} if val.nil?
          @#{attr} = val
        end
      EOS
    end
  end
end
