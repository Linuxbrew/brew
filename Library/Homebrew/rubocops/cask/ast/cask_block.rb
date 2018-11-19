require "forwardable"

module RuboCop
  module Cask
    module AST
      # This class wraps the AST block node that represents the entire cask
      # definition. It includes various helper methods to aid cops in their
      # analysis.
      class CaskBlock
        extend Forwardable

        def initialize(block_node, comments)
          @block_node = block_node
          @comments = comments
        end

        attr_reader :block_node, :comments

        alias cask_node block_node

        def_delegator :cask_node, :block_body, :cask_body

        def header
          @header ||= CaskHeader.new(cask_node.method_node)
        end

        def stanzas
          return [] unless cask_body

          @stanzas ||= cask_body.each_node
                                .select(&:stanza?)
                                .map { |node| Stanza.new(node, stanza_comments(node)) }
        end

        def toplevel_stanzas
          @toplevel_stanzas ||= stanzas.select(&:toplevel_stanza?)
        end

        def sorted_toplevel_stanzas
          @sorted_toplevel_stanzas ||= sort_stanzas(toplevel_stanzas)
        end

        private

        def sort_stanzas(stanzas)
          stanzas.sort do |s1, s2|
            i1 = stanza_order_index(s1)
            i2 = stanza_order_index(s2)
            if i1 == i2
              i1 = stanzas.index(s1)
              i2 = stanzas.index(s2)
            end
            i1 - i2
          end
        end

        def stanza_order_index(stanza)
          Constants::STANZA_ORDER.index(stanza.stanza_name)
        end

        def stanza_comments(stanza_node)
          stanza_node.each_node.reduce([]) do |comments, node|
            comments | comments_hash[node.loc]
          end
        end

        def comments_hash
          @comments_hash ||= Parser::Source::Comment
                             .associate_locations(cask_node, comments)
        end
      end
    end
  end
end
