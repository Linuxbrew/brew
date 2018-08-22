module UnpackStrategy
  class Jar
    def dependencies
      @dependencies ||= [Formula["unzip"]]
    end
  end
end
