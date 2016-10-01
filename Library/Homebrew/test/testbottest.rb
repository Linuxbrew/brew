class Testbottest < Formula
  desc "Minimal C program and Makefile used for testing Homebrew."
  homepage "https://github.com/Homebrew/brew"
  url "file://#{File.expand_path("..", __FILE__)}/tarballs/testbottest-0.1.tbz"
  sha256 "78b54d8f31585c9773bed12b4aa4ab2ce458ebd044b9406cb24d40aa5107f082"

  def install
    system "make", "install", "PREFIX=#{prefix}"
  end

  test do
    assert_equal "testbottest\n", shell_output("#{bin}/testbottest")
  end
end
