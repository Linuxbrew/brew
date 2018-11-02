RSpec.describe RuboCop::Cop::RSpec::Pending do
  subject(:cop) { described_class.new }

  it 'flags xcontext' do
    expect_offense(<<-RUBY)
      xcontext 'test' do
      ^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xdescribe' do
    expect_offense(<<-RUBY)
      xdescribe 'test' do
      ^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xexample' do
    expect_offense(<<-RUBY)
      xexample 'test' do
      ^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xfeature' do
    expect_offense(<<-RUBY)
      xfeature 'test' do
      ^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xit' do
    expect_offense(<<-RUBY)
      xit 'test' do
      ^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xscenario' do
    expect_offense(<<-RUBY)
      xscenario 'test' do
      ^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags xspecify' do
    expect_offense(<<-RUBY)
      xspecify 'test' do
      ^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags skip inside of an it' do
    expect_offense(<<-RUBY)
      it 'test' do
        skip
        ^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags skip blocks' do
    expect_offense(<<-RUBY)
      skip 'test' do
      ^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags blocks with skip symbol metadata' do
    expect_offense(<<-RUBY)
      it 'test', :skip do
      ^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags blocks with pending symbol metadata' do
    expect_offense(<<-RUBY)
      it 'test', :pending do
      ^^^^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags blocks with skip: true metadata' do
    expect_offense(<<-RUBY)
      it 'test', skip: true do
      ^^^^^^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags pending blocks' do
    expect_offense(<<-RUBY)
      pending 'test' do
      ^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'flags pending examples when receiver is explicit' do
    expect_offense(<<-RUBY)
      RSpec.xit 'test' do
      ^^^^^^^^^^^^^^^^ Pending spec found.
      end
    RUBY
  end

  it 'does not flag describe' do
    expect_no_offenses(<<-RUBY)
      describe 'test' do; end
    RUBY
  end

  it 'does not flag example' do
    expect_no_offenses(<<-RUBY)
      example 'test' do; end
    RUBY
  end

  it 'does not flag scenario' do
    expect_no_offenses(<<-RUBY)
      scenario 'test' do; end
    RUBY
  end

  it 'does not flag specify' do
    expect_no_offenses(<<-RUBY)
      specify 'test' do; end
    RUBY
  end

  it 'does not flag feature' do
    expect_no_offenses(<<-RUBY)
      feature 'test' do; end
    RUBY
  end

  it 'does not flag context' do
    expect_no_offenses(<<-RUBY)
      context 'test' do; end
    RUBY
  end

  it 'does not flag it' do
    expect_no_offenses(<<-RUBY)
      it 'test' do; end
    RUBY
  end

  it 'does not flag it with skip: false metadata' do
    expect_no_offenses(<<-RUBY)
      it 'test', skip: false do; end
    RUBY
  end

  it 'does not flag example_group' do
    expect_no_offenses(<<-RUBY)
      example_group 'test' do; end
    RUBY
  end

  it 'does not flag method called pending' do
    expect_no_offenses(<<-RUBY)
      subject { Project.pending }
    RUBY
  end
end
