RSpec.shared_examples 'smoke test', type: :cop_spec do
  context 'with default configuration' do
    # This is overridden to avoid a number of specs that define `cop_config`
    # (so it is referenced in the 'config' shared context) but do not define
    # all of the dependent configuration options until inside of a context
    # that is out of scope, causing a NameError.
    let(:cop_config) { {} }

    stress_tests = Pathname.glob('spec/smoke_tests/*.rb')

    raise 'No smoke tests could be found!' if stress_tests.empty?

    stress_tests.each do |path|
      it "does not crash on smoke test: #{path}" do
        source    = path.read
        file_name = path.to_s

        aggregate_failures do
          expect { inspect_source(source, file_name) }.not_to raise_error
          expect { autocorrect_source(source, file_name) }.not_to raise_error
        end
      end
    end
  end
end
