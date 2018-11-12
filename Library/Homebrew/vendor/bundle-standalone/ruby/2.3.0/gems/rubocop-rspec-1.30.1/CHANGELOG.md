# Change log

## Master (Unreleased)

## 1.30.1 (2018-11-01)

* `FactoryBot/CreateList` now ignores `times` blocks with an argument. ([@Darhazer][])

## 1.30.0 (2018-10-08)

* Add config to `RSpec/VerifiedDoubles` to enforcement of verification on unnamed doubles. ([@BrentWheeldon][])
* Fix `FactoryBot/AttributeDefinedStatically` not working when there is a non-symbol key. ([@vzvu3k6k][])
* Fix false positive in `RSpec/ImplicitSubject` when `is_expected` is used inside `its()` block. ([@Darhazer][])
* Add `single_statement_only` style to  `RSpec/ImplicitSubject` as a more relaxed alternative to `single_line_only`. ([@Darhazer][])
* Add `RSpec/UnspecifiedException` as a default cop to encourage more-specific `expect{}.to raise_error(ExceptionType)`, or `raise_exception` style handling of exceptions. ([@daveworth][])

## 1.29.1 (2018-09-01)

* Fix false negative in `FactoryBot/AttributeDefinedStatically` when attribute is defined on `self`. ([@Darhazer][])
* `RSpec/FactoryBot` cops will now also inspect the `spec/factories.rb` path by default. ([@bquorning][])

## 1.29.0 (2018-08-25)

* `RSpec/InstanceVariable` - Recommend local variables in addition to `let`. ([@jaredbeck][])
* Add `RSpec/ImplicitSubject` cop. ([@Darhazer][])
* Add `RSpec/HooksBeforeExamples` cop. ([@Darhazer][])

## 1.28.0 (2018-08-14)

* Add `RSpec/ReceiveNever` cop enforcing usage of `not_to receive` instead of `never` matcher. ([@Darhazer][])
* Fix false positive in `RSpec/EmptyLineAfterExampleGroup` cop when example is inside `if`. ([@Darhazer][])
* Add `RSpec/MissingExampleGroupArgument` to enforce first argument for an example group. ([@geniou][])
* Drop support for ruby `2.1`. ([@bquorning][])
* Add `FactoryBot/AttributeDefinedStatically` cop to help FactoryBot users with the deprecation of static attributes. ([@composerinteralia][], [@seanpdoyle][])
* Remove `FactoryBot/DynamicAttributeDefinedStatically` and `FactoryBot/StaticAttributeDefinedDynamically` cops. ([@composerinteralia][])

## 1.27.0 (2018-06-14)

* `RSpec/LeadingSubject` now enforces subject to be before any examples, hooks or let declarations. ([@Darhazer][])
* Fix `RSpec/NotToNot` to highlight only the selector (`not_to` or `to_not`), so it works also on `expect { ... }` blocks. ([@bquorning][])
* Add `RSpec/EmptyLineAfterHook` cop. ([@bquorning][])
* Add `RSpec/EmptyLineAfterExampleGroup` cop to check that there is an empty line after example group blocks. ([@bquorning][])
* Fix `RSpec/DescribeClass` crashing on `RSpec.describe` without arguments. ([@Darhazer][])
* Bump RuboCop requirement to v0.56.0. ([@bquorning][])
* Fix `RSpec/OverwritingSetup` crashing if a variable is used as an argument for `let`. ([@Darhazer][])

## 1.26.0 (2018-06-06)

* Fix false positive in `RSpec/EmptyExampleGroup` cop when methods named like a RSpec method are used.  ([@Darhazer][])
* Fix `Capybara/FeatureMethods` not working when there is require before the spec. ([@Darhazer][])
* Fix `RSpec/EmptyLineAfterFinalLet`: allow a comment to be placed after latest let, requiring empty line after the comment. ([@Darhazer][])
* Add `RSpec/ReceiveCounts` cop to enforce usage of :once and :twice matchers. ([@Darhazer][])

