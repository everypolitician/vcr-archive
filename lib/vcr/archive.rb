require 'vcr'

require 'vcr/archive/version'

module VCR
  module Archive
    class YamlSeparateHtmlSerializer
      def self.file_extension
        'archive'
      end

      def self.serialize(hash)
        hash
      end

      def self.deserialize(hash)
        hash
      end
    end

    class YamlSeparateHtmlPersister
      def self.[](interactions_directory)
        interactions_directory.sub!(/\.archive$/, '')
        return nil unless File.directory?(interactions_directory)
        files = Dir.glob("#{interactions_directory}/**/*.yml")
        return nil unless files.any?
        interactions = files.map do |f|
          meta = YAML.load_file(f)
          body = File.binread(f.sub(/\.yml$/, '.html'))
          meta['response']['body']['string'] = body
          meta
        end
        {
          'http_interactions' => interactions,
          'recorded_with' => File.binread(File.join(interactions_directory, 'recorded_with.txt')),
        }
      end

      def self.[]=(interactions_directory, meta)
        interactions_directory.sub!(/\.archive$/, '')
        meta['http_interactions'].each do |interaction|
          uri = URI.parse(interaction['request']['uri'])
          path = File.join(interactions_directory, uri.host, Digest::SHA1.hexdigest(uri.to_s))
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless File.exist?(directory)
          body = interaction['response']['body'].delete('string')
          File.binwrite("#{path}.yml", YAML.dump(interaction))
          File.binwrite("#{path}.html", body)
        end
        File.binwrite(File.join(interactions_directory, 'recorded_with.txt'), meta['recorded_with'])
      end
    end

    VCR.configure do |config|
      config.hook_into :webmock
      config.cassette_serializers[:yaml_separate_html] = YamlSeparateHtmlSerializer
      config.cassette_persisters[:yaml_separate_html] = YamlSeparateHtmlPersister
      config.default_cassette_options = { serialize_with: :yaml_separate_html, persist_with: :yaml_separate_html }
    end
  end
end
