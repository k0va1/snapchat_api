module SnapchatApi
  module Resources
    class Base
      attr_reader :client

      def initialize(client)
        @client = client
      end
    end
  end
end
