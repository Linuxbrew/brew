require "rubocops/extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits `homepage` url in Formulae
      class Homepage < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          homepage_node = find_node_method_by_name(body_node, :homepage)
          homepage = if homepage_node
            string_content(parameters(homepage_node).first)
          else
            ""
          end

          problem "Formula should have a homepage." if homepage_node.nil? || homepage.empty?

          unless homepage =~ %r{^https?://}
            problem "The homepage should start with http or https (URL is #{homepage})."
          end

          case homepage
          # Check for http:// GitHub homepage urls, https:// is preferred.
          # Note: only check homepages that are repo pages, not *.github.com hosts
          when %r{^http://github.com/}
            problem "Please use https:// for #{homepage}"

          # Savannah has full SSL/TLS support but no auto-redirect.
          # Doesn't apply to the download URLs, only the homepage.
          when %r{^http://savannah.nongnu.org/}
            problem "Please use https:// for #{homepage}"

          # Freedesktop is complicated to handle - It has SSL/TLS, but only on certain subdomains.
          # To enable https Freedesktop change the URL from http://project.freedesktop.org/wiki to
          # https://wiki.freedesktop.org/project_name.
          # "Software" is redirected to https://wiki.freedesktop.org/www/Software/project_name
          when %r{^http://((?:www|nice|libopenraw|liboil|telepathy|xorg)\.)?freedesktop\.org/(?:wiki/)?}
            if homepage =~ /Software/
              problem "#{homepage} should be styled `https://wiki.freedesktop.org/www/Software/project_name`"
            else
              problem "#{homepage} should be styled `https://wiki.freedesktop.org/project_name`"
            end

          # Google Code homepages should end in a slash
          when %r{^https?://code\.google\.com/p/[^/]+[^/]$}
            problem "#{homepage} should end with a slash"

          # People will run into mixed content sometimes, but we should enforce and then add
          # exemptions as they are discovered. Treat mixed content on homepages as a bug.
          # Justify each exemptions with a code comment so we can keep track here.

          when %r{^http://[^/]*\.github\.io/},
               %r{^http://[^/]*\.sourceforge\.io/}
            problem "Please use https:// for #{homepage}"

          when %r{^http://([^/]*)\.(sf|sourceforge)\.net(/|$)}
            problem "#{homepage} should be `https://#{Regexp.last_match(1)}.sourceforge.io/`"

          # There's an auto-redirect here, but this mistake is incredibly common too.
          # Only applies to the homepage and subdomains for now, not the FTP URLs.
          when %r{^http://((?:build|cloud|developer|download|extensions|git|
                              glade|help|library|live|nagios|news|people|
                              projects|rt|static|wiki|www)\.)?gnome\.org}x
            problem "Please use https:// for #{homepage}"

          # Compact the above into this list as we're able to remove detailed notations, etc over time.
          when %r{^http://[^/]*\.apache\.org},
               %r{^http://packages\.debian\.org},
               %r{^http://wiki\.freedesktop\.org/},
               %r{^http://((?:www)\.)?gnupg\.org/},
               %r{^http://ietf\.org},
               %r{^http://[^/.]+\.ietf\.org},
               %r{^http://[^/.]+\.tools\.ietf\.org},
               %r{^http://www\.gnu\.org/},
               %r{^http://code\.google\.com/},
               %r{^http://bitbucket\.org/},
               %r{^http://(?:[^/]*\.)?archive\.org}
            problem "Please use https:// for #{homepage}"
          end
        end
      end
    end
  end
end
