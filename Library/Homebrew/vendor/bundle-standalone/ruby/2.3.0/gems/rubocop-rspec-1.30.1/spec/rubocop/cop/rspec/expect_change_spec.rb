RSpec.describe RuboCop::Cop::RSpec::ExpectChange, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  context 'with EnforcedStyle `method_call`' do
    let(:enforced_style) { 'method_call' }

    it 'finds blocks that contain simple message sending' do
      expect_offense(<<-RUBY)
        it do
          expect(run).to change { User.count }
                         ^^^^^^^^^^^^^^^^^^^^^ Prefer `change(User, :count)`.
        end
      RUBY
    end

    it 'ignores blocks that cannot be converted to obj/attribute pair' do
      expect_no_offenses(<<-RUBY)
        it do
          expect(run).to change { User.sum(:points) }
        end
      RUBY
    end

    it 'ignores change method of object that happens to receive a block' do
      expect_no_offenses(<<-RUBY)
        it do
          Record.change { User.count }
        end
      RUBY
    end

    include_examples(
      'autocorrect',
      'expect(run).to change { User.count }.by(1)',
      'expect(run).to change(User, :count).by(1)'
    )
  end

  context 'with EnforcedStyle `block`' do
    let(:enforced_style) { 'block' }

    it 'finds change matcher without block' do
      expect_offense(<<-RUBY)
        it do
          expect(run).to change(User, :count)
                         ^^^^^^^^^^^^^^^^^^^^ Prefer `change { User.count }`.
        end
      RUBY
    end

    it 'finds change matcher when receiver is a variable' do
      expect_offense(<<-RUBY)
        it do
          expect(run).to change(user, :count)
                         ^^^^^^^^^^^^^^^^^^^^ Prefer `change { user.count }`.
        end
      RUBY
    end

    it 'ignores methods called change' do
      expect_no_offenses(<<-RUBY)
        it do
          record.change(user, :count)
        end
      RUBY
    end

    include_examples(
      'autocorrect',
      'expect(run).to change(User, :count).by(1)',
      'expect(run).to change { User.count }.by(1)'
    )
  end
end
