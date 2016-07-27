require 'test_helper'
require 'open-uri'

class VCR::ArchiveTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::VCR::Archive::VERSION
  end

  def test_serializer
    assert_equal 'archive', VCR::Archive::YamlSeparateHtmlSerializer.file_extension
    assert_equal({ foo: :bar }, VCR::Archive::YamlSeparateHtmlSerializer.serialize(foo: :bar))
    assert_equal({ foo: :bar }, VCR::Archive::YamlSeparateHtmlSerializer.deserialize(foo: :bar))
  end

  def test_persister
    Dir.mktmpdir do |dir|
      VCR.use_cassette(dir) do
        open('http://example.com/')
      end
      assert File.directory?(File.join(dir, 'example.com'))
      assert File.exist?(File.join(dir, 'example.com', '9c17e047f58f9220a7008d4f18152fee4d111d14.html'))
      assert File.exist?(File.join(dir, 'example.com', '9c17e047f58f9220a7008d4f18152fee4d111d14.yml'))
    end
  end
end
