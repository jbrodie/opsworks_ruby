# frozen_string_literal: true
module Drivers
  module Dns
    class Factory
      def self.build(context, app, options = {})
        engine = detect_engine(app, context.node, options)
        raise StandardError, 'There is no supported Worker driver for given configuration.' if engine.blank?
        engine.new(context, app, options)
      end

      def self.detect_engine(app, node, _options)
        Drivers::Dns::Base.descendants.detect do |dns_driver|
          dns_driver.allowed_engines.include?(
            node['deploy'][app['shortname']]['dns'].try(:[], 'adapter') ||
            node['defaults']['dns']['adapter']
          )
        end
      end
    end
  end
end