## 1.25.1 (2018-04-10)

* Fix false positive in `RSpec/Pending` cop when pending is used as a method name.  ([@Darhazer][])
* Fix `FactoryBot/DynamicAttributeDefinedStatically` false positive when using symbol proc argument for a sequence. ([@tdeo][])

## 1.25.0 (2018-04-07)

* Add `RSpec/SharedExamples` cop to enforce consistent usage of string to titleize shared examples. ([@anthony-robin][])
* Add `RSpec/Be` cop to enforce passing argument to the generic `be` matcher. ([@Darhazer][])
* Fix false positives in `StaticAttributeDefinedDynamically` and `ReturnFromStub` when a const is used in an array or hash. ([@Darhazer][])
* Add `RSpec/Pending` cop to enforce no existing pending or skipped examples.  This is disabled by default. ([@patrickomatic][])
* Fix `RSpec/NestedGroups` cop support --auto-gen-config. ([@walf443][])
* Fix false positives in `Capybara/FeatureMethods` when feature methods are used as property names in a factory. ([@Darhazer][])
* Allow configuring enabled methods in `Capybara/FeatureMethods`. ([@Darhazer][])
* Add `FactoryBot/CreateList` cop. ([@Darhazer][])

## 1.24.0 (2018-03-06)

* Compatibility with RuboCop v0.53.0. ([@bquorning][])
* The `Rails/HttpStatus` cop is unavailable if the `rack` gem cannot be loaded. ([@bquorning][])
* Fix `Rails/HttpStatus` not working with custom HTTP status codes. ([@bquorning][])
* Fix `FactoryBot/StaticAttributeDefinedDynamically` to handle empty block. ([@abrom][])
* Fix false positive in `FactoryBot/DynamicAttributeDefinedStatically` when a before/after callback has a symbol proc argument. ([@abrom][])

## 1.23.0 (2018-02-23)

* Add `RSpec/Rails/HttpStatus` cop to enforce consistent usage of the status format (numeric or symbolic). ([@anthony-robin][], [@jojos003][])
* Fix false negative in `RSpec/ReturnFromStub` when a constant is being returned by the stub. ([@Darhazer][])
* Fix `FactoryBot/DynamicAttributeDefinedStatically` to handle dynamic attributes inside arrays/hashes. ([@abrom][])
* Add `FactoryBot/StaticAttributeDefinedDynamically` (based on dynamic attribute cop). ([@abrom][])

## 1.22.2 (2018-02-01)

* Fix error in `RSpec/DescribedClass` when working on an empty `describe` block. ([@bquorning][])

## 1.22.1 (2018-01-17)

* Fix false positives in `RSpec/ReturnFromStub`. ([@Darhazer][])

## 1.22.0 (2018-01-10)

* Updates `describe_class` to account for RSpecs `:system` wrapper of rails system tests. ([@EliseFitz15][])
* Add `RSpec/ExpectChange` cop to enforce consistent usage of the change matcher. ([@Darhazer][])
* Add autocorrect support to `RSpec/LetBeforeExamples`. ([@Darhazer][])
* Fix `RSpec/InstanceVariable` flagging instance variables inside dynamically defined class. ([@Darhazer][])
* Add autocorrect support for `RSpec/ReturnFromStub` cop. ([@bquorning][])
* Add `RSpec/ExampleWithoutDescription` cop. ([@Darhazer][])

## 1.21.0 (2017-12-13)

* Compatibility with RuboCop v0.52.0. ([@bquorning][])
* Improve performance when user does not override default RSpec Pattern config. ([@walf443][])
* Add `AggregateFailuresByDefault` configuration for `RSpec/MultipleExpectations` cop. ([@onk][])

## 1.20.1 (2017-11-15)

* Add "without" to list of default allowed prefixes for `RSpec/ContextWording`. ([@bquorning][])

## 1.20.0 (2017-11-09)

