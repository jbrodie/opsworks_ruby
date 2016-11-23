# frozen_string_literal: true
module Drivers
  module Dns
    class Route53 < Drivers::Dns::Base

      adapter :route53
      allowed_engines :route53
      output filter: []

      def out
        super
        Chef::Log.warn(' SUPER CALLED!!!  SUPER CALLED!!!  SUPER CALLED!!!  SUPER CALLED!!!  SUPER CALLED!!!  SUPER CALLED!!!  SUPER CALLED!!! ')
      end

      def configure
        dns = Drivers::Dns::Factory.build(context, app)
        dns.out
        add_update_dns(dns)
      end


      def after_deploy
        dns = Drivers::Dns::Factory.build(context, app)
        dns.out
        add_update_dns(dns)
      end

      def after_undeploy
        remove_dns
      end

      def setup
        dns.out
      end

      private

      def remove_dns
        context.include_recipe("route53::undeploy")
      end

      def add_update_dns(dns)
        # context.include_recipe("route53::deploy")
        context.route53_record "create a record" do
          name  node[:defaults][:dns][:domain] #{}"qqqqq.itrgdev.com"
          value node[:cloud][:public_hostname]
          type  "CNAME"

          # The following are for routing policies
          # weight "1" (optional)
          # set_identifier "my-instance-id" (optional-must be unique)
          zone_id               node[:route53][:zone_id] # "Z1PRUJSS4U83X0" #
          aws_access_key_id     node[:route53][:aws_access_key_id] # "AKIAIY4N3UZOHIZFSLJQ" #
          aws_secret_access_key node[:route53][:aws_secret_access_key] #"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" #
          overwrite true
          action :create
        end
      end
    end
  end
end
