require 'spec_helper'

describe 'zfsonlinux::install', :type=>'class' do
  context 'on an unknown OS' do
    it { expect { should raise_error(Puppet::Error) } }
  end

  context 'on a supported Kernel' do
    let(:facts) { {
      :kernel => 'Linux',
    } }

    context 'on an unsupported OS' do
      let(:facts) { {
        :kernel => 'Linux',
        :osfamily => 'Debian',
        :operatingsystem => 'Debian',
      } }

      it { should contain_notify(
        'zfsonlinux::install not supported on this platform yet') }
    end

    context 'on a RedHat OS' do
      let(:facts) { {
        :kernel => 'Linux',
        :osfamily => 'RedHat',
        :operatingsystem => 'RedHat',
      } }

      it { should contain_class('zfsonlinux::install::redhat') }
    end
  end

end