* Rename namespace `FactoryGirl` to `FactoryBot` following original library update. ([@walf443][])
* Fix exception in `RSpec/ReturnFromStub` on empty block. ([@yevhene][])
* Add `RSpec/ContextWording` cop. ([@pirj][], [@telmofcosta][])
* Fix `RSpec/SubjectStub` cop matches receive message inside all matcher. ([@walf443][])

## 1.19.0 (2017-10-18)

Compatibility release so users can upgrade RuboCop to 0.51.0. No new features.

## 1.18.0 (2017-09-29)

* Fix false positive in `Capybara/FeatureMethods`. ([@Darhazer][])
* Add `RSpec/Capybara/CurrentPathExpectation` cop for feature specs, disallowing setting expectations on `current_path`. ([@timrogers][])
* Fix false positive in `RSpec/LetBeforeExamples` cop when example group contains single let. ([@Darhazer][])

## 1.17.1 (2017-09-20)

* Improved `RSpec/ReturnFromStub` to handle string interpolation, hashes and do..end blocks. ([@Darhazer][])
* Fixed compatibility with JRuby. ([@zverok][])

## 1.17.0 (2017-09-14)

* Add `RSpec/Capybara` namespace including the first cop for feature specs: `Capybara/FeatureMethods`. ([@rspeicher][])
* Update to RuboCop 0.50.0. ([@bquorning][])

## 1.16.0 (2017-09-06)

* Add `RSpec/FactoryGirl` namespace including the first cop for factories: `FactoryGirl/DynamicAttributeDefinedStatically`. ([@jonatas][])
* Add disabled by default `RSpec/AlignLeftLetBrace`. ([@backus][])
* Add disabled by default `RSpec/AlignRightLetBrace`. ([@backus][])
* Add `RSpec/LetBeforeExamples` cop. ([@Darhazer][])
* Add `RSpec/MultipleSubjects` cop. ([@backus][])
* Add `RSpec/ReturnFromStub` cop. ([@Darhazer][])
* Add `RSpec/VoidExpect` cop. ([@pocke][])
* Add `RSpec/InvalidPredicateMatcher` cop. ([@pocke][])
* Change HookArgument cop to detect when hook has a receiver. ([@pocke][])
* Add `RSpec/PredicateMatcher` cop. ([@pocke][])
* Add `RSpec/ExpectInHook` cop. ([@pocke][])
* `RSpec/MultipleExpectations` now detects usage of expect_any_instance_of. ([@Darhazer][])
* `RSpec/MultipleExpectations` now detects usage of is_expected. ([@bmorrall][])

## 1.15.1 (2017-04-30)

* Fix the handling of various edge cases in the `RSpec/ExampleWording` cop, including one that would cause autocorrect to crash. ([@dgollahon][])
* Fix `RSpec/IteratedExpectation` crashing when there is an assignment in the iteration. ([@Darhazer][])
* Fix false positive in `RSpec/SingleArgumentMessageChain` cop when the single argument is a hash. ([@Darhazer][])

## 1.15.0 (2017-03-24)

* Add `RSpec/DescribeSymbol` cop. ([@rspeicher][])
* Fix error when `RSpec/OverwritingSetup` and `RSpec/ScatteredLet` analyzed empty example groups. ([@backus][])

## 1.14.0 (2017-03-24)

* Add `RSpec/OverwritingSetup` cop. ([@Darhazer][])
* Add autocorrect support for `RSpec/LeadingSubject` cop. ([@Darhazer][])
* Add `RSpec/ScatteredLet` cop. ([@Darhazer][])
* Add `RSpec/IteratedExpectation` cop. ([@Darhazer][])
* Add `RSpec/EmptyLineAfterSubject` cop. ([@Darhazer][])
* Add `RSpec/EmptyLineAfterFinalLet` cop. ([@Darhazer][])

## 1.13.0 (2017-03-07)

