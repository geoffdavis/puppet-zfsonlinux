Puppet::Type.type(:zfs).provide(:zfsonlinux) do
  desc "Provider for zfs on Linux via the zfsonlinux.org project."

  commands :zfs => "/sbin/zfs"
  defaultfor :operatingsystem => :linux

  def self.instances(hash = {})
    output=zfs('list', '-t', 'filesystem', '-H', '-o', 'name').each_line.map(&:chomp)

    datasets = []
    hash = {}
    output.each do |line|
      hash[:provider] = :zfsonlinux
      hash[:name] = line

      datasets << new(hash)
      hash = {}
    end

    datasets
  end

  def add_properties
    properties = []
    Puppet::Type.type(:zfs).validproperties.each do |property|
      next if property == :ensure
      if value = @resource[property] and value != ""
        properties << "-o" << "#{property}=#{value}"
      end
    end
    properties
  end

  def create
    zfs *([:create] + add_properties + [@resource[:name]])
  end

  def destroy
    zfs(:destroy, @resource[:name])
  end

  def exists?
    if zfs(:list).split("\n").detect { |line| line.split("\s")[0] == @resource[:name] }
      true
    else
      false
    end
  end

  [:aclinherit, :atime, :canmount, :checksum, :compression, :copies, :devices, :exec, :logbias, :mountpoint, :nbmand, :primarycache, :quota, :readonly, :recordsize, :refquota, :refreservation, :reservation, :secondarycache, :setuid, :shareiscsi, :sharenfs, :sharesmb, :snapdir, :version, :volsize, :vscan, :xattr, :zoned, :vscan].each do |field|
    define_method(field) do
      zfs(:get, "-H", "-o", "value", field, @resource[:name]).strip
    end

    define_method(field.to_s + "=") do |should|
      zfs(:set, "#{field}=#{should}", @resource[:name])
    end
  end

  # These aren't valid properties in the zfsonlinux implementation
  [:aclmode, :shareiscsi].each do |field|
    define_method(field) do
      nil
    end

    define_method(field.to_s + "=") do |should|
      nil
    end
  end

end

