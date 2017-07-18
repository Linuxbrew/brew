require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits urls and mirrors in Formulae
      class Urls < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          urls = find_every_method_call_by_name(body_node, :url)
          mirrors = find_every_method_call_by_name(body_node, :mirror)

          # GNU urls; doesn't apply to mirrors
          gnu_pattern = %r{^(?:https?|ftp)://ftpmirror.gnu.org/(.*)}
          audit_urls(urls, gnu_pattern) do |match, url|
            problem "Please use \"https://ftp.gnu.org/gnu/#{match[1]}\" instead of #{url}."
          end

          # Fossies upstream requests they aren't used as primary URLs
          # https://github.com/Homebrew/homebrew-core/issues/14486#issuecomment-307753234
          fossies_pattern = %r{^https?://fossies\.org/}
          audit_urls(urls, fossies_pattern) do
            problem "Please don't use fossies.org in the url (using as a mirror is fine)"
          end

          audit_urls(mirrors, /.*/) do |_, mirror|
            urls.each do |url|
              url_string = string_content(parameters(url).first)
              next unless url_string.eql?(mirror)
              problem "URL should not be duplicated as a mirror: #{url_string}"
            end
          end

          urls += mirrors

          # Check a variety of SSL/TLS URLs that don't consistently auto-redirect
          # or are overly common errors that need to be reduced & fixed over time.
          http_to_https_patterns = Regexp.union([%r{^http://ftp\.gnu\.org/},
                                                 %r{^http://ftpmirror\.gnu\.org/},
                                                 %r{^http://download\.savannah\.gnu\.org/},
                                                 %r{^http://download-mirror\.savannah\.gnu\.org/},
                                                 %r{^http://[^/]*\.apache\.org/},
                                                 %r{^http://code\.google\.com/},
                                                 %r{^http://fossies\.org/},
                                                 %r{^http://mirrors\.kernel\.org/},
                                                 %r{^http://(?:[^/]*\.)?bintray\.com/},
                                                 %r{^http://tools\.ietf\.org/},
                                                 %r{^http://launchpad\.net/},
                                                 %r{^http://github\.com/},
                                                 %r{^http://bitbucket\.org/},
                                                 %r{^http://anonscm\.debian\.org/},
                                                 %r{^http://cpan\.metacpan\.org/},
                                                 %r{^http://hackage\.haskell\.org/},
                                                 %r{^http://(?:[^/]*\.)?archive\.org},
                                                 %r{^http://(?:[^/]*\.)?freedesktop\.org},
                                                 %r{^http://(?:[^/]*\.)?mirrorservice\.org/}])
          audit_urls(urls, http_to_https_patterns) do |_, url|
            problem "Please use https:// for #{url}"
          end

          cpan_pattern = %r{^http://search\.mcpan\.org/CPAN/(.*)}i
          audit_urls(urls, cpan_pattern) do |match, url|
            problem "#{url} should be `https://cpan.metacpan.org/#{match[1]}`"
          end

          gnome_pattern = %r{^(http|ftp)://ftp\.gnome\.org/pub/gnome/(.*)}i
          audit_urls(urls, gnome_pattern) do |match, url|
            problem "#{url} should be `https://download.gnome.org/#{match[2]}`"
          end

          debian_pattern = %r{^git://anonscm\.debian\.org/users/(.*)}i
          audit_urls(urls, debian_pattern) do |match, url|
            problem "#{url} should be `https://anonscm.debian.org/git/users/#{match[1]}`"
          end
        end

        private

        def audit_urls(urls, regex)
          urls.each do |url_node|
            url_string_node = parameters(url_node).first
            url_string = string_content(url_string_node)
            match_object = regex_match_group(url_string_node, regex)
            offending_node(url_string_node.parent) if match_object
            yield match_object, url_string if match_object
          end
        end
      end
    end
  end
end
