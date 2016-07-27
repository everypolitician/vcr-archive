require 'test_helper'
require 'open-uri'

describe VCR::Archive do
  it 'has a version number' do
    refute_nil ::VCR::Archive::VERSION
  end
end
