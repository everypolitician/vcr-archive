require 'vcr'

require 'vcr/archive/version'

module VCR
  module Archive

    extend self

    attr_accessor :git_repository_url

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

      def [](_)
        nil
      end

      def []=(_, _)
        nil
      end

      def absolute_path_to_file(storage_key)
        storage_key
      end
    end

    module GitRepository
      extend self

      def tmpdir
        @tmpdir ||= Dir.mktmpdir
      end

      def directory
        @directory ||= File.join(tmpdir, git_repository_url.split('/').last)
      end

      def git_repository_url
        VCR::Archive.git_repository_url
      end

      def branch_name
        @branch_name ||= 'scraped-pages-archive'
      end

      def commit_all(message, &block)
        unless File.directory?(File.join(directory, '.git'))
          system("git clone --quiet #{git_repository_url} #{directory}")
        end
        Dir.chdir(directory) do
          if system("git rev-parse --verify origin/#{branch_name} > /dev/null 2>&1")
            system("git checkout --quiet #{branch_name}")
          else
            system("git checkout --orphan #{branch_name}")
            system("git rm --quiet -rf .")
          end

          yield(directory)

          system("git add .")
          system("git commit --quiet --allow-empty --message='#{message}'")
          system("git push --quiet origin #{branch_name}")
        end
      end
    end

    VCR.configure do |config|
      config.hook_into :webmock
      config.cassette_serializers[:vcr_archive] = Serializer
      config.cassette_persisters[:vcr_archive] = Persister
      config.default_cassette_options = { serialize_with: :vcr_archive, persist_with: :vcr_archive, record: :all }
      config.before_record do |interaction, cassette|
        uri = URI.parse(interaction.request.uri)
        message = "#{interaction.response.status.to_hash.values_at('code', 'message').join(' ')} #{uri}"
        GitRepository.commit_all(message) do |directory|
          path = File.join(directory, uri.host, Digest::SHA1.hexdigest(uri.to_s))
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless File.exist?(directory)
          meta = interaction.to_hash
          body = meta['response']['body'].delete('string')
          File.binwrite("#{path}.yml", YAML.dump(meta))
          File.binwrite("#{path}.html", body)
        end
      end
    end
  end
end
