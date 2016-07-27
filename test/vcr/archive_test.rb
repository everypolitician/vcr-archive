require 'test_helper'
require 'open-uri'

describe VCR::Archive do
  it 'has a version number' do
    refute_nil ::VCR::Archive::VERSION
  end

  describe 'Serializer'  do
    subject { VCR::Archive::Serializer }
    it 'returns "archive" as the file extension' do
      assert_equal 'archive', subject.file_extension
    end

    it "doesn't touch the hash when (de)serializing" do
      assert_equal({ foo: :bar }, subject.serialize(foo: :bar))
      assert_equal({ foo: :bar }, subject.deserialize(foo: :bar))
    end
  end
end
