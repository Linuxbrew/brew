RSpec.describe RuboCop::Cop::RSpec::FactoryBot::CreateList, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  context 'when EnforcedStyle is :create_list' do
    let(:enforced_style) { :create_list }

    it 'flags usage of n.times with no arguments' do
      expect_offense(<<-RUBY)
        3.times { create :user }
        ^^^^^^^ Prefer create_list.
      RUBY
    end

    it 'flags usage of n.times when FactoryGirl.create is used' do
      expect_offense(<<-RUBY)
        3.times { FactoryGirl.create :user }
        ^^^^^^^ Prefer create_list.
      RUBY
    end

    it 'flags usage of n.times when FactoryBot.create is used' do
      expect_offense(<<-RUBY)
        3.times { FactoryBot.create :user }
        ^^^^^^^ Prefer create_list.
      RUBY
    end

    it 'ignores create method of other object' do
      expect_no_offenses(<<-RUBY)
        3.times { SomeFactory.create :user }
      RUBY
    end

    it 'ignores create in other block' do
      expect_no_offenses(<<-RUBY)
        allow(User).to receive(:create) { create :user }
      RUBY
    end

    it 'ignores n.times with argument' do
      expect_no_offenses(<<-RUBY)
        3.times { |n| create :user, created_at: n.days.ago }
      RUBY
    end

    it 'ignores n.times when there is no create call inside' do
      expect_no_offenses(<<-RUBY)
        3.times { do_something }
      RUBY
    end

    it 'ignores n.times when there is other calls but create' do
      expect_no_offenses(<<-RUBY)
        used_passwords = []
        3.times do
          u = create :user
          expect(used_passwords).not_to include(u.password)
          used_passwords << u.password
        end
      RUBY
    end

    it 'flags FactoryGirl.create calls with a block' do
      expect_offense(<<-RUBY)
        3.times do
        ^^^^^^^ Prefer create_list.
          create(:user) { |user| create :account, user: user }
        end
      RUBY
    end

    include_examples 'autocorrect',
                     '5.times { create :user }',
                     'create_list :user, 5'

    include_examples 'autocorrect',
                     '5.times { create(:user, :trait) }',
                     'create_list(:user, 5, :trait)'

    include_examples 'autocorrect',
                     '5.times { create :user, :trait, key: val }',
                     'create_list :user, 5, :trait, key: val'

    include_examples 'autocorrect',
                     '5.times { FactoryGirl.create :user }',
                     'FactoryGirl.create_list :user, 5'
  end

  context 'when EnforcedStyle is :n_times' do
    let(:enforced_style) { :n_times }

    it 'flags usage of create_list' do
      expect_offense(<<-RUBY)
        create_list :user, 3
        ^^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'flags usage of FactoryGirl.create_list' do
      expect_offense(<<-RUBY)
       FactoryGirl.create_list :user, 3
                   ^^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'flags usage of FactoryGirl.create_list with a block' do
      expect_offense(<<-RUBY)
       FactoryGirl.create_list(:user, 3) { |user| user.points = rand(1000) }
                   ^^^^^^^^^^^ Prefer 3.times.
      RUBY
    end

    it 'ignores create method of other object' do
      expect_no_offenses(<<-RUBY)
        SomeFactory.create_list :user, 3
      RUBY
    end

    include_examples 'autocorrect',
                     'create_list :user, 5',
                     '5.times { create :user }'

    include_examples 'autocorrect',
                     'create_list(:user, 5, :trait)',
                     '5.times { create(:user, :trait) }'

    include_examples 'autocorrect',
                     'create_list :user, 5, :trait, key: val',
                     '5.times { create :user, :trait, key: val }'

    include_examples 'autocorrect',
                     'FactoryGirl.create_list :user, 5',
                     '5.times { FactoryGirl.create :user }'
  end
end
