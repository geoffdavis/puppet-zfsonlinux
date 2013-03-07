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


Facter.add(:zfs_version) do
  confine :kernel => :linux
  confine :zfsonlinux_present => :true
  setcode do
    zfs_v = Facter::Util::Resolution.exec('zfs upgrade -v')
    if zfs_v
      zfs_v.scan(/^\s+(\d+)\s+/m).flatten.last
    else
      nil
    end
  end
end

Facter.add(:zpool_version) do
  confine :kernel => :linux
  confine :zfsonlinux_present => :true
  setcode do
    zpool_v = Facter::Util::Resolution.exec('zpool upgrade -v')
    if zpool_v
      # ZFS pool version XX
      version_match=zpool_v.match(/ZFS pool version (\d+)./)
      if version_match
        return version_match.captures.first
      end
      # VER  DESCRIPTION
      # ---  --------------------------------------------------------
      #  1   Initial ZFS version
      # ...
      #  28  Multiple vdev replacements
      zpool_v.scan(/^( {1}\d+)\s{2,3}.\w+/).last.first.to_i
    else
      nil
    end
  end
end
