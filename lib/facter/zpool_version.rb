require 'facter'
Facter.add(:zpool_version) do
  confine :kernel => :linux
  confine :zfsonlinux_present => :true
  setcode do
    zpool_v = Facter::Util::Resolution.exec('zpool upgrade -v')
    # VER  DESCRIPTION
    # ---  --------------------------------------------------------
    #  1   Initial ZFS version
    # ...
    #  28  Multiple vdev replacements
    zpool_v.scan(/^ {1}(\d+)\s{2,3}.\w+/).flatten.last unless zpool_v.nil?
  end
end
