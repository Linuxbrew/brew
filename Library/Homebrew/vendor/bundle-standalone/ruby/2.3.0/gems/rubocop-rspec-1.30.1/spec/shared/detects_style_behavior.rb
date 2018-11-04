RSpec.shared_examples 'detects style' do |source, style, filename: 'x_spec.rb'|
  it 'generates a todo based on the detected style' do
    inspect_source(source, filename)

    expect(cop.config_to_allow_offenses).to eq('EnforcedStyle' => style)
  end
end
