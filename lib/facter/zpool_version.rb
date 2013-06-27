require 'facter'

Facter.add(:zpool_version) do
  setcode do
    if Facter::Util::Resolution.which('zpool')
      zpool_v = Facter::Util::Resolution.exec('zpool upgrade -v')
      zpool_v.scan(/^ {1}(\d+)\s{2,3}.\w+/).flatten.last unless zpool_v.nil?
    end
  end
end
