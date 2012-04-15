class zfsonlinux::install {
  case $::osfamily {
    'RedHat' : {
      class { 'zfsonlinux::reqs::redhat_devel' : }
      class { 'zfsonlinux::install::redhat' : }
      Class['zfsonlinux::reqs::redhat_devel'] -> Class['zfsonlinux::install::redhat']
    }
    # 'Debian' : { include 'zfsonlinux::install::debian' }
    default  : {
      notify('zfsonlinux:install not supported on this platform yet')
    }
  }
}
