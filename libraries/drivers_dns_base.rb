# frozen_string_literal: true
module Drivers
  module Dns
    class Base < Drivers::Base
      include Drivers::Dsl::Notifies
      include Drivers::Dsl::Output
      include Drivers::Dsl::Packages

      def setup
        handle_packages
      end

      def out
        handle_output(raw_out)
      end

      def raw_out
        # node['defaults']['dns'].merge!(
        #   node['deploy'][app['shortname']]['dns'] || {}
        # ).symbolize_keys
        node.override['defaults']['dns']['adapter'] = node['deploy'][app['shortname']]['dns']['adapter']
        node.default['defaults']['dns']['domain'] = node['deploy'][app['shortname']]['dns']['domain']
        node['defaults']['dns'].symbolize_keys
      end

      def validate_app_engine
      end
    end
  end
end
