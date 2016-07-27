require 'test_helper'
require 'open-uri'

class VCR::ArchiveTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::VCR::Archive::VERSION
  end
end
