require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop checks for and audits legacy patches in Formulae
      class LegacyPatches < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body)
          patches_node = find_method_def(body, :patches)
          return if patches_node.nil?
          legacy_patches = find_strings(patches_node)
          problem "Use the patch DSL instead of defining a 'patches' method"
          legacy_patches.each { |p| patch_problems(p) }
        end

        def patch_problems(patch)
          patch_url = string_content(patch)
          gh_patch_patterns = Regexp.union([%r{/raw\.github\.com/},
                                            %r{gist\.github\.com/raw},
                                            %r{gist\.github\.com/.+/raw},
                                            %r{gist\.githubusercontent\.com/.+/raw}])
          if regex_match_group(patch, gh_patch_patterns)
            unless patch_url =~ /[a-fA-F0-9]{40}/
              problem "GitHub/Gist patches should specify a revision:\n#{patch_url}"
            end
          end

          gh_patch_diff_pattern = %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          if match_obj = regex_match_group(patch, gh_patch_diff_pattern)
            problem <<-EOS.undent
              use GitHub pull request URLs:
                https://github.com/#{match_obj[1]}/#{match_obj[2]}/pull/#{match_ojb[3]}.patch
              Rather than patch-diff:
                #{patch_url}
            EOS
          end

          if regex_match_group(patch, %r{macports/trunk})
            problem "MacPorts patches should specify a revision instead of trunk:\n#{patch_url}"
          end

          if regex_match_group(patch, %r{^http://trac\.macports\.org})
            problem "Patches from MacPorts Trac should be https://, not http:\n#{patch_url}"
          end

          return unless regex_match_group(patch, %r{^http://bugs\.debian\.org})
          problem "Patches from Debian should be https://, not http:\n#{patch_url}"
        end
      end
    end
  end
end
