module RuboCop
  module AST
    # Extensions for RuboCop's AST Node class
    class Node
      include RuboCop::Cask::Constants

      def_node_matcher :method_node, "{$(send ...) (block $(send ...) ...)}"
      def_node_matcher :block_args,  "(block _ $_ _)"
      def_node_matcher :block_body,  "(block _ _ $_)"

      def_node_matcher :key_node,    "{(pair $_ _) (hash (pair $_ _) ...)}"
      def_node_matcher :val_node,    "{(pair _ $_) (hash (pair _ $_) ...)}"

      def_node_matcher :cask_block?, "(block (send nil? :cask _) args ...)"

      def stanza?
        (send_type? || block_type?) && STANZA_ORDER.include?(method_name)
      end

      def heredoc?
        loc.is_a?(Parser::Source::Map::Heredoc)
      end

      def expression
        base_expression = loc.expression
        descendants.select(&:heredoc?).reduce(base_expression) do |expr, node|
          expr.join(node.loc.heredoc_end)
        end
      end
    end
  end
end
