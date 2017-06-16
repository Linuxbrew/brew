require "open3"

describe "trash", :needs_macos do
  let(:executable) { HOMEBREW_LIBRARY_PATH/"utils/trash.swift" }
  let(:dir) { mktmpdir }
  let(:file) { dir/"new_file" }

  it "moves existing files to the trash" do
    FileUtils.touch file

    expect(file).to exist

    out, err, status = Open3.capture3(executable, file)

    expect(out).to match %r{moved #{file} to .*/\.Trash/\.*}
    expect(err).to be_empty
    expect(status).to be_a_success

    expect(file).not_to exist

    trashed_path = out.sub(/^moved #{Regexp.escape(file.to_s)} to (.*)\n$/, '\1')
    FileUtils.rm_f trashed_path
  end

  it "fails when files don't exist" do
    out, err, status = Open3.capture3(executable, file)

    expect(out).to be_empty
    expect(err).to eq "could not move #{file} to trash\n"
    expect(status).to be_a_failure
  end
end
