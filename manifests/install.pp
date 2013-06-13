# == Class: zfsonlinux::install
#
# This class will install zfsonlinux to the specified version.
# ZFS on Linux as provided by zfsonlinux.org has two major components:
# * SPL - The Solaris Porting Layer
# * ZFS itself
#
# Typically, the ZFS and SPL versions must match, but we provide the ability
# to override the individual component versions.
#
# == Parameters
#
# If a parameter is not specified, it will default to the value in
# zfsonlinux::params. See that class for values
#
# === Common Parameters
#
# [*version*]
#   The version of ZFS and SPL packages to install. Versions of individual
#   components can be set using the variables below.
#
# [*timeout*]
#   The timeout value to use for each step of the staging and build process.
#
# [*verbose*]
#   Turn on verbose mode when building ZFSOnLinux. Should be true or false.
#   Defaults to false.
#
# [*upgrade*]
#   Upgrade packages if they are already installed. Defaults to false since
#   this can leave a system unable to access critical filesystems if the ZFS
#   packages are removed while a system is running.
#
# [*dependency*]
#   If false, the module will not try to install package dependencies.
#   These must be provided elsewhere in your package configuration
#
# === Advanced Parameters
#
# [*spl_version*]
#   The version of SPL - the Solaris Porting Layer - to install. Only necessary
#   if you want to override the version parameter for this component.
#   *Don't do this unless you know what you're doing*
#
# [*zfs_version*]
#   The version of ZFS to install. Only necessary if you want to override the
#   version parameter for this component.
#   *Don't do this unless you know what you're doing*
#
# == Examples
#
#   # Install the current version as of this module's writing 0.6.0-rc8
#   include zfsonlinux::install
#
#   # More customized
#   class { 'zfsonlinux::install':
#     version     => '0.6.0-rc8',
#     spl_version => '0.6.0-rc7',
#     timeout     => '3600',
#   }
#
# == Caveats
#
# This has only been tested on CentOS 6.2 and with the 0.6.0 series of
# ZFSOnLinux.
#
# Specifiying a different version of spl_version and zfs_version may not work
# due to tight code dependencies
#
# Downgrading an already installed version of spl or zfs will not work
#
# Upgrading is particularly dangerous, as a system can be left without access
# to critical filesystems
#
# == Authors
#
# Geoff Davis <gadavis@ucsd.edu>
#
# == Copyright
#
# Copyright 2012 The Regents of the University of California
#
# == License
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
class zfsonlinux::install(
  $version     = $zfsonlinux::params::version,
  $zfs_version = undef,
  $spl_version = undef,
  $timeout     = $zfsonlinux::params::timeout,
  $verbose     = false,
  $upgrade     = false,
  $dependency  = true
) inherits zfsonlinux::params{

  ###
  # Validate parameters
  validate_bool($verbose)
  validate_string($version)
  validate_re($timeout, [ '^[0-9]+', '' ])

  ###
  # Set up internal variables
  $real_spl_version = $zfsonlinux::install::spl_version ? {
    ''      => $zfsonlinux::install::version,
    default => $zfsonlinux::install::spl_version,
  }
  $real_zfs_version = $zfsonlinux::install::zfs_version ? {
    ''      => $zfsonlinux::install::version,
    default => $zfsonlinux::install::zfs_version,
  }

  case $::osfamily {
    'RedHat' : {
      if $dependency {
        class { 'zfsonlinux::reqs::redhat_devel' :
          before => Class['zfsonlinux::install::redhat'],
        }
      }

      class { 'zfsonlinux::install::redhat' :
        timeout     => $timeout,
        zfs_version => $real_zfs_version,
        spl_version => $real_spl_version,
        verbose     => $verbose,
        upgrade     => $upgrade,
      }
    }

    # 'Debian' : { include 'zfsonlinux::install::debian' }

    default  : {
      notice('zfsonlinux:install not supported on this platform yet')
    }
  }
}
