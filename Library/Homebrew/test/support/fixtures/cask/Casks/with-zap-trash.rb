cask 'with-zap-trash' do
  version '1.2.3'
  sha256 '8c62a2b791cf5f0da6066a0a4b6e85f62949cd60975da062df44adf887f4370b'

  url "file://#{TEST_FIXTURE_DIR}/cask/MyFancyPkg.zip"
  homepage 'https://brew.sh/fancy-pkg'

  pkg 'Fancy.pkg'

  zap trash: [
               "#{TEST_TMPDIR}/absolute_path",
               '~/path_with_tilde',
               "#{TEST_TMPDIR}/glob_path*",
               'impermissible/relative/path',
               '/another/impermissible/../relative/path',
             ]
end
