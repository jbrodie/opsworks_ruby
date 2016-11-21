# frozen_string_literal: true
module Drivers
  module Dns
    class Route53 < Drivers::Dns::Base

      adapter :route53
      allowed_engines :route53
      output filter: [:config, :process_count, :require, :syslog]

      def after_deploy
        add_update_dns(Drivers::Dns::Factory.build(context, app))
      end

      def after_undeploy
        remove_dns
      end

      def setup

        Chef::Log.warn('************************************************* END OF DNS SETUP')
      end

      private

      def remove_dns
        Chef::Log.warn('************************************************* REMOVE DNS - AFTER UN DEPLOY')
      end

      def add_update_dns(dns)
        context.include_recipe("route53")
        Chef::Log.warn('************************************************* ADD DNS - AFTER DEPLOY')
        context.node.each do |k,v|
          Chef::Log.warn("#{k}")
          Chef::Log.warn("#{v}")
        end
        # Chef::Log.warn("#{context.node["opsworks"]["instance"]["id"]}")
        # include_recipe "route53"

        context.route53_record "create a record" do
          name  context.node["deploy"]["global"]["domain"]
          value context.node["ec2"]["public_hostname"]
          type  "CNAME"

          # The following are for routing policies
          # weight "1"
          # set_identifier "my-instance-id"
          # zone_id               node[:route53][:zone_id]
          # aws_access_key_id     node[:route53][:aws_access_key_id]
          # aws_secret_access_key node[:route53][:aws_secret_access_key]
          # overwrite true
          # action :create
        end

      end

      # def add_sidekiq_config
      #   deploy_to = deploy_dir(app)
      #   config = configuration
      #
      #   (1..process_count).each do |process_number|
      #     context.template File.join(deploy_to, File.join('shared', 'config', "sidekiq_#{process_number}.yml")) do
      #       owner node['deployer']['user']
      #       group www_group
      #       source 'sidekiq.conf.yml.erb'
      #       variables config: config
      #     end
      #   end
      # end
    end
  end
end
