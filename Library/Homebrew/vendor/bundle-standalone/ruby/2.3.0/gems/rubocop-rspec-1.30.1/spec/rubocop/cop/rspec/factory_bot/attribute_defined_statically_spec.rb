# frozen_string_literal: true

RSpec.describe RuboCop::Cop::RSpec::FactoryBot::AttributeDefinedStatically do # rubocop:disable Metrics/LineLength
  subject(:cop) { described_class.new }

  it 'registers an offense for offending code' do
    expect_offense(<<-RUBY)
      FactoryBot.define do
        factory :post do
          title "Something"
          ^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          published_at 1.day.from_now
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          status [:draft, :published].sample
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          created_at 1.day.ago
          ^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          update_times [Time.current]
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          meta_tags(foo: Time.current)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
        end
      end
    RUBY
  end

  it 'registers an offense in a trait' do
    expect_offense(<<-RUBY)
      FactoryBot.define do
        factory :post do
          trait :published do
            title "Something"
            ^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
            published_at 1.day.from_now
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          end
        end
      end
    RUBY
  end

  it 'registers an offense in a transient block' do
    expect_offense(<<-RUBY)
      FactoryBot.define do
        factory :post do
          transient do
            title "Something"
            ^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
            published_at 1.day.from_now
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
          end
        end
      end
    RUBY
  end

  it 'registers an offense for an attribute defined on `self`' do
    expect_offense(<<-RUBY)
      FactoryBot.define do
        factory :post do
          self.start { Date.today }
          self.end Date.tomorrow
          ^^^^^^^^^^^^^^^^^^^^^^ Use a block to declare attribute values.
        end
      end
    RUBY
  end

  it 'accepts valid factory definitions' do
    expect_no_offenses(<<-RUBY)
      FactoryBot.define do
        factory :post do
          trait :published do
            published_at { 1.day.from_now }
          end
          created_at { 1.day.ago }
          status { :draft }
          comments_count { 0 }
          title { "Static" }
          description { FFaker::Lorem.paragraph(10) }
          recent_statuses { [] }
          tags { { like_count: 2 } }

          before(:create, &:initialize_something)
          after(:create, &:rebuild_cache)
        end
      end
    RUBY
  end

  it 'does not add offense if out of factory bot block' do
    expect_no_offenses(<<-RUBY)
      status [:draft, :published].sample
      published_at 1.day.from_now
      created_at 1.day.ago
      update_times [Time.current]
      meta_tags(foo: Time.current)
    RUBY
  end

  it 'accepts valid association definitions' do
    expect_no_offenses(<<-RUBY)
      FactoryBot.define do
        factory :post do
          author age: 42, factory: :user
        end
      end
    RUBY
  end

  it 'accepts valid sequence definition' do
    expect_no_offenses(<<-RUBY)
      FactoryBot.define do
        factory :post do
          sequence :negative_numbers, &:-@
        end
      end
    RUBY
  end

  bad = <<-RUBY
    FactoryBot.define do
      factory :post do
        title "Something"
        comments_count 0
        tag Tag::MAGIC
        recent_statuses []
        status([:draft, :published].sample)
        published_at 1.day.from_now
        created_at(1.day.ago)
        updated_at Time.current
        update_times [Time.current]
        meta_tags(foo: Time.current)
        other_tags({ foo: Time.current })
        options color: :blue
        other_options Tag::MAGIC => :magic
        self.end Date.tomorrow

        trait :old do
          published_at 1.week.ago
        end
      end
    end
  RUBY

  corrected = <<-RUBY
    FactoryBot.define do
      factory :post do
        title { "Something" }
        comments_count { 0 }
        tag { Tag::MAGIC }
        recent_statuses { [] }
        status { [:draft, :published].sample }
        published_at { 1.day.from_now }
        created_at { 1.day.ago }
        updated_at { Time.current }
        update_times { [Time.current] }
        meta_tags { { foo: Time.current } }
        other_tags { { foo: Time.current } }
        options { { color: :blue } }
        other_options { { Tag::MAGIC => :magic } }
        self.end { Date.tomorrow }

        trait :old do
          published_at { 1.week.ago }
        end
      end
    end
  RUBY

  include_examples 'autocorrect', bad, corrected
end
