#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Volume controller
#

class privatecloud::volume::controller(
  $ks_cinder_internal_port   = $os_params::ks_cinder_internal_port,
  $ks_cinder_password        = $os_params::ks_cinder_password,
  $ks_keystone_internal_host = $os_params::ks_keystone_internal_host,
  $ks_swift_internal_proto   = $os_params::ks_swift_internal_proto,
  $ks_swift_internal_host    = $os_params::ks_swift_internal_host,
  $ks_swift_internal_port    = $os_params::ks_swift_internal_port,
  $ks_glance_internal_host   = $os_params::ks_glance_internal_host,
  $api_eth                   = $os_params::api_eth,
) {

  include 'privatecloud::volume'

  class { 'cinder::scheduler': }

  class { 'cinder::api':
    keystone_password  => $ks_cinder_password,
    keystone_auth_host => $ks_keystone_internal_host,
    bind_host          => $api_eth
  }

  class { 'cinder::backup': }

  class { 'cinder::backup::swift':
    backup_swift_url => "${ks_swift_internal_proto}://${ks_swift_internal_host}:${ks_swift_internal_port}/v1/AUTH"
  }

  class { 'cinder::glance':
    glance_api_servers     => $ks_glance_internal_host,
    glance_request_timeout => '10'
  }

  @@haproxy::balancermember{"${::fqdn}-cinder_api":
    listening_service => 'cinder_api_cluster',
    server_names      => $::hostname,
    ipaddresses       => $api_eth,
    ports             => $ks_cinder_internal_port,
    options           => 'check inter 2000 rise 2 fall 5'
  }

}
