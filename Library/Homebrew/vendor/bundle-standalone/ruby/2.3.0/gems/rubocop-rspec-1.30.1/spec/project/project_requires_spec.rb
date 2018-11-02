RSpec.describe 'Project requires' do
  it 'alphabetizes cop requires' do
    source   = SpecHelper::ROOT.join('lib', 'rubocop', 'cop', 'rspec_cops.rb')
    captures = source.read.scan(%r{^(require_relative 'rspec/(.*?/)?(.*?)')$})

    require_statements = captures.map(&:first)
    sorted_require_statements =
      captures.sort_by do |_require_statement, cop_category, name|
        [cop_category || 'rspec', name]
      end.map(&:first)

    aggregate_failures do
      # Sanity check that we actually discovered require statements.
      expect(captures).not_to be_empty
      expect(require_statements).to eql(sorted_require_statements)
    end
  end
end
