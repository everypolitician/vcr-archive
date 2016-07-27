require 'simplecov'
SimpleCov.start if ENV['COVERAGE']

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'vcr/archive'

require 'minitest/autorun'
