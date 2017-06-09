require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      class Checksum < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          %w[Stable Devel HEAD].each do |name|
            next unless spec_node = find_block(body_node, name.downcase.to_sym)
            _, _, spec_body = *spec_node
            audit_checksums(spec_body, name)
            resource_blocks = find_all_blocks(spec_body, :resource)
            resource_blocks.each do |rb|
              _, _, resource_body = *rb
              audit_checksums(resource_body, name, string_content(parameters(rb).first))
            end
          end
        end

        def audit_checksums(node, spec, resource_name = nil)
          msg_prefix = if resource_name
            "#{spec} resource \"#{resource_name}\": "
          else
            "#{spec}: "
          end
          if find_node_method_by_name(node, :md5)
            problem "#{msg_prefix}MD5 checksums are deprecated, please use SHA256"
          end

          if find_node_method_by_name(node, :sha1)
            problem "#{msg_prefix}SHA1 checksums are deprecated, please use SHA256"
          end

          checksum_node = find_node_method_by_name(node, :sha256)
          checksum = parameters(checksum_node).first
          if string_content(checksum).size.zero?
            problem "#{msg_prefix}sha256 is empty"
            return
          end

          if string_content(checksum).size != 64 && regex_match_group(checksum, /^\w*$/)
            problem "#{msg_prefix}sha256 should be 64 characters"
          end

          unless regex_match_group(checksum, /^[a-f0-9]+$/i)
            problem "#{msg_prefix}sha256 contains invalid characters"
          end

          return unless regex_match_group(checksum, /^[a-f0-9]+$/)
          problem "#{msg_prefix}sha256 should be lowercase"
        end
      end
    end
  end
end
