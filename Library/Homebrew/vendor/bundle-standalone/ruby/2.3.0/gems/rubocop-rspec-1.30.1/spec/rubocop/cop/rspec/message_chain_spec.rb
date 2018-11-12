RSpec.describe RuboCop::Cop::RSpec::MessageChain do
  subject(:cop) { described_class.new }

  it 'finds `receive_message_chain`' do
    expect_offense(<<-RUBY)
      before do
        allow(foo).to receive_message_chain(:one, :two) { :three }
                      ^^^^^^^^^^^^^^^^^^^^^ Avoid stubbing using `receive_message_chain`.
      end
    RUBY
  end

  it 'finds old `stub_chain` syntax' do
    expect_offense(<<-RUBY)
      before do
        foo.stub_chain(:one, :two).and_return(:three)
            ^^^^^^^^^^ Avoid stubbing using `stub_chain`.
      end
    RUBY
  end
end
