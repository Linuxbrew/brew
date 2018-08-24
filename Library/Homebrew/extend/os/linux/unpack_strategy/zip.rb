module UnpackStrategy
  class Zip
    def dependencies
      @dependencies ||= [Formula["unzip"]]
    end
  end
end
