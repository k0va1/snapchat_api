# frozen_string_literal: true

require "test_helper"

class SnapchatApiTest < Minitest::Test
  def test_has_a_version_number
    refute_nil SnapchatApi::VERSION
  end
end
