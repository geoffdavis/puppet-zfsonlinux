# === Class: zfsonlinux::install::redhat
#
# This class is for internal use only by zfsonlinux::install, and is not
# intended for general usage.
#
# === Parameters:
#
# *[download_dir]*
#    Source URL of the directory containing the tar files.
#    This can be a URL or a path on local disk. It is used by the staging
#    module to retrieve the installer tar.gz files.
#
class zfsonlinux::install::redhat (
  $download_dir = $zfsonlinux::params::download_dir,
  $spl_version  = $zfsonlinux::params::version,
  $zfs_version  = $zfsonlinux::params::version,
  $timeout      = $zfsonlinux::params::install_timeout,
  $verbose      = false,
  $upgrade      = false,
) inherits zfsonlinux::params {
  ####
  # Check our parameters
  validate_bool($verbose)

  case $::zfsonlinux_zfs_version {
    $zfs_version : {
      # No-op if we're already at the right version
      notice "zfsonlinux already at requested version $zfs_version"
      $do_install = false
    }

    '' : {
      # If $zfs_version is unset, zfsonlinux is not installed
      notice "Attempting install of zfsonlinux spl $spl_version, zfs $zfs_version"
      $do_install = true
      if $::zfsonlinux_spl_version != '' {
        $do_uninstall_first = true
      }
    }

    default : {
      # zfs_version doesn't match zfsonlinux_zfs_version fact
      if $upgrade {
        # We will uninstall the old packages and then install the new ones
        $do_install = true
        $do_uninstall_first = true
      } else {
        # No-op if zfsonlinux is installed but upgrade is false
        notice "Not upgrading zfsonlinux. zfsonlinux is at version $zfsonline_zfs_version, requested version $zfs_version, but upgrade is set to false."
        $do_install = false
      }
    }

  }


  if $do_install {
    require staging

    ####
    # Set up variables
    ####

    # http://github.com/downloads/zfsonlinux/spl/spl-0.6.0-rc8.tar.gz
    $spl_installer_tar = "spl-${spl_version}.tar.gz"
    $spl_installer_dir = "spl-${spl_version}"
    $spl_source_url = "${download_dir}/spl/${spl_installer_tar}"
    $spl_packagenames = [
      'spl',
      'spl-modules',
      'spl-modules-devel',
    ]
    $spl_packagenames_s = join($spl_packagenames, ' ')

    $zfs_installer_tar = "zfs-${zfs_version}.tar.gz"
    $zfs_installer_dir = "zfs-${zfs_version}"
    $zfs_source_url = "${download_dir}/zfs/${zfs_installer_tar}"
    $zfs_packagenames = [
      'zfs',
      'zfs-dracut',
      'zfs-modules',
      'zfs-modules-devel',
      'zfs-devel',
      'zfs-test',
    ]
    $zfs_packagenames_s = join($zfs_packagenames, ' ')

    $manage_exec_logoutput = $verbose ? {
      true    => true,
      false => on_failure,
    }

    $manage_exec_timeout = $timeout

    $manage_staging_timeout = $timeout

    ###
    # Set resource defaults
    ###
    Exec { path => '/usr/local/bin:/usr/bin:/bin', }

    ###
    # Uninstall existing spl and zfs packages
    ###
    if $do_uninstall_first {
      if $::zfsonlinux_zfs_version != '' {
        exec { 'uninstall-for-upgrade ZFS' :
          command   => "rpm -e ${zfs_packagenames_s}",
          timeout   => $manage_exec_timeout,
          logoutput => $manage_exec_logoutput,
          user      => 0,
          group     => 0,
          before    => Exec['uninstall-for-upgrade SPL'],
        }
      }
      exec { 'uninstall-for-upgrade SPL' :
        command => "rpm -e ${spl_packagenames_s}",
        timeout => $manage_exec_timeout,
        logoutput => $manage_exec_logoutput,
        user    => 0,
        group   => 0,
        before  => Exec['install spl rpms'],
      }
    }

    ###
    # Stage the installers
    ###

    staging::file { $spl_installer_tar :
      source  => $spl_source_url,
      timeout => $manage_staging_timeout,
    }

    staging::extract { $spl_installer_tar :
      target  => "${staging::path}/zfsonlinux",
      require => Staging::File[$spl_installer_tar],
    }

    staging::file { $zfs_installer_tar :
      source  => $zfs_source_url,
      timeout => $manage_staging_timeout,
    }

    staging::extract { $zfs_installer_tar :
      target  => "${staging::path}/zfsonlinux",
      require => Staging::File[$zfs_installer_tar],
    }

    ###
    # Perform build of spl
    ##

    exec { 'configure spl':
      command      => "${staging::path}/zfsonlinux/${spl_installer_dir}/configure",
      cwd          => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput    => $manage_exec_logoutput,
      #    creates => "${staging::path}/zfsonlinux/${spl_installer_dir}/Makefile",
      require      => Staging::Extract[$spl_installer_tar],
      timeout      => $manage_exec_timeout,
    }

    exec { 'build spl':
      command   => 'make rpm',
      cwd       => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput => $manage_exec_logoutput,
      require   => Exec['configure spl'],
      timeout   => $manage_exec_timeout,
    }

    exec { 'install spl rpms':
      command   => "rpm -Uvh *.${::hardwareisa}.rpm",
      cwd       => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput => $manage_exec_logoutput,
      require   => Exec['build spl'],
      timeout   => $manage_exec_timeout,
      user      => 0,
      group     => 0,
    }

    ###
    # Perform build of zfs
    ###
    exec { 'configure zfs':
      command   => "${staging::path}/zfsonlinux/${zfs_installer_dir}/configure",
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => $manage_exec_logoutput,
      # creates   => "${staging::path}/zfsonlinux/${zfs_installer_dir}/Makefile",
      require   => [
        Staging::Extract[$zfs_installer_tar],
        Exec['install spl rpms'],
        ],
      timeout      => $manage_exec_timeout,
    }

    exec { 'build zfs':
      command   => 'make rpm',
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => $manage_exec_logoutput,
      require   => Exec['configure zfs'],
      timeout   => $manage_exec_timeout,
    }

    exec { 'install zfs rpms':
      command   => "rpm -Uvh *.${::hardwareisa}.rpm",
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => $manage_exec_logoutput,
      require   => Exec['build zfs'],
      timeout   => $manage_exec_timeout,
      user      => 0,
      group     => 0,
    }

  }

}
