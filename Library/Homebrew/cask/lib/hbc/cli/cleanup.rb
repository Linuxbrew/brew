module Hbc
  class CLI
    class Cleanup < AbstractCommand
      OUTDATED_DAYS = 10
      OUTDATED_TIMESTAMP = Time.now - (60 * 60 * 24 * OUTDATED_DAYS)

      def self.help
        "cleans up cached downloads and tracker symlinks"
      end

      def self.needs_init?
        true
      end

      attr_reader :cache_location

      def initialize(*args, cache_location: Hbc.cache)
        super(*args)
        @cache_location = Pathname.new(cache_location)
      end

      def run
        remove_cache_files(*args)
      end

      def cache_files
        return [] unless cache_location.exist?
        cache_location.children
                      .map(&method(:Pathname))
                      .reject(&method(:outdated?))
      end

      def outdated?(file)
        outdated_only? && file && file.stat.mtime > OUTDATED_TIMESTAMP
      end

      def incomplete?(file)
        file.extname == ".incomplete"
      end

      def cache_incompletes
        cache_files.select(&method(:incomplete?))
      end

      def cache_completes
        cache_files.reject(&method(:incomplete?))
      end

      def disk_cleanup_size
        cache_files.map(&:disk_usage).inject(:+)
      end

      def remove_cache_files(*tokens)
        message = "Removing cached downloads"
        message.concat " for #{tokens.join(", ")}" unless tokens.empty?
        message.concat " older than #{OUTDATED_DAYS} days old" if outdated_only?
        ohai message

        deletable_cache_files = if tokens.empty?
          cache_files
        else
          start_withs = tokens.map { |token| "#{token}--" }

          cache_files.select do |path|
            path.basename.to_s.start_with?(*start_withs)
          end
        end

        delete_paths(deletable_cache_files)
      end

      def delete_paths(paths)
        cleanup_size = 0
        processed_files = 0
        paths.each do |item|
          next unless item.exist?
          processed_files += 1

          begin
            LockFile.new(item.basename).with_lock do
              puts item
              cleanup_size += File.size(item)
              item.rmtree
            end
          rescue OperationInProgressError
            puts "skipping: #{item} is locked"
            next
          end
        end

        if processed_files.zero?
          puts "Nothing to do"
        else
          disk_space = disk_usage_readable(cleanup_size)
          ohai "This operation has freed approximately #{disk_space} of disk space."
        end
      end
    end
  end
end
