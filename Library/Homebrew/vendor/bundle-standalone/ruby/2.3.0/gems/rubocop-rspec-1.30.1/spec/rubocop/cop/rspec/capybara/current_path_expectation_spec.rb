RSpec.describe RuboCop::Cop::RSpec::Capybara::CurrentPathExpectation do
  subject(:cop) { described_class.new }

  it 'flags violations for `expect(current_path)`' do
    expect_offense(<<-RUBY)
      expect(current_path).to eq("/callback")
      ^^^^^^ Do not set an RSpec expectation on `current_path` in Capybara feature specs - instead, use the `have_current_path` matcher on `page`
    RUBY
  end

  it 'flags violations for `expect(page.current_path)`' do
    expect_offense(<<-RUBY)
      expect(page.current_path).to eq("/callback")
      ^^^^^^ Do not set an RSpec expectation on `current_path` in Capybara feature specs - instead, use the `have_current_path` matcher on `page`
    RUBY
  end

  it "doesn't flag a violation for other expectations" do
    expect_no_offenses(<<-RUBY)
      expect(current_user).to eq(user)
    RUBY
  end

  it "doesn't flag a violation for other references to `current_path`" do
    expect_no_offenses(<<-RUBY)
      current_path = WalkingRoute.last.path
    RUBY
  end
end
