# frozen_string_literal: true

RSpec.describe RuboCop::RSpec::Hook do
  include RuboCop::AST::Sexp

  def hook(source)
    described_class.new(parse_source(source).ast)
  end

  it 'extracts name' do
    expect(hook('around(:each) { }').name).to be(:around)
  end

  it 'does not break if a hook is not given a symbol literal' do
    expect(hook('before(scope) { example_setup }').knowable_scope?).to be(false)
  end

  it 'knows the scope of a hook with a symbol literal' do
    expect(hook('before { example_setup }').knowable_scope?).to be(true)
  end

  it 'ignores other arguments to hooks' do
    expect(hook('before(:each, :metadata) { example_setup }').scope)
      .to be(:each)
  end

  it 'classifies nonstandard hook arguments as invalid' do
    expect(hook('before(:nothing) { example_setup }').valid_scope?).to be(false)
  end

  it 'classifies :each as a valid hook argument' do
    expect(hook('before(:each) { example_setup }').valid_scope?).to be(true)
  end

  it 'classifies :each as an example hook' do
    expect(hook('before(:each) { }').example?).to be(true)
  end

  shared_examples 'standardizes scope' do |source, scope|
    it "interprets #{source} as having scope #{scope}" do
      expect(hook(source).scope).to equal(scope)
    end
  end

  include_examples 'standardizes scope', 'before(:each) { }',    :each
  include_examples 'standardizes scope', 'around(:example) { }', :each
  include_examples 'standardizes scope', 'after { }',            :each

  include_examples 'standardizes scope', 'before(:all) { }',     :context
  include_examples 'standardizes scope', 'around(:context) { }', :context

  include_examples 'standardizes scope', 'after(:suite) { }', :suite
end