* Add repeated 'it' detection to `RSpec/ExampleWording` cop. ([@dgollahon][])
* Add [observed_nesting/max_nesting] info to `RSpec/NestedGroups` messages. ([@dgollahon][])
* Add `RSpec/ItBehavesLike` cop. ([@dgollahon][])
* Add `RSpec/SharedContext` cop. ([@Darhazer][])
* `Rspec/MultipleExpectations`: Count aggregate_failures block as single expectation. ([@Darhazer][])
* Fix `ExpectActual` cop flagging `rspec-rails` routing specs. ([@backus][])
* Fix `FilePath` cop not registering offenses for files like `spec/blog/user.rb` when it should be `spec/blog/user_spec.rb`. ([@backus][])

## 1.12.0 (2017-02-21)

* Add `RSpec/InstanceSpy` cop. ([@Darhazer][])
* Add `RSpec/BeforeAfterAll` for avoiding leaky global test setup. ([@cfabianski][])

## 1.11.0 (2017-02-16)

* Add `AroundBlock` cop. ([@Darhazer][])
* Add `EnforcedStyle` configuration for `RSpec/DescribedClass` cop. ([@Darhazer][])
* Fix false positive for `RSpec/RepeatedExample` cop. ([@redross][])

## 1.10.0 (2017-01-15)

* Fix false negative for `RSpec/MessageSpies` cop. ([@onk][])
* Fix internal dependencies on RuboCop to be compatible with 0.47 release. ([@backus][])
* Add autocorrect support for `SingleArgumentMessageChain` cop. ([@bquorning][])
* Rename `NestedGroups`' configuration key from `MaxNesting` to `Max` in order to be consistent with other cop configuration. ([@backus][])
* Add `RepeatedExample` cop for detecting repeated examples within example groups. ([@backus][])
* Add `ScatteredSetup` cop for enforcing that only one `before`, `around`, and `after` hook are used per example group scope. ([@backus][])
* Add `ExpectOutput` cop for recommending `expect { ... }.to output(...).to_stdout`. ([@backus][])

## 1.9.1 (2017-01-02)

* Fix unintentional regression change in `NestedGroups` reported in #270. ([@backus][])
* Change `MaxNesting` for `NestedGroups` from 2 to 3. ([@backus][])

## 1.9.0 (2016-12-29)

* Add `MessageSpies` cop for enforcing consistent style of either `expect(...).to have_received` or `expect(...).to receive`, intended as a replacement for the `MessageExpectation` cop. ([@bquorning][])
* Fix `DescribeClass` to not flag `describe` at the top of a block of shared examples. ([@clupprich][])
* Add `SingleArgumentMessageChain` cop for recommending use of `receive` instead of `receive_message_chain` where possible. ([@bquorning][])
* Add `RepeatedDescription` cop for detecting repeated example descriptions within example groups. ([@backus][])

## 1.8.0 (2016-10-27)

* Optionally ignore method names in the `describe` argument when running the `FilePath` cop. ([@bquorning][])
* Fix regression in how `FilePath` converts alphanumeric class names into paths. ([@bquorning][])
* Add `ImplicitExpect` cop for enforcing `should` vs. `is_expected.to`. ([@backus][])
* Disable `MessageExpectation` cop in the default configuration. ([@bquorning][])

## 1.7.0 (2016-08-24)

