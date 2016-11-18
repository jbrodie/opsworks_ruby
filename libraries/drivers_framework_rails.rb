# frozen_string_literal: true
module Drivers
  module Framework
    class Rails < Drivers::Framework::Base
      adapter :rails
      allowed_engines :rails
      output filter: [
        :migrate, :migration_command, :deploy_environment, :assets_precompile, :assets_precompilation_command,
        :envs_in_console
      ]
      packages debian: 'zlib1g-dev', rhel: 'zlib-devel'

      def raw_out
        super.merge(deploy_environment: { 'RAILS_ENV' => deploy_env })
      end

      def configure
        rdses =
          context.search(:aws_opsworks_rds_db_instance).presence || [Drivers::Db::Factory.build(context, app)]
        rdses.each do |rds|
          database_yml(Drivers::Db::Factory.build(context, app, rds: rds))
        end
        write_config_files_yml(context, app)
      end

      def deploy_before_migrate
        symlink_config_files(context, app)
      end

      def deploy_after_restart
        setup_rails_console
      end

      private

      def database_yml(db)
        return unless db.applicable_for_configuration?

        database = db.out
        deploy_environment = deploy_env

        context.template File.join(deploy_dir(app), 'shared', 'config', 'database.yml') do
          source 'database.yml.erb'
          mode '0660'
          owner node['deployer']['user'] || 'root'
          group www_group
          variables(database: database, environment: deploy_environment)
        end
      end

      def symlink_config_files(context, app)
        shared_files = JSON.parse((context.node['deploy'][app['shortname']]['shared_files'] || {}).to_json)
        links = {}
        release_path = Dir[File.join(deploy_dir(app), 'releases', '*')].sort.last
        shared_files.each do |key, values|
          context.link File.join(release_path, 'config', key) do
            to File.join(deploy_dir(app), 'shared', 'config', key)
          end
        end
      end

      def write_config_files_yml(context, app)
        shared_files = JSON.parse((context.node['deploy'][app['shortname']]['shared_files'] || {}).to_json)
        deploy_environment = deploy_env
        shared_files.each do |key, values|
          context.template File.join(deploy_dir(app), 'shared', 'config', key) do
            source 'shared_files.yml.erb'
            mode '0660'
            owner node['deployer']['user'] || 'root'
            group www_group
            variables(values: values, environment: deploy_environment)
          end
        end
      end

      def setup_rails_console
        return unless out[:envs_in_console]
        application_rb_path = File.join(deploy_dir(app), 'current', 'config', 'application.rb')

        return unless File.exist?(application_rb_path)
        env_code = "if(defined?(Rails::Console))\n  " +
                   environment.map { |key, value| "ENV['#{key}'] = #{value.inspect}" }.join("\n  ") +
                   "\nend\n"

        contents = File.read(application_rb_path).sub(/(^(?:module|class).*$)/, "#{env_code}\n\\1")

        File.open(application_rb_path, 'w') { |file| file.write(contents) }
      end

      def environment
        app['environment'].merge(out[:deploy_environment])
      end
    end
  end
end
