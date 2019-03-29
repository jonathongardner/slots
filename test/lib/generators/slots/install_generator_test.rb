# frozen_string_literal: true

require 'test_helper'
require 'generators/slots/install/install_generator'

module Slots
  class InstallGeneratorTest < Rails::Generators::TestCase
    tests InstallGenerator
    destination Rails.root.join('tmp/generators')
    setup :prepare_destination

    # test "generator runs without errors" do
    #   assert_nothing_raised do
    #     run_generator ["arguments"]
    #   end
    # end
  end
end
