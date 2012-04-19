class zfsonlinux::install::redhat (
  $download_dir = $zfsonlinux::params::download_dir,
  $spl_version  = $zfsonlinux::params::spl_version,
  $zfs_version  = $zfsonlinux::params::zfs_version,
  $timeout      = undef
) inherits zfsonlinux::params {

  # No-op if we're already at the right version
  if $::zfsonlinux_zfs_version == $zfs_version {
    notice "zfsonlinux already at requested version $zfs_version"
  } else {
    require staging

    ####
    # Set up variables
    ####

    # http://github.com/downloads/zfsonlinux/spl/spl-0.6.0-rc8.tar.gz
    $spl_installer_tar = "spl-${spl_version}.tar.gz"
    $spl_installer_dir = "spl-${spl_version}"
    $spl_source_url = "${download_dir}/spl/${spl_installer_tar}"

    $zfs_installer_tar = "zfs-${zfs_version}.tar.gz"
    $zfs_installer_dir = "zfs-${zfs_version}"
    $zfs_source_url = "${download_dir}/zfs/${zfs_installer_tar}"

    ###
    # Set resource defaults
    ###
    Exec { path => '/usr/local/bin:/usr/bin:/bin', }

    ###
    # Stage the installers
    ###

    staging::file { $spl_installer_tar :
      source  => $spl_source_url,
      timeout => $timeout,
    }

    staging::extract { $spl_installer_tar :
      target  => "${staging::path}/zfsonlinux",
      require => Staging::File[$spl_installer_tar],
    }

    staging::file { $zfs_installer_tar :
      source  => $zfs_source_url,
      timeout => $timeout,
    }

    staging::extract { $zfs_installer_tar :
      target  => "${staging::path}/zfsonlinux",
      require => Staging::File[$zfs_installer_tar],
    }

    ###
    # Perform build of spl
    ##

    exec { 'configure spl':
      command   => "${staging::path}/zfsonlinux/${spl_installer_dir}/configure",
      cwd       => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput => on_failure,
      #    creates   => "${staging::path}/zfsonlinux/${spl_installer_dir}/Makefile",
      require   => Staging::Extract[$spl_installer_tar],
    }

    exec { 'build spl':
      command => 'make rpm',
      cwd       => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput => on_failure,
      require   => Exec['configure spl'],
    }

    exec { 'install spl rpms':
      command   => "rpm -Uvh *.${::hardwareisa}.rpm",
      cwd       => "${staging::path}/zfsonlinux/${spl_installer_dir}",
      logoutput => on_failure,
      require   => Exec['build spl'],
      user      => 0,
      group     => 0,
    }

    ###
    # Perform build of zfs
    ###
    exec { 'configure zfs':
      command   => "${staging::path}/zfsonlinux/${zfs_installer_dir}/configure",
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => on_failure,
      # creates   => "${staging::path}/zfsonlinux/${zfs_installer_dir}/Makefile",
      require   => [
        Staging::Extract[$zfs_installer_tar],
        Exec['install spl rpms'],
        ],
    }

    exec { 'build zfs':
      command => 'make rpm',
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => on_failure,
      require   => Exec['configure zfs'],
    }

    exec { 'install zfs rpms':
      command   => "rpm -Uvh *.${::hardwareisa}.rpm",
      cwd       => "${staging::path}/zfsonlinux/${zfs_installer_dir}",
      logoutput => on_failure,
      require   => Exec['build zfs'],
      user      => 0,
      group     => 0,
    }

  }

}
