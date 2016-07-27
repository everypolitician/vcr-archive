require 'yaml'

require 'vcr/archive/version'

module VCR
  module Archive
    module Serializer
      extend self

      def file_extension
        'archive'
      end

      def serialize(hash)
        hash
      end

      def deserialize(hash)
        hash
      end
    end

    module Persister
      extend self

      attr_reader :storage_location

      def storage_location=(dir)
        FileUtils.mkdir_p(dir) if dir
        @storage_location = dir ? absolute_path_for(dir) : nil
      end

      def [](file_name)
        path = absolute_path_to_file(file_name)
        files = Dir.glob("#{path}/**/*.yml")
        return nil unless files.any?
        interactions = files.map do |f|
          meta = YAML.load_file(f)
          body = File.binread(f.sub(/\.yml$/, '.html'))
          meta['response']['body']['string'] = body
          meta
        end
        {
          'http_interactions' => interactions,
        }
      end

      def []=(file_name, meta)
        path = absolute_path_to_file(file_name)
        meta['http_interactions'].each do |interaction|
          uri = URI.parse(interaction['request']['uri'])
          path = File.join(path, uri.host, Digest::SHA1.hexdigest(uri.to_s))
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless File.exist?(directory)
          body = interaction['response']['body'].delete('string')
          File.binwrite("#{path}.yml", YAML.dump(interaction))
          File.binwrite("#{path}.html", body)
        end
      end

      def absolute_path_to_file(file_name)
        return nil unless storage_location
        File.join(storage_location, sanitized_file_name_from(file_name))
      end

      private

      def absolute_path_for(path)
        Dir.chdir(path) { Dir.pwd }
      end

      def sanitized_file_name_from(file_name)
        parts = file_name.to_s.split('.')

        # Get rid of the unneeded extension on the file_name
        if parts.size > 1 && !parts.last.include?(File::SEPARATOR)
          parts.pop
        end

        parts.join('.').gsub(/[^\w\-\/]+/, '_')
      end
    end
  end
end
