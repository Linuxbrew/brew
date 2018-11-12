RSpec.describe RuboCop::Cop::RSpec::IteratedExpectation do
  subject(:cop) { described_class.new }

  it 'flags `each` with an expectation' do
    expect_offense(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each { |user| expect(user).to be_valid }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using the `all` matcher instead of iterating over an array.
      end
    RUBY
  end

  it 'flags `each` when expectation calls method with arguments' do
    expect_offense(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each { |user| expect(user).to be_a(User) }
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using the `all` matcher instead of iterating over an array.
      end
    RUBY
  end

  it 'ignores `each` without expectation' do
    expect_no_offenses(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each { |user| allow(user).to receive(:method) }
      end
    RUBY
  end

  it 'flags `each` with multiple expectations' do
    expect_offense(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each do |user|
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Prefer using the `all` matcher instead of iterating over an array.
          expect(user).to receive(:method)
          expect(user).to receive(:other_method)
        end
      end
    RUBY
  end

  it 'ignore `each` when the body does not contain only expectations' do
    expect_no_offenses(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each do |user|
          allow(Something).to receive(:method).and_return(user)
          expect(user).to receive(:method)
          expect(user).to receive(:other_method)
        end
      end
    RUBY
  end

  it 'ignores `each` with expectation on property' do
    expect_no_offenses(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each { |user| expect(user.name).to be }
      end
    RUBY
  end

  it 'ignores assignments in the iteration' do
    expect_no_offenses(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each { |user| array = array.concat(user) }
      end
    RUBY
  end

  it 'ignores `each` when there is a negative expectation' do
    expect_no_offenses(<<-RUBY)
      it 'validates users' do
        [user1, user2, user3].each do |user|
          expect(user).not_to receive(:method)
          expect(user).to receive(:other_method)
        end
      end
    RUBY
  end
end
