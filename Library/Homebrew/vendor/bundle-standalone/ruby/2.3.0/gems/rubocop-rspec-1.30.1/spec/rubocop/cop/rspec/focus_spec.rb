RSpec.describe RuboCop::Cop::RSpec::Focus do
  subject(:cop) { described_class.new }

  # rubocop:disable RSpec/ExampleLength
  it 'flags all rspec example blocks with that include `focus: true`' do
    expect_offense(<<-RUBY)
      example 'test', meta: true, focus: true do; end
                                  ^^^^^^^^^^^ Focused spec found.
      xit 'test', meta: true, focus: true do; end
                              ^^^^^^^^^^^ Focused spec found.
      describe 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      it 'test', meta: true, focus: true do; end
                             ^^^^^^^^^^^ Focused spec found.
      xspecify 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      specify 'test', meta: true, focus: true do; end
                                  ^^^^^^^^^^^ Focused spec found.
      example_group 'test', meta: true, focus: true do; end
                                        ^^^^^^^^^^^ Focused spec found.
      scenario 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      xexample 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      xdescribe 'test', meta: true, focus: true do; end
                                    ^^^^^^^^^^^ Focused spec found.
      context 'test', meta: true, focus: true do; end
                                  ^^^^^^^^^^^ Focused spec found.
      xcontext 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      feature 'test', meta: true, focus: true do; end
                                  ^^^^^^^^^^^ Focused spec found.
      xfeature 'test', meta: true, focus: true do; end
                                   ^^^^^^^^^^^ Focused spec found.
      xscenario 'test', meta: true, focus: true do; end
                                    ^^^^^^^^^^^ Focused spec found.
    RUBY
  end

  it 'flags all rspec example blocks that include `:focus`' do
    expect_offense(<<-RUBY)
      example_group 'test', :focus do; end
                            ^^^^^^ Focused spec found.
      feature 'test', :focus do; end
                      ^^^^^^ Focused spec found.
      xexample 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      xdescribe 'test', :focus do; end
                        ^^^^^^ Focused spec found.
      xscenario 'test', :focus do; end
                        ^^^^^^ Focused spec found.
      specify 'test', :focus do; end
                      ^^^^^^ Focused spec found.
      example 'test', :focus do; end
                      ^^^^^^ Focused spec found.
      xfeature 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      xspecify 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      scenario 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      describe 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      xit 'test', :focus do; end
                  ^^^^^^ Focused spec found.
      context 'test', :focus do; end
                      ^^^^^^ Focused spec found.
      xcontext 'test', :focus do; end
                       ^^^^^^ Focused spec found.
      it 'test', :focus do; end
                 ^^^^^^ Focused spec found.
    RUBY
  end
  # rubocop:enable RSpec/ExampleLength

  it 'does not flag unfocused specs' do
    expect_no_offenses(<<-RUBY)
      xcontext      'test' do; end
      xscenario     'test' do; end
      xspecify      'test' do; end
      describe      'test' do; end
      example       'test' do; end
      xexample      'test' do; end
      scenario      'test' do; end
      specify       'test' do; end
      xit           'test' do; end
      feature       'test' do; end
      xfeature      'test' do; end
      context       'test' do; end
      it            'test' do; end
      example_group 'test' do; end
      xdescribe     'test' do; end
    RUBY
  end

  it 'does not flag a method that is focused twice' do
    expect_offense(<<-RUBY)
      fit "foo", :focus do
      ^^^^^^^^^^^^^^^^^ Focused spec found.
      end
    RUBY
  end

  it 'ignores non-rspec code with :focus blocks' do
    expect_no_offenses(<<-RUBY)
      some_method "foo", focus: true do
      end
    RUBY
  end

  it 'flags focused block types' do
    expect_offense(<<-RUBY)
      fdescribe 'test' do; end
      ^^^^^^^^^^^^^^^^ Focused spec found.
      ffeature 'test' do; end
      ^^^^^^^^^^^^^^^ Focused spec found.
      fcontext 'test' do; end
      ^^^^^^^^^^^^^^^ Focused spec found.
      fit 'test' do; end
      ^^^^^^^^^^ Focused spec found.
      fscenario 'test' do; end
      ^^^^^^^^^^^^^^^^ Focused spec found.
      fexample 'test' do; end
      ^^^^^^^^^^^^^^^ Focused spec found.
      fspecify 'test' do; end
      ^^^^^^^^^^^^^^^ Focused spec found.
      focus 'test' do; end
      ^^^^^^^^^^^^ Focused spec found.
    RUBY
  end
end
