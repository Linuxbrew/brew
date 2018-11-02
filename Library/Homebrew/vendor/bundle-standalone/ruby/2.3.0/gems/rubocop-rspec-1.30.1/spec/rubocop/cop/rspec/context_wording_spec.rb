RSpec.describe RuboCop::Cop::RSpec::ContextWording, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) { { 'Prefixes' => %w[when with] } }

  it 'skips describe blocks' do
    expect_no_offenses(<<-RUBY)
      describe 'the display name not present' do
      end
    RUBY
  end

  it 'finds context without `when` at the beginning' do
    expect_offense(<<-RUBY)
      context 'the display name not present' do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Start context description with 'when', or 'with'.
      end
    RUBY
  end

  it 'finds shared_context without `when` at the beginning' do
    expect_offense(<<-RUBY)
      shared_context 'the display name not present' do
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Start context description with 'when', or 'with'.
      end
    RUBY
  end

  it "skips descriptions beginning with 'when'" do
    expect_no_offenses(<<-RUBY)
      context 'when the display name is not present' do
      end
    RUBY
  end

  it 'finds context without separate `when` at the beginning' do
    expect_offense(<<-RUBY)
      context 'whenever you do' do
              ^^^^^^^^^^^^^^^^^ Start context description with 'when', or 'with'.
      end
    RUBY
  end

  context 'when configured' do
    let(:cop_config) { { 'Prefixes' => %w[if] } }

    it 'finds context without whitelisted prefixes at the beginning' do
      expect_offense(<<-RUBY)
        context 'when display name is present' do
                ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Start context description with 'if'.
        end
      RUBY
    end

    it 'skips descriptions with whitelisted prefixes at the beginning' do
      expect_no_offenses(<<-RUBY)
        context 'if display name is present' do
        end
      RUBY
    end
  end
end
