require_relative "./extend/formula_cop"

module RuboCop
  module Cop
    module FormulaAudit
      class Checksum < FormulaCop
        def audit_formula(_node, _class_node, _parent_class_node, body_node)
          return if body_node.nil?
          if method_called_ever?(body_node, :md5)
            problem "MD5 checksums are deprecated, please use SHA256"
          end

          if method_called_ever?(body_node, :sha1)
            problem "SHA1 checksums are deprecated, please use SHA256"
          end

          sha256_calls = find_every_method_call_by_name(body_node, :sha256)
          sha256_calls.each do |sha256_call|
            sha256_node = get_checksum_node(sha256_call)
            audit_sha256(sha256_node)
          end
        end

        def get_checksum_node(call)
          return if parameters(call).empty? || parameters(call).nil?
          if parameters(call).first.str_type?
            parameters(call).first
          elsif parameters(call).first.hash_type?
            parameters(call).first.keys.first
          end
        end

        def audit_sha256(checksum)
          return if checksum.nil?
          if regex_match_group(checksum, /^$/)
            problem "sha256 is empty"
            return
          end

          if string_content(checksum).size != 64 && regex_match_group(checksum, /^\w*$/)
            problem "sha256 should be 64 characters"
          end

          if regex_match_group(checksum, /[^a-f0-9]+/i)
            problem "sha256 contains invalid characters"
          end

          return unless regex_match_group(checksum, /[A-F]+/)
          problem "sha256 should be lowercase"
        end
      end
    end
  end
end
