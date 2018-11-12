RSpec.describe RuboCop::RSpec::Wording do
  let(:replacements) { { 'have' => 'has' } }
  let(:ignores)      { %w[only really]     }

  expected_rewrites =
    {
      'should return something'            => 'returns something',
      'should not return something'        => 'does not return something',
      'should do nothing'                  => 'does nothing',
      'should have sweets'                 => 'has sweets',
      'should worry about the future'      => 'worries about the future',
      'should pay for pizza'               => 'pays for pizza',
      'should obey my orders'              => 'obeys my orders',
      'should deploy the app'              => 'deploys the app',
      'should buy the product'             => 'buys the product',
      'should miss me'                     => 'misses me',
      'should fax the document'            => 'faxes the document',
      'should amass debt'                  => 'amasses debt',
      'should echo the input'              => 'echoes the input',
      'should alias the method'            => 'aliases the method',
      'should search the internet'         => 'searches the internet',
      'should wish me luck'                => 'wishes me luck',
      'should really only return one item' => 'really only returns one item',
      "shouldn't return something"         => 'does not return something',
      'SHOULD RETAIN UPPERCASE'            => 'RETAINS UPPERCASE',
      "shouldn't be true"                  => 'is not true',
      "SHOULDN'T BE true"                  => 'IS NOT true',
      "SHOULDN'T NOT RETAIN UPPERCASE"     => 'DOES NOT NOT RETAIN UPPERCASE',
      'should WORRY'                       => 'WORRIES',
      'should WISH me luck'                => 'WISHES me luck',
      ''                                   => '',
      'should'                             => '',
      "shouldn't"                          => 'does not',
      'should not'                         => 'does not',
      'should fizz'                        => 'fizzes'
    }

  expected_rewrites.each do |old, new|
    it %(rewrites "#{old}" as "#{new}") do
      rewrite =
        described_class.new(
          old,
          replace: replacements,
          ignore:  ignores
        ).rewrite

      expect(rewrite).to eql(new)
    end
  end
end
