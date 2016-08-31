test_cask 'container-7z' do
  version '1.2.3'
  sha256 '3f9542ace85ed5f88549e2d0ea82210f8ddc87e0defbb78469d3aed719b3c964'

  url TestHelper.local_binary_url('container.7z')
  homepage 'https://example.com/container-7z'

  depends_on formula: 'unar'

  app 'container'
end
