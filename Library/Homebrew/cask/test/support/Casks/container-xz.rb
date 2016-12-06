test_cask 'container-xz' do
  version '1.2.3'
  sha256 '839263f474edde1d54a9101606e6f0dc9d963acc93f6dcc5af8d10ebc3187c02'

  url "file://#{TEST_FIXTURE_DIR}/cask/container.xz"
  homepage 'https://example.com/container-xz'

  depends_on formula: 'xz'

  app 'container-xz--1.2.3'
end
