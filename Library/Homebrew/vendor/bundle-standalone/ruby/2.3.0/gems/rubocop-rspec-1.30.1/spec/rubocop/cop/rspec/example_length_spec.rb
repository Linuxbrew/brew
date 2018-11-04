RSpec.describe RuboCop::Cop::RSpec::ExampleLength, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'Max' => 3 } }

  it 'ignores non-spec blocks' do
    expect_no_offenses(<<-RUBY)
      foo do
        line 1
        line 2
        line 3
        line 4
      end
    RUBY
  end

  it 'allows an empty example' do
    expect_no_offenses(<<-RUBY)
      it do
      end
    RUBY
  end

  it 'allows a short example' do
    expect_no_offenses(<<-RUBY)
      it do
        line 1
        line 2
        line 3
      end
    RUBY
  end

  it 'ignores comments' do
    expect_no_offenses(<<-RUBY)
      it do
        line 1
        line 2
        # comment
        line 3
      end
    RUBY
  end

  context 'when inspecting large examples' do
    it 'flags the example' do
      expect_offense(<<-RUBY)
        it do
        ^^^^^ Example has too many lines [4/3].
          line 1
          line 2
          line 3
          line 4
        end
      RUBY
    end
  end

  context 'with CountComments enabled' do
    let(:cop_config) do
      { 'Max' => 3, 'CountComments' => true }
    end

    it 'flags the example' do
      expect_offense(<<-RUBY)
        it do
        ^^^^^ Example has too many lines [4/3].
          line 1
          line 2
          # comment
          line 3
        end
      RUBY
    end
  end
end
