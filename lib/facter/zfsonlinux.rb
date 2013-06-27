# zfsonlinux.rb
#
# This generates two facts on Linux systems:
# * zfsonlinux_spl_version
# * zfsonlinux_rpm_version
#
# Resources:
#   Multi-os facts:
# https://github.com/puppetlabs/facter/blob/master/lib/facter/operatingsystemrelease.rb
#   Redhat package versions:
# http://geek.jasonhancock.com/2011/11/01/package-version-as-fact-in-puppet/
#   Debian package versions:
# https://blog.kumina.nl/2010/03/puppet-tipstricks-getting-the-version-from-a-package/
#
if Facter.value(:kernel) == 'Linux'
  case Facter.value(:operatingsystem)
  when "CentOS", "RedHat", "Scientific", "SLC", "Ascendos",
    "CloudLinux", "PSBM"
    spl_version = %x{/bin/rpm -qa --queryformat "%{VERSION}-%{RELEASE}" spl}
    zfs_version = %x{/bin/rpm -qa --queryformat "%{VERSION}-%{RELEASE}" zfs}
  when "Debian", "Ubuntu"
    spl_version = %x{/usr/bin/dpkg-query -W -f='${Version}' spl}
    zfs_version = %x{/usr/bin/dpkg-query -W -f='${Version}' zfs}
  end

  Facter.add(:zfsonlinux_spl_version) do
    setcode do
      spl_version
    end
  end

  Facter.add(:zfsonlinux_zfs_version) do
    setcode do
      zfs_version
    end
  end

  zfsonlinux_present=false
  if zfs_version != ''
    zfsonlinux_present=true
  end

  Facter.add(:zfsonlinux_present) do
    setcode do
      zfsonlinux_present.to_s
    end
  end
end
