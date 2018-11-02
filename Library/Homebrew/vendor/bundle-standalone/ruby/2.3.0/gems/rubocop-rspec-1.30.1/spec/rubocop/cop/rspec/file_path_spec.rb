RSpec.describe RuboCop::Cop::RSpec::FilePath, :config do
  subject(:cop) { described_class.new(config) }

  it 'registers an offense for a bad path' do
    expect_offense(<<-RUBY, 'wrong_path_foo_spec.rb')
      describe MyClass, 'foo' do; end
      ^^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*foo*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a wrong class but a correct method' do
    expect_offense(<<-RUBY, 'wrong_class_foo_spec.rb')
      describe MyClass, '#foo' do; end
      ^^^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*foo*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a repeated .rb' do
    expect_offense(<<-RUBY, 'my_class/foo_spec.rb.rb')
      describe MyClass, '#foo' do; end
      ^^^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*foo*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a file missing a .rb' do
    expect_offense(<<-RUBY, 'my_class/foo_specorb')
      describe MyClass, '#foo' do; end
      ^^^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*foo*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a wrong class and highlights metadata' do
    expect_offense(<<-RUBY, 'wrong_class_foo_spec.rb')
      describe MyClass, '#foo', blah: :blah do; end
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*foo*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a wrong class name' do
    expect_offense(<<-RUBY, 'wrong_class_spec.rb')
      describe MyClass do; end
      ^^^^^^^^^^^^^^^^ Spec path should end with `my_class*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a wrong class name with a symbol argument' do
    expect_offense(<<-RUBY, 'wrong_class_spec.rb')
      describe MyClass, :foo do; end
      ^^^^^^^^^^^^^^^^^^^^^^ Spec path should end with `my_class*_spec.rb`.
    RUBY
  end

  it 'registers an offense for a file missing _spec' do
    expect_offense(<<-RUBY, 'user.rb')
      describe User do; end
      ^^^^^^^^^^^^^ Spec path should end with `user*_spec.rb`.
    RUBY
  end

  it 'skips specs that do not describe a class / method' do
    expect_no_offenses(<<-RUBY, 'some/class/spec.rb')
      describe 'Test something' do; end
    RUBY
  end

  it 'skips specs that do have multiple top level describes' do
    expect_no_offenses(<<-RUBY, 'some/class/spec.rb')
      describe MyClass, 'do_this' do; end
      describe MyClass, 'do_that' do; end
    RUBY
  end

  it 'checks class specs' do
    expect_no_offenses(<<-RUBY, 'some/class_spec.rb')
      describe Some::Class do; end
    RUBY
  end

  it 'allows different parent directories' do
    expect_no_offenses(<<-RUBY, 'parent_dir/some/class_spec.rb')
      describe Some::Class do; end
    RUBY
  end

  it 'handles CamelCaps class names' do
    expect_no_offenses(<<-RUBY, 'my_class_spec.rb')
      describe MyClass do; end
    RUBY
  end

  it 'handles ACRONYMClassNames' do
    expect_no_offenses(<<-RUBY, 'abc_one/two_spec.rb')
      describe ABCOne::Two do; end
    RUBY
  end

  it 'handles ALLCAPS class names' do
    expect_no_offenses(<<-RUBY, 'allcaps_spec.rb')
      describe ALLCAPS do; end
    RUBY
  end

  it 'handles alphanumeric class names' do
    expect_no_offenses(<<-RUBY, 'ipv4_and_ipv6_spec.rb')
      describe IPV4AndIPV6 do; end
    RUBY
  end

  it 'checks instance methods' do
    expect_no_offenses(<<-RUBY, 'some/class/inst_spec.rb')
      describe Some::Class, '#inst' do; end
    RUBY
  end

  it 'checks class methods' do
    expect_no_offenses(<<-RUBY, 'some/class/inst_spec.rb')
      describe Some::Class, '.inst' do; end
    RUBY
  end

  it 'allows flat hierarchies for instance methods' do
    expect_no_offenses(<<-RUBY, 'some/class_inst_spec.rb')
      describe Some::Class, '#inst' do; end
    RUBY
  end

  it 'allows flat hierarchies for class methods' do
    expect_no_offenses(<<-RUBY, 'some/class_inst_spec.rb')
      describe Some::Class, '.inst' do; end
    RUBY
  end

  it 'allows subdirs for instance methods' do
    filename = 'some/class/instance_methods/inst_spec.rb'
    expect_no_offenses(<<-RUBY, filename)
      describe Some::Class, '#inst' do; end
    RUBY
  end

  it 'allows subdirs for class methods' do
    filename = 'some/class/class_methods/inst_spec.rb'
    expect_no_offenses(<<-RUBY, filename)
      describe Some::Class, '.inst' do; end
    RUBY
  end

  it 'ignores non-alphanumeric characters' do
    expect_no_offenses(<<-RUBY, 'some/class/pred_spec.rb')
      describe Some::Class, '#pred?' do; end
    RUBY
  end

  it 'allows bang method' do
    expect_no_offenses(<<-RUBY, 'some/class/bang_spec.rb')
      describe Some::Class, '#bang!' do; end
    RUBY
  end

  it 'allows flexibility with predicates' do
    filename = 'some/class/thing_predicate_spec.rb'
    expect_no_offenses(<<-RUBY, filename)
      describe Some::Class, '#thing?' do; end
    RUBY
  end

  it 'allows flexibility with operators' do
    filename = 'my_little_class/spaceship_operator_spec.rb'
    expect_no_offenses(<<-RUBY, filename)
      describe MyLittleClass, '#<=>' do; end
    RUBY
  end

  context 'when configured with CustomTransform' do
    let(:cop_config) { { 'CustomTransform' => { 'FooFoo' => 'foofoo' } } }

    it 'respects custom module name transformation' do
      expect_no_offenses(<<-RUBY, 'foofoo/some/class/bar_spec.rb')
        describe FooFoo::Some::Class, '#bar' do; end
      RUBY
    end

    it 'ignores routing specs' do
      expect_no_offenses(<<-RUBY, 'foofoo/some/class/bar_spec.rb')
        describe MyController, "#foo", type: :routing do; end
      RUBY
    end
  end

  context 'when configured with IgnoreMethods' do
    let(:cop_config) { { 'IgnoreMethods' => true } }

    it 'does not care about the described method' do
      expect_no_offenses(<<-RUBY, 'my_class_spec.rb')
        describe MyClass, '#look_here_a_method' do; end
      RUBY
    end
  end
end
