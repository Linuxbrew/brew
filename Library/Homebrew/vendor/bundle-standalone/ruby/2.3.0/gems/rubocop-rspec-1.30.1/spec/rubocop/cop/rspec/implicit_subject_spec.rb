RSpec.describe RuboCop::Cop::RSpec::ImplicitSubject, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'EnforcedStyle' => enforced_style }
  end

  context 'with EnforcedStyle `single_line_only`' do
    let(:enforced_style) { 'single_line_only' }

    it 'flags `is_expected` in multi-line examples' do
      expect_offense(<<-RUBY)
        it 'expect subject to be used' do
          is_expected.to be_good
          ^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    it 'allows `is_expected` inside `its` block, in multi-line examples' do
      expect_no_offenses(<<-RUBY)
        its(:quality) do
          is_expected.to be :high
        end
      RUBY
    end

    it 'flags `should` in multi-line examples' do
      expect_offense(<<-RUBY)
        it 'expect subject to be used' do
          should be_good
          ^^^^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    it 'allows `is_expected` in single-line examples' do
      expect_no_offenses(<<-RUBY)
        it { is_expected.to be_good }
      RUBY
    end

    it 'allows `should` in single-line examples' do
      expect_no_offenses(<<-RUBY)
        it { should be_good }
      RUBY
    end

    it 'does not flag methods called is_expected and should' do
      expect_no_offenses(<<-RUBY)
        it 'uses some similar sounding methods' do
          expect(baz).to receive(:is_expected)
          baz.is_expected
          foo.should(deny_access)
        end
      RUBY
    end

    it 'detects usage of `is_expected` inside helper methods' do
      expect_offense(<<-RUBY)
        def permits(actions)
          actions.each { |action| is_expected.to permit_action(action) }
                                  ^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    bad_code = <<-RUBY
      it 'works' do
        is_expected.to be_truthy
      end
    RUBY

    good_code = <<-RUBY
      it 'works' do
        expect(subject).to be_truthy
      end
    RUBY

    include_examples 'autocorrect',
                     bad_code,
                     good_code

    bad_code = <<-RUBY
      it 'works' do
        should be_truthy
        should_not be_falsy
      end
    RUBY

    good_code = <<-RUBY
      it 'works' do
        expect(subject).to be_truthy
        expect(subject).not_to be_falsy
      end
    RUBY

    include_examples 'autocorrect',
                     bad_code,
                     good_code
  end

  context 'with EnforcedStyle `single_statement_only`' do
    let(:enforced_style) { 'single_statement_only' }

    it 'allows `is_expected` in multi-line example with single statement' do
      expect_no_offenses(<<-RUBY)
        it 'expect subject to be used' do
          is_expected.to be_good
        end
      RUBY
    end

    it 'flags `is_expected` in multi-statement examples' do
      expect_offense(<<-RUBY)
        it 'expect subject to be used' do
          subject.age = 18
          is_expected.to be_valid
          ^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    bad_code = <<-RUBY
      it 'is valid' do
        subject.age = 18
        is_expected.to be_valid
      end
    RUBY

    good_code = <<-RUBY
      it 'is valid' do
        subject.age = 18
        expect(subject).to be_valid
      end
    RUBY

    include_examples 'autocorrect',
                     bad_code,
                     good_code

    include_examples 'autocorrect',
                     bad_code,
                     good_code
  end

  context 'with EnforcedStyle `disallow`' do
    let(:enforced_style) { 'disallow' }

    it 'flags `is_expected` in multi-line examples' do
      expect_offense(<<-RUBY)
        it 'expect subject to be used' do
          is_expected.to be_good
          ^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    it 'flags `is_expected` in single-line examples' do
      expect_offense(<<-RUBY)
        it { is_expected.to be_good }
             ^^^^^^^^^^^ Don't use implicit subject.
      RUBY
    end

    it 'flags `should` in multi-line examples' do
      expect_offense(<<-RUBY)
        it 'expect subject to be used' do
          should be_good
          ^^^^^^^^^^^^^^ Don't use implicit subject.
        end
      RUBY
    end

    it 'flags `should` in single-line examples' do
      expect_offense(<<-RUBY)
        it { should be_good }
             ^^^^^^^^^^^^^^ Don't use implicit subject.
      RUBY
    end

    it 'allows `is_expected` inside `its` block' do
      expect_no_offenses(<<-RUBY)
        its(:quality) { is_expected.to be :high }
      RUBY
    end

    include_examples 'autocorrect',
                     'it { is_expected.to be_truthy }',
                     'it { expect(subject).to be_truthy }'

    include_examples 'autocorrect',
                     'it { should be_truthy }',
                     'it { expect(subject).to be_truthy }'

    include_examples 'autocorrect',
                     'it { should_not be_truthy }',
                     'it { expect(subject).not_to be_truthy }'
  end
end
