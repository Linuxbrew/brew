# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::Rails::HttpStatus, :config do
  subject(:cop) { described_class.new(config) }

  context 'when EnforcedStyle is `symbolic`' do
    let(:cop_config) { { 'EnforcedStyle' => 'symbolic' } }

    it 'registers an offense when using numeric value' do
      expect_offense(<<-RUBY)
        it { is_expected.to have_http_status 200 }
                                             ^^^ Prefer `:ok` over `200` to describe HTTP status code.
      RUBY
    end

    it 'does not register an offense when using symbolic value' do
      expect_no_offenses(<<-RUBY)
        it { is_expected.to have_http_status :ok }
      RUBY
    end

    it 'does not register an offense when using custom HTTP code' do
      expect_no_offenses(<<-RUBY)
        it { is_expected.to have_http_status 550 }
      RUBY
    end

    include_examples 'autocorrect',
                     'it { is_expected.to have_http_status 200 }',
                     'it { is_expected.to have_http_status :ok }'

    include_examples 'autocorrect',
                     'it { is_expected.to have_http_status 404 }',
                     'it { is_expected.to have_http_status :not_found }'

    context 'with parenthesis' do
      include_examples 'autocorrect',
                       'it { is_expected.to have_http_status(200) }',
                       'it { is_expected.to have_http_status(:ok) }'

      include_examples 'autocorrect',
                       'it { is_expected.to have_http_status(404) }',
                       'it { is_expected.to have_http_status(:not_found) }'
    end
  end

  context 'when EnforcedStyle is `numeric`' do
    let(:cop_config) { { 'EnforcedStyle' => 'numeric' } }

    it 'registers an offense when using symbolic value' do
      expect_offense(<<-RUBY)
        it { is_expected.to have_http_status :ok }
                                             ^^^ Prefer `200` over `:ok` to describe HTTP status code.
      RUBY
    end

    it 'does not register an offense when using numeric value' do
      expect_no_offenses(<<-RUBY)
        it { is_expected.to have_http_status 200 }
      RUBY
    end

    it 'does not register an offense when using whitelisted symbols' do
      expect_no_offenses(<<-RUBY)
        it { is_expected.to have_http_status :error }
        it { is_expected.to have_http_status :success }
        it { is_expected.to have_http_status :missing }
        it { is_expected.to have_http_status :redirect }
      RUBY
    end

    include_examples 'autocorrect',
                     'it { is_expected.to have_http_status :ok }',
                     'it { is_expected.to have_http_status 200 }'

    include_examples 'autocorrect',
                     'it { is_expected.to have_http_status :not_found }',
                     'it { is_expected.to have_http_status 404 }'

    context 'with parenthesis' do
      include_examples 'autocorrect',
                       'it { is_expected.to have_http_status(:ok) }',
                       'it { is_expected.to have_http_status(200) }'

      include_examples 'autocorrect',
                       'it { is_expected.to have_http_status(:not_found) }',
                       'it { is_expected.to have_http_status(404) }'
    end
  end
end
