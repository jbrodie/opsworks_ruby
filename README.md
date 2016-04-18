# opsworks_ruby Cookbook

[![Build Status](https://travis-ci.org/ajgon/opsworks_ruby.svg?branch=master)](https://travis-ci.org/ajgon/opsworks_ruby)
[![Coverage Status](https://coveralls.io/repos/github/ajgon/opsworks_ruby/badge.svg?branch=master)](https://coveralls.io/github/ajgon/opsworks_ruby?branch=master)

A [chef](https://www.chef.io/) cookbook to deploy Ruby applications to Amazon OpsWorks.

## Quick Start

This cookbook is design to "just work". So in base case scenario, all you have
to do is create a layer and application with assigned RDS data source, then
[add recipes to the corresponding OpsWorks actions](#recipes).

**Currently only PostgreSQL database, GIT SCM, Rails framework, Unicorn
appserver and nginx webserver are supported.** New drivers will be added soon.

## Requirements

### Cookbooks

* [deployer](https://supermarket.chef.io/cookbooks/deployer)
* [ruby-ng](https://supermarket.chef.io/cookbooks/ruby-ng)
* [nginx (~> 2.7)](https://supermarket.chef.io/cookbooks/nginx)
* [application_ruby](https://supermarket.chef.io/cookbooks/application_ruby)

### Platform

Currenty this cookbook was tested only under Ubuntu 14.04, more platforms will
be added soon. However, other Debian family distributions are assumed to work.

## Attributes

Attributes format follows the guidelines of old Chef 11.x based OpsWorks stack.
So all of them, need to be placed under `node['deploy'][<application_shortname>]`.
Attributes (and whole logic of this cookbook) are divided to five sections.
Following convention is used: `app == node['deploy'][<application_shortname>]`
so for example `app['framework']['adapter']` actually means
`node['deploy'][<application_shortname>]['framework']['adapter']`.

### database

Those parameters will be passed without any alteration to the `database.yml`
file. Keep in mind, that if you have RDS connected to your OpsWorks application,
you don't need to use them. The chef will do all the job, and determine them
for you.

* `app['database']['adapter']`
  * **Supported values:** `postgresql`
  * **Default:** `postgresql`
  * ActiveRecord adapter which will be used for database connection. Currently
    only PostgreSQL is supported.
* `app['database']['username']`
  * Username used to authenticate to the DB
* `app['database']['password']`
  * Password used to authenticate to the DB
* `app['database']['host']`
  * Database host
* `app['database']['database']`
  * Database name
* `app['database'][<any other>]`
  * Any other key-value pair provided here, will be passed directly to the
    `database.yml`

### scm

Those parameters can also be determined from OpsWorks application, and usually
you don't need to provide them here. Currently only `git` is supported.

* `app['scm']['scm_provider']`
  * **Supported values:** `git`
  * **Default:** `git`
  * SCM used by the cookbook to clone the repo.
* `app['scm']['repository']`
  * Repository URL
* `app['scm']['revision']`
  * Branch name/SHA1 of commit which should be use as a base of the deployment.
* `app['scm']['ssh_key']`
  * A private SSH deploy key (the key itself, not the file name), used when
    fetching repositories via SSH.
* `app['scm']['ssh_wrapper']`
  * A wrapper script, which will be used by git when fetching repository
    via SSH. Essentially, a value of `GIT_SSH` environment variable. This
    cookbook provides one of those scripts for you, so you shouldn't alter this
    variable unless you know what you're doing.
* `app['scm']['enabled_submodules']`
  * If set to `true`, any submodules included in the repository, will also be
    fetched.

### framework

Pre-optimalization for specific frameworks (like migrations, cache etc.).
Currently only `Rails` is supported.

* `app['framework']['adapter']`
  * **Supported values:** `rails`
  * **Default:** `rails`
  * Ruby framework used in project.
* `app['framework']['migrate']`
  * **Supported values:** `true`, `false`
  * **Default:** `true`
  * If set to `true`, migrations will be launch during deployment.
* `app['framework']['migration_command']`
  * A command which will be invoked to perform migration. This cookbook comes
    with predefined migration commands, well suited for the task, and usually
    you don't have to change this parameter.

### appserver

Configuration parameters for the ruby application server. Currently only
`Unicorn` is supported.

* [`app['appserver']['accept_filter']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Default:** `httpready`
* [`app['appserver']['backlog']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Default:** `1024`
* [`app['appserver']['delay']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Default:** `0.5`
* [`app['appserver']['preload_app']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-preload_app)
  * **Supported values:** `true`, `false`
  * **Default:** `true`
* [`app['appserver']['tcp_nodelay']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Supported values:** `true`, `false`
  * **Default:** `true`
* [`app['appserver']['tcp_nopush']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Supported values:** `true`, `false`
  * **Default:** `false`
* [`app['appserver']['tries']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-listen)
  * **Default:** `5`
* [`app['appserver']['timeout']`](https://unicorn.bogomips.org/Unicorn/Configurator.html#method-i-timeout)
  * **Default:** `50`
* [`app['appserver']['worker_processes']`](https://unicorn.bogomips.org/TUNING.html)
  * **Default:** `4`

### webserver

Webserver configuration. Proxy passing to application is handled out-of-the-box.
Currently only nginx is supported.

* `app['webserver']['build_type']`
  * **Supported values:** `default` or `source`
  * **Default:** `default`
  * The way the [nginx](https://supermarket.chef.io/cookbooks/nginx) cookbooks
    handles `nginx` installation. Check out [the corresponding docs](https://github.com/miketheman/nginx/tree/2.7.x#recipes)
    for more details.
* [`app['webserver']['client_body_timeout']`](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_body_timeout)
  * **Default:** `12`
* [`app['webserver']['client_header_timeout']`](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_header_timeout)
  * **Default:** `12`
* [`app['webserver']['client_max_body_size']`](http://nginx.org/en/docs/http/ngx_http_core_module.html#client_max_body_size)
  * **Default:** `10m`
* `app['webserver']['dhparams']`
  * If you wish to use custom generated DH primes, instead of common ones
    (which is a very good practice), put the contents (not file name) of the
    `dhparams.pem` file into this attribute. [Read more here.](https://weakdh.org/sysadmin.html)
* [`app['webserver']['keepalive_timeout']`](http://nginx.org/en/docs/http/ngx_http_core_module.html#keepalive_timeout)
  * **Default**: `15`
* `app['webserver']['log_dir']`
  * **Default**: `/var/log/nginx`
  * A place to store application-related nginx logs.
* [`app['webserver']['proxy_read_timeout']`](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_read_timeout)
  * **Default**: `60`
* [`app['webserver']['proxy_send_timeout']`](http://nginx.org/en/docs/http/ngx_http_proxy_module.html#proxy_send_timeout)
  * **Default**: `60`
* [`app['webserver']['send_timeout']`](http://nginx.org/en/docs/http/ngx_http_core_module.html#send_timeout)
  * **Default**: `10`
* `app['webserver']['ssl_for_legacy_browsers']`
  * **Supported values:** `true`, `false`
  * **Default:** `false`
  * By default nginx is configured to follow strict SSL security standards,
    [covered in this article](https://cipherli.st/). However, old browsers
    (like IE < 9 or Android < 2.2) wouldn't work with this configuration very
    well. If your application needs a support for those browsers, set this
    parameter to `true`.

Since this driver is basically a wrapper for [nginx cookbook](https://github.com/miketheman/nginx/tree/2.7.x),
you can also configure [`node['nginx']` attributes](https://github.com/miketheman/nginx/tree/2.7.x#attributes)
as well (notice that `node['deploy'][<application_shortname>]` logic doesn't
apply here.)

## Recipes

This cookbook provides five main recipes, which should be attached
to corresponding OpsWorks actions.

* `opsworks_ruby::setup` - attach to **Setup**
* `opsworks_ruby::configure` - attach to **Configure**
* `opsworks_ruby::deploy` - attach to **Deploy**
* `opsworks_ruby::undeploy` - attach to **Undeploy**
* `opsworks_ruby::shutdown` - attach to **Shutdown**

## Contributing

Please see [CONTRIBUTING](https://github.com/ajgon/opsworks_ruby/blob/master/CONTRIBUTING.md)
for details.

## Author and License

Author: Igor Rzegocki <[igor@rzegocki.pl](mailto:igor@rzegocki.pl)>
License: [MIT](http://opsworks-ruby.mit-license.org/)