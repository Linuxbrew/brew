require "forwardable"

module RuboCop
  module Cask
    module AST
      # This class wraps the AST send/block node that encapsulates the method
      # call that comprises the stanza. It includes various helper methods to
      # aid cops in their analysis.
      class Stanza
        extend Forwardable

        def initialize(method_node, comments)
          @method_node = method_node
          @comments = comments
        end

        attr_reader :method_node, :comments

        alias stanza_node method_node

        def_delegator :stanza_node, :method_name, :stanza_name
        def_delegator :stanza_node, :parent, :parent_node

        def source_range
          stanza_node.expression
        end

        def source_range_with_comments
          comments.reduce(source_range) do |range, comment|
            range.join(comment.loc.expression)
          end
        end

        def_delegator :source_range, :source
        def_delegator :source_range_with_comments, :source,
                      :source_with_comments

        def stanza_group
          Constants::STANZA_GROUP_HASH[stanza_name]
        end

        def same_group?(other)
          stanza_group == other.stanza_group
        end

        def toplevel_stanza?
          parent_node.cask_block? || parent_node.parent.cask_block?
        end

        def ==(other)
          self.class == other.class && stanza_node == other.stanza_node
        end

        alias eql? ==

        Constants::STANZA_ORDER.each do |stanza_name|
          class_eval <<-RUBY, __FILE__, __LINE__ + 1
            def #{stanza_name}?
              stanza_name == :#{stanza_name}
            end
          RUBY
        end
      end
    end
  end
end
