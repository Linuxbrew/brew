module RuboCop
  module RSpec
    # Helps determine the offending location if there is not a blank line
    # following the node. Allows comments to follow directly after.
    module BlankLineSeparation
      include FinalEndLocation
      include RuboCop::Cop::RangeHelp

      def missing_separating_line(node)
        line = final_end_location(node).line

        line += 1 while comment_line?(processed_source[line])

        return if processed_source[line].blank?

        yield offending_loc(line)
      end

      def offending_loc(last_line)
        offending_line = processed_source[last_line - 1]

        content_length = offending_line.lstrip.length
        start          = offending_line.length - content_length

        source_range(processed_source.buffer, last_line, start, content_length)
      end

      def last_child?(node)
        return true unless node.parent && node.parent.begin_type?

        node.equal?(node.parent.children.last)
      end

      def autocorrect(node)
        lambda do |corrector|
          missing_separating_line(node) do |location|
            corrector.insert_after(location.end, "\n")
          end
        end
      end
    end
  end
end
