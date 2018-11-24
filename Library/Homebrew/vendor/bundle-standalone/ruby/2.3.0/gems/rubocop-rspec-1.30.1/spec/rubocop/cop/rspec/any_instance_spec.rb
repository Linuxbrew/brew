RSpec.describe RuboCop::Cop::RSpec::AnyInstance do
  subject(:cop) { described_class.new }

  it 'finds `allow_any_instance_of` instead of an instance double' do
    expect_offense(<<-RUBY)
      before do
        allow_any_instance_of(Object).to receive(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid stubbing using `allow_any_instance_of`.
      end
    RUBY
  end

  it 'finds `expect_any_instance_of` instead of an instance double' do
    expect_offense(<<-RUBY)
      before do
        expect_any_instance_of(Object).to receive(:foo)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Avoid stubbing using `expect_any_instance_of`.
      end
    RUBY
  end

  it 'finds old `any_instance` syntax instead of an instance double' do
    expect_offense(<<-RUBY)
      before do
        Object.any_instance.should_receive(:foo)
        ^^^^^^^^^^^^^^^^^^^ Avoid stubbing using `any_instance`.
      end
    RUBY
  end
end
