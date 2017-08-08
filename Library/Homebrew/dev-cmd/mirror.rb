#: @hide_from_man_page
#:  * `mirror` [`--test`] <formulae>:
#:    Reuploads the stable URL for a formula to Bintray to use it as a mirror.

module Homebrew
  module_function

  def mirror
    odie "This command requires at least formula argument!" if ARGV.named.empty?

    bintray_user = ENV["HOMEBREW_BINTRAY_USER"]
    bintray_key = ENV["HOMEBREW_BINTRAY_KEY"]
    if !bintray_user || !bintray_key
      raise "Missing HOMEBREW_BINTRAY_USER or HOMEBREW_BINTRAY_KEY variables!"
    end

    ARGV.formulae.each do |f|
      bintray_package = Utils::Bottles::Bintray.package f.name
      bintray_repo_url = "https://api.bintray.com/packages/homebrew/mirror"
      package_url = "#{bintray_repo_url}/#{bintray_package}"

      unless system "curl", "--silent", "--fail", "--output", "/dev/null", package_url
        package_blob = <<-EOS.undent
          {"name": "#{bintray_package}",
           "public_download_numbers": true,
           "public_stats": true}
        EOS
        curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
             "--header", "Content-Type: application/json",
             "--data", package_blob, bintray_repo_url
        puts
      end

      download = f.fetch
      f.verify_download_integrity(download)
      filename = download.basename
      destination_url = "https://dl.bintray.com/homebrew/mirror/#{filename}"

      ohai "Uploading to #{destination_url}"
      content_url = "https://api.bintray.com/content/homebrew/mirror"
      content_url += "/#{bintray_package}/#{f.pkg_version}/#{filename}"
      content_url += "?publish=1"
      curl "--silent", "--fail", "--user", "#{bintray_user}:#{bintray_key}",
           "--upload-file", download, content_url
      puts
      ohai "Mirrored #{filename}!"
    end
  end
end