* Add support for checking all example groups with `ExampleLength`. ([@backus][])
* Add support for checking shared example groups for `DescribedClass`. ([@backus][])
* Add support for checking `its` from [rspec-its](https://github.com/rspec/rspec-its). ([@backus][])
* Add `EmptyExampleGroup` cop for detecting `describe`s and `context`s without any tests inside. ([@backus][])
* Add `CustomIncludeMethods` configuration option for `EmptyExampleGroup`. ([@backus][])
* Add `NestedGroups` cop for detecting excessive example group nesting. ([@backus][])
* Add `MaxNesting` configuration option for `NestedGroups` cop. ([@backus][])
* Add `ExpectActual` cop for detecting literal values within `expect(...)`. ([@backus][])
* Add `MultipleExpectations` cop for detecting multiple `expect(...)` calls within one example. ([@backus][])
* Add `Max` configuration option for `MultipleExpectations`. ([@backus][])
* Add `SubjectStub` cop for testing stubbed test subjects. ([@backus][])
* Add `LetSetup` cop for detecting cases where `let!` is used for test setup. ([@backus][])
* Change all cops to only inspect files with names following rspec convention (`*/spec/*` and/or `_spec.rb`). ([@backus][])
* Add `AllCops/RSpec` configuration option for specifying custom spec file patterns. ([@backus][])
* Add `AssignmentOnly` configuration option for `RSpec/InstanceVariable` cop. ([@backus][])
* Add `BeEql` cop which looks for expectations that can use `be(...)` instead of `eql(...)`. ([@backus][])
* Add autocorrect support for `BeEql` cop. ([@backus][])
* Add `MessageExpectation` cop for enforcing consistent style of either `expect(...).to receive` or `allow(...).to receive`. ([@backus][])
* Add `MessageChain` cop. ([@bquorning][])

## 1.6.0 (2016-08-03)

* Add `SkipBlocks` option for `DescribedClass` cop. ([@backus][])

## 1.5.3 (2016-08-02)

* Add `RSpec/NamedSubject` cop. ([@backus][])

## 1.5.2 (2016-08-01)

* Drop support for ruby `2.0.0` and `2.1.0`. ([@backus][])
* Internal refactorings and improved test coverage. ([@backus][])

## 1.5.1 (2016-07-20)

* Fix `unrecognized parameter RSpec/VerifiedDoubles:IgnoreSymbolicNames` warning. ([@jeffreyc][])
* Update to rubocop 0.41.2. ([@backus][])

## 1.5.0 (2016-05-17)

* Expand `VerifiedDoubles` cop to check for `spy` as well as `double`. ([@andyw8][])
* Enable `VerifiedDoubles` cop by default. ([@andyw8][])
* Add `IgnoreSymbolicNames` option for `VerifiedDoubles` cop. ([@andyw8][])
* Add `RSpec::ExampleLength` cop. ([@andyw8][])
* Handle alphanumeric class names in `FilePath` cop. ([@andyw8][])
* Skip `DescribeClass` cop for view specs. ([@andyw8][])
* Skip `FilePath` cop for Rails routing specs. ([@andyw8][])
* Add cop to check for focused specs. ([@renanborgescampos][], [@jaredmoody][])
* Clean-up `RSpec::NotToNot` to use same configuration semantics as other Rubocop cops, add autocorrect support for `RSpec::NotToNot`. ([@baberthal][])
* Update to rubocop 0.40.0. ([@nijikon][])

## 1.4.1 (2016-04-03)

* Ignore routing specs for DescribeClass cop. ([@nijikon][])
* Move rubocop dependency to runtime. ([@nijikon][])
* Update to rubocop 0.39.0. ([@nijikon][])

## 1.4.0 (2016-02-15)

* Update to rubocop 0.37.2. ([@nijikon][])
* Update ruby versions we test against. ([@nijikon][])
* Add `RSpec::NotToNot` cop. ([@miguelfteixeira][])
* Add `Rspec/AnyInstance` cop. ([@mlarraz][])

## 1.3.1

* Fix auto correction issue - syntax had changed in RuboCop v0.31. ([@bquorning][])
* Add RuboCop clone to vendor folder - see #39 for details. ([@bquorning][])

## 1.3.0

* Ignore non string arguments for FilePathCop - thanks to @deivid-rodriguez. ([@geniou][])
* Skip DescribeMethod cop for tagged specs. ([@deivid-rodriguez][])
* Skip DescribeClass cop for feature/request specs. ([@deivid-rodriguez][])

## 1.2.2

* Make `RSpec::ExampleWording` case insensitive. ([@geniou][])

## 1.2.1

* Add `RSpec::VerifiedDoubles` cop. ([@andyw8][])

## 1.2.0

* Drop support of ruby `1.9.2`. ([@geniou][])
* Update to RuboCop `~> 0.24`. ([@geniou][])
* Add `autocorrect` to `RSpec::ExampleWording`. This experimental - use with care and check the changes. ([@geniou][])
* Fix config loader debug output. ([@geniou][])
* Rename `FileName` cop to `FilePath` as a workaround - see [#19](https://github.com/nevir/rubocop-rspec/issues/19). ([@geniou][])

## 1.1.0

* Add `autocorrect` to `RSpec::DescribedClass` cop. ([@geniou][])

## 1.0.1

* Add `config` folder to gemspec. ([@pstengel][])

## 1.0.rc3

* Update to RuboCop `>= 0.23`. ([@geniou][])
* Add configuration option for `CustomTransformation` to `FileName` cop. ([@geniou][])

## 1.0.rc2

* Gem is no longer 20MB (sorry!). ([@nevir][])
* `RspecFileName` cop allows for method specs to organized into directories by class and type. ([@nevir][])

## 1.0.rc1

* Update code to work with rubocop `>= 0.19`. ([@geniou][])
* Split `UnitSpecNaming` cop into `RSpecDescribeClass`, `RSpecDescribeMethod` and `RSpecFileName` and enabled them all by default. ([@geniou][])
* Add `RSpecExampleWording` cop to prevent to use of should at the beginning of the spec description. ([@geniou][])
* Fix `RSpecFileName` cop for non-class specs. ([@geniou][])
* Adapt `RSpecFileName` cop to commen naming convention and skip spec with multiple top level describes. ([@geniou][])
* Add `RSpecMultipleDescribes` cop to check for multiple top level describes. ([@geniou][])
* Add `RSpecDescribedClass` to promote the use of `described_class`. ([@geniou][])
* Add `RSpecInstanceVariable` cop to check for the usage of instance variables. ([@geniou][])

<!-- Contributors -->

[@andyw8]: https://github.com/andyw8
[@backus]: https://github.com/backus
[@bquorning]: https://github.com/bquorning
[@deivid-rodriguez]: https://github.com/deivid-rodriguez
[@geniou]: https://github.com/geniou
[@jaredbeck]: https://github.com/jaredbeck
[@jawshooah]: https://github.com/jawshooah
[@nevir]: https://github.com/nevir
[@nijikon]: https://github.com/nijikon
[@pstengel]: https://github.com/pstengel
[@miguelfteixeira]: https://github.com/miguelfteixeira
[@mlarraz]: https://github.com/mlarraz
[@renanborgescampos]: https://github.com/renanborgescampos
[@jaredmoody]: https://github.com/jaredmoody
[@baberthal]: https://github.com/baberthal
[@jeffreyc]: https://github.com/jeffreyc
[@clupprich]: https://github.com/clupprich
[@onk]: https://github.com/onk
[@Darhazer]: https://github.com/Darhazer
[@redross]: https://github.com/redross
[@cfabianski]: https://github.com/cfabianski
[@dgollahon]: https://github.com/dgollahon
[@rspeicher]: https://github.com/rspeicher
[@jonatas]: https://github.com/jonatas
[@pocke]: https://github.com/pocke
[@bmorrall]: https:/github.com/bmorrall
[@zverok]: https:/github.com/zverok
[@timrogers]: https://github.com/timrogers
[@yevhene]: https://github.com/yevhene
[@walf443]: https://github.com/walf443
[@pirj]: https://github.com/pirj
[@telmofcosta]: https://github.com/telmofcosta
[@EliseFitz15]: https://github.com/EliseFitz15
[@anthony-robin]: https://github.com/anthony-robin
[@jojos003]: https://github.com/jojos003
[@abrom]: https://github.com/abrom
[@patrickomatic]: https://github.com/patrickomatic
[@tdeo]: https://github.com/tdeo
[@composerinteralia]: https://github.com/composerinteralia
[@seanpdoyle]: https://github.com/seanpdoyle
[@vzvu3k6k]: https://github.com/vzvu3k6k
[@BrentWheeldon]: https://github.com/BrentWheeldon
[@daveworth]: https://github.com/daveworth
