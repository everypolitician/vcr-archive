require 'vcr'

require 'vcr/archive/version'

module VCR
  module Archive
    class YamlSeparateHtmlSerializer
      def self.file_extension
        'git'
      end

      def self.serialize(hash)
        hash
      end

      def self.deserialize(hash)
        hash
      end
    end

    class GitRepository
      attr_reader :url, :directory

      def initialize(git_repository_url)
        @url = git_repository_url
        @directory = Dir.mktmpdir
        clone_repo_if_missing!
        Dir.chdir(directory)
        create_or_checkout_archive_branch!
      end

      def clone_repo_if_missing!
        return if File.directory?(File.join(directory, '.git'))
        system("git clone #{url} #{directory}")
      end

      def create_or_checkout_archive_branch!
        if system("git rev-parse --verify origin/#{branch_name} > /dev/null 2>&1")
          system("git checkout --quiet #{branch_name}")
        else
          system("git checkout --orphan #{branch_name}")
          system("git rm --quiet -rf .")
        end
      end

      # TODO: This should be configurable
      def branch_name
        @branch_name ||= 'scraped-pages-archive'
      end
    end

    module YamlSeparateHtmlPersister
      extend self

      def [](git_repository)
        # VCR adds the extension from the serializer, so we need to remove it.
        repo = GitRepository.new(git_repository.sub!(/\.git$/, ''))
        files = Dir.glob("#{repo.directory}/**/*.yml")
        return nil if files.empty?
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

      def []=(git_repository, meta)
        # VCR adds the extension from the serializer, so we need to remove it.
        repo = GitRepository.new(git_repository.sub!(/\.git$/, ''))
        meta['http_interactions'].each do |interaction|
          uri = URI.parse(interaction['request']['uri'])
          path = File.join(repo.directory, uri.host, Digest::SHA1.hexdigest(uri.to_s))
          directory = File.dirname(path)
          FileUtils.mkdir_p(directory) unless File.exist?(directory)
          body = interaction['response']['body'].delete('string')
          File.binwrite("#{path}.yml", YAML.dump(interaction))
          File.binwrite("#{path}.html", body)
          message = "#{interaction['response']['status'].values_at('code', 'message').join(' ')} #{interaction['request']['uri']}"
          system("git add .")
          system("git commit --allow-empty --message='#{message}'")
          # TODO: Use VCR hooks to run this when the cassette is ejected.
        end
        system("git push --quiet origin #{repo.branch_name}")
      end

      def absolute_path_to_file(storage_key)
        storage_key
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
