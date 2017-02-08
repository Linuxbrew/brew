module FileMatchers
  extend RSpec::Matchers::DSL

  matcher :be_a_valid_symlink do
    match do |path|
      path.symlink? && path.readlink.exist?
    end
  end
end
