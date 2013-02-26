# Default parameters for most of the zfsonlinux classes
class zfsonlinux::params {
  # basic sanity checking
  if $::kernel != 'Linux' {
    fail('ZFSOnLinux can only be run on Linux.')
  }

  $version = '0.6.0-rc14'
  $download_dir = 'http://github.com/downloads/zfsonlinux'
  $install_timeout = '1200'
}
