RSpec.describe RuboCop::Cop::RSpec::AlignRightLetBrace do
  subject(:cop) { described_class.new }

  it 'registers offense for unaligned braces' do
    expect_offense(<<-RUBY)
      let(:foo)      { a }
                         ^ Align right let brace
      let(:hi)       { ab }
                          ^ Align right let brace
      let(:blahblah) { abcd }

      let(:thing) { ignore_this }
      let(:other) {
        ignore_this_too
      }

      describe 'blah' do
        let(:blahblah) { a }
                           ^ Align right let brace
        let(:blah)     { bc }
                            ^ Align right let brace
        let(:a)        { abc }
      end
    RUBY
  end

  it 'works with empty file' do
    expect_no_offenses('')
  end

  offensive_source = <<-RUBY
    let(:foo)      { a }
    let(:hi)       { ab }
    let(:blahblah) { abcd }

    let(:thing) { ignore_this }
    let(:other) {
      ignore_this_too
    }

    describe 'blah' do
      let(:blahblah) { a }
      let(:blah)     { bc }
      let(:a)        { abc }
    end
  RUBY

  corrected_source = <<-RUBY
    let(:foo)      { a    }
    let(:hi)       { ab   }
    let(:blahblah) { abcd }

    let(:thing) { ignore_this }
    let(:other) {
      ignore_this_too
    }

    describe 'blah' do
      let(:blahblah) { a   }
      let(:blah)     { bc  }
      let(:a)        { abc }
    end
  RUBY

  include_examples 'autocorrect', offensive_source, corrected_source
end
