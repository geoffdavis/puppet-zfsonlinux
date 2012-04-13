class zfsonlinux::install {
  case $::osfamily {
    'RedHat' : { include 'zfsonlinux::install::redhat' }
    # 'Debian' : { include 'zfsonlinux::install::debian' }
    default  : {
      notify('zfsonlinux:install not supported on this platform yet')
    }
  }
}
