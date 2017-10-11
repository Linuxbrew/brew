describe Hbc::Artifact::App, :cask do
  # FIXME: Doesn't actually raise because the `app` stanza is not evaluated on load.
  # it "must raise" do
  #   lambda {
  #     Hbc::CaskLoader.load(cask_path("with-two-apps-incorrect"))
  #   }.must_raise
  #   # TODO: later give the user a nice exception for this case and check for it here
  # end
end
