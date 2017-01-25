test_cask 'container-sit' do
  version '1.2.3'
  sha256 '0d21a64dce625044345c8ecca888e5439feaf254dac7f884917028a744f93cf3'

  url "file://#{TEST_FIXTURE_DIR}/cask/container.sit"
  homepage 'https://example.com/container-sit'

  depends_on formula: 'unar'

  app 'container'
end
