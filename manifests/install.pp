class zfsonlinux::install(
  timeout = $zfsonlinux::params::timeout
) inherits zfsonlinux::params{
  case $::osfamily {
    'RedHat' : {
      class { 'zfsonlinux::reqs::redhat_devel' : }
      class { 'zfsonlinux::install::redhat' : timeout => $timeout }
      Class['zfsonlinux::reqs::redhat_devel'] -> Class['zfsonlinux::install::redhat']
    }
    # 'Debian' : { include 'zfsonlinux::install::debian' }
    default  : {
      notify('zfsonlinux:install not supported on this platform yet')
    }
  }
}
