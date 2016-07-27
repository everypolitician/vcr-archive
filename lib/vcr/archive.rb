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

    module YamlSeparateHtmlPersister
      extend self

      def [](git_repository)
        puts "Read from persister"
        # VCR adds the extension from the serializer, so we need to remove it.
        git_repository.sub!(/\.archive$/, '')
        clone_repo_if_missing!(git_repository)
        Dir.chdir(git_repository)
        create_or_checkout_archive_branch!
        return nil unless File.directory?(git_repository)
        files = Dir.glob("#{git_repository}/**/*.yml")
        return nil if files.empty?
        interactions = files.map do |f|
          meta = YAML.load_file(f)
          body = File.binread(f.sub(/\.yml$/, '.html'))
          meta['response']['body']['string'] = body
          meta
        end
        {
          'http_interactions' => interactions,
          'recorded_with' => File.binread(File.join(git_repository, 'recorded_with.txt')),
        }
      end

      def []=(git_repository, meta)
        # VCR adds the extension from the serializer, so we need to remove it.
        git_repository.sub!(/\.archive$/, '')
        clone_repo_if_missing!(git_repository)
        Dir.chdir(git_repository)
        create_or_checkout_archive_branch!
        meta['http_interactions'].each do |interaction|
          uri = URI.parse(interaction['request']['uri'])
          path = File.join(git_repository, uri.host, Digest::SHA1.hexdigest(uri.to_s))
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
        File.binwrite(File.join(git_repository, 'recorded_with.txt'), meta['recorded_with'])
        system("git add .")
        unless system("git diff --exit-code")
          system("git commit --message='#{message}'")
        end
        system("git push --quiet origin #{branch_name}")
      end

      def absolute_path_to_file(storage_key)
        storage_key
      end

      def clone_repo_if_missing!(git_repository)
        if github_repo_url.nil?
          warn "Could not determine git repo for 'scraped_page_archive' to use.\n\n" \
            "See https://github.com/everypolitician/scraped_page_archive#usage for details."
          return
        end
        unless File.directory?(git_repository)
          warn "Cloning archive repo into #{git_repository}"
          system("git clone #{git_url} #{git_repository}")
        end
      end

      def create_or_checkout_archive_branch!
        if system("git rev-parse --verify origin/#{branch_name} > /dev/null 2>&1")
          system("git checkout --quiet #{branch_name}")
        else
          system("git checkout --orphan #{branch_name}")
          system("git rm --quiet -rf .")
        end
      end

      def git_url
        url = URI.parse(github_repo_url)
        url.password = ENV['SCRAPED_PAGE_ARCHIVE_GITHUB_TOKEN']
        url.to_s
      end

      def github_repo_url
        @github_repo_url ||= (git_remote_get_url_origin || ENV['MORPH_SCRAPER_CACHE_GITHUB_REPO_URL'])
      end

      def git_remote_get_url_origin
        remote_url = `git remote get-url origin`.chomp
        remote_url.empty? ? nil : remote_url
      end

      # TODO: This should be configurable
      def refresh_cache?
        true
      end

      # TODO: This should be configurable
      def branch_name
        @branch_name ||= 'scraped-pages-archive'
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
