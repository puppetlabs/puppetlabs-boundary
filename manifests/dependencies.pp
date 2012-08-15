#
# Author:: James Turnbull <james@lovedthanlost.net>
# Module Name:: boundary
# Class:: boundary::dependencies
#
# Copyright 2011, Puppet Labs
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class boundary::dependencies {

  Exec {
    path => '/usr/bin:/usr/sbin:/bin:/sbin',
  }

  case $::operatingsystem {
    'redhat', 'centos': {

      $rpmkey = '/etc/pki/rpm-gpg/RPM-GPG-KEY-Boundary'

      file { $rpmkey:
        ensure => present,
        source => 'puppet:///modules/boundary/RPM-GPG-KEY-Boundary',
      }

      exec { 'import_key':
        command     => "/bin/rpm --import $rpmkey",
        subscribe   => File[$rpmkey],
        refreshonly => true,
      }

      yumrepo { 'boundary':
        enabled  => 1,
        baseurl  => "https://yum.boundary.com/centos/os/$::operatingsystemrelease/$::architecture/",
        gpgcheck => 1,
        gpgkey   => 'https://yum.boundary.com/RPM-GPG-KEY-Boundary',
      }
    }

    'debian', 'ubuntu': {

      package { 'apt-transport-https':
        ensure => latest,
      }

      $downcase_os = downcase($::operatingsystem)

      $repos = $::operatingsystem ? {
        'Debian' => 'main',
        'Ubuntu' => 'universe',
      }

      apt::source { "boundary":
        location   => "https://apt.boundary.com/${boundary::dependencies::downcase_os}",
        repos      => $boundary::dependencies::repos,
        key        => '6532CC20',
        key_server => 'pgp.mit.edu',
        require    => Package['apt-transport-https'],
      }

    }

    default: {
      fail('Platform not supported by Boundary module. Patches welcomed.')
    }
  }
}
