#: @hide_from_man_page
#:  * `mirror` <formulae>:
#:    Reuploads the stable URL for a formula to Bintray to use it as a mirror.

require "cli_parser"

module Homebrew
  module_function

  def mirror_args
    Homebrew::CLI::Parser.new do
      usage_banner <<~EOS
        `mirror` <formulae>

        Reuploads the stable URL for a formula to Bintray to use it as a mirror.
      EOS
      switch :verbose
      switch :debug
    end
  end

  def mirror
    mirror_args.parse

    odie "This command requires at least one formula argument!" if ARGV.named.empty?

    bintray_user = ENV["HOMEBREW_BINTRAY_USER"]
    bintray_key = ENV["HOMEBREW_BINTRAY_KEY"]
    if !bintray_user || !bintray_key
      raise "Missing HOMEBREW_BINTRAY_USER or HOMEBREW_BINTRAY_KEY variables!"
    end

    ARGV.formulae.each do |f|
      bintray_package = Utils::Bottles::Bintray.package f.name
      bintray_repo_url = "https://api.bintray.com/packages/homebrew/mirror"
      package_url = "#{bintray_repo_url}/#{bintray_package}"

      unless system curl_executable, "--silent", "--fail", "--output", "/dev/null", package_url
        package_blob = <<~JSON
          {"name": "#{bintray_package}",
           "public_download_numbers": true,
           "public_stats": true}
        JSON
        curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
             "--header", "Content-Type: application/json",
             "--data", package_blob, bintray_repo_url
        puts
      end

      downloader = f.downloader

      downloader.fetch
      f.verify_download_integrity(downloader.cached_location)

      filename = downloader.basename

      destination_url = "https://dl.bintray.com/homebrew/mirror/#{filename}"
      ohai "Uploading to #{destination_url}"

      content_url =
        "https://api.bintray.com/content/homebrew/mirror/#{bintray_package}/#{f.pkg_version}/#{filename}?publish=1"
      curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
           "--upload-file", downloader.cached_location, content_url
      puts
      ohai "Mirrored #{filename}!"
    end
  end
end
