module UnpackStrategy
  class LuaRock
    def dependencies
      @dependencies ||= [Formula["unzip"]]
    end
  end
end
