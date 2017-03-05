describe Hbc::Artifact::App, :cask do
  # FIXME: Doesn't actually raise because the `app` stanza is not evaluated on load.
  # it "must raise" do
  #   lambda {
  #     Hbc::CaskLoader.load_from_file(TEST_FIXTURE_DIR/"cask/Casks/with-two-apps-incorrect.rb")
  #   }.must_raise
  #   # TODO: later give the user a nice exception for this case and check for it here
  # end
end
