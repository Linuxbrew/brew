require_relative "./extend/formula_cop"
require_relative "../extend/string"

module RuboCop
  module Cop
    module FormulaAudit
      # This cop audits patches in Formulae
      class Patches < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body)
          external_patches = find_all_blocks(body, :patch)
          external_patches.each do |patch_block|
            url_node = find_every_method_call_by_name(patch_block, :url).first
            url_string = parameters(url_node).first
            patch_problems(url_string)
          end

          patches_node = find_method_def(body, :patches)
          return if patches_node.nil?
          legacy_patches = find_strings(patches_node)
          problem "Use the patch DSL instead of defining a 'patches' method"
          legacy_patches.each { |p| patch_problems(p) }
        end

        private

        def patch_problems(patch)
          patch_url = string_content(patch)
          gh_patch_param_pattern = %r{https?://github\.com/.+/.+/(?:commit|pull)/[a-fA-F0-9]*.(?:patch|diff)}
          if regex_match_group(patch, gh_patch_param_pattern)
            if patch_url !~ /\?full_index=\w+$/
              problem <<-EOS.undent
                GitHub patches should use the full_index parameter:
                  #{patch_url}?full_index=1
              EOS
            end
          end

          gh_patch_patterns = Regexp.union([%r{/raw\.github\.com/},
                                            %r{gist\.github\.com/raw},
                                            %r{gist\.github\.com/.+/raw},
                                            %r{gist\.githubusercontent\.com/.+/raw}])
          if regex_match_group(patch, gh_patch_patterns)
            if patch_url !~ /[a-fA-F0-9]{40}/
              problem <<-EOS.undent.chomp
                GitHub/Gist patches should specify a revision:
                #{patch_url}
              EOS
            end
          end

          gh_patch_diff_pattern = %r{https?://patch-diff\.githubusercontent\.com/raw/(.+)/(.+)/pull/(.+)\.(?:diff|patch)}
          if match_obj = regex_match_group(patch, gh_patch_diff_pattern)
            problem <<-EOS.undent
              use GitHub pull request URLs:
                https://github.com/#{match_obj[1]}/#{match_obj[2]}/pull/#{match_obj[3]}.patch
              Rather than patch-diff:
                #{patch_url}
            EOS
          end

          if regex_match_group(patch, %r{macports/trunk})
            problem <<-EOS.undent.chomp
              MacPorts patches should specify a revision instead of trunk:
              #{patch_url}
            EOS
          end

          if regex_match_group(patch, %r{^http://trac\.macports\.org})
            problem <<-EOS.undent.chomp
              Patches from MacPorts Trac should be https://, not http:
              #{patch_url}
            EOS
          end

          return unless regex_match_group(patch, %r{^http://bugs\.debian\.org})
          problem <<-EOS.undent.chomp
            Patches from Debian should be https://, not http:
            #{patch_url}
          EOS
        end
      end
    end
  end
end
