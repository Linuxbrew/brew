RSpec.describe RuboCop::Cop::RSpec::ScatteredLet do
  subject(:cop) { described_class.new }

  it 'flags `let` after the first different node ' do
    expect_offense(<<-RUBY)
      RSpec.describe User do
        let(:a) { a }
        subject { User }
        let(:b) { b }
        ^^^^^^^^^^^^^ Group all let/let! blocks in the example group together.
      end
    RUBY
  end

  it 'doesnt flag `let!` in the middle of multiple `let`s' do
    expect_no_offenses(<<-RUBY)
      RSpec.describe User do
        subject { User }

        let(:a) { a }
        let!(:b) { b }
        let(:c) { c }
      end
    RUBY
  end
end
