# frozen_string_literal: true
module Drivers
  module Dns
    class Null < Drivers::Dns::Base
      adapter :null
      allowed_engines :null
      output filter: []
    end
  end
end
