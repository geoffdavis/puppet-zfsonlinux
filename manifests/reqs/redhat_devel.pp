class zfsonlinux::reqs::redhat_devel {
  $deps = [
    'make',
    'rpm-devel',
    'rpm-build',
    'zlib-devel',
    'kernel-devel',
    'libuuid-devel',
    'lsscsi',
    'parted',
  ]

  package { $deps :
    ensure => 'installed',
  }

}
