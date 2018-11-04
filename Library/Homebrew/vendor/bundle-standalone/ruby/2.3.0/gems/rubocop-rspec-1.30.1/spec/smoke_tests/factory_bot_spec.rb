# frozen_string_literal: true

# Since FactoryBot is not a dependency, none of this should be executed. We just
# need the AST to exist.
if false
  FactoryBot.define do
    factory :foo do
      bar {}
    end
  end
end
