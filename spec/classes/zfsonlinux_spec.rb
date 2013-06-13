require 'spec_helper'

describe 'zfsonlinux', :type=>'class' do
  context 'on an unknown OS' do
    it { expect { should raise_error(Puppet::Error) } }
  end

  context 'on a supported Kernel' do
    let(:facts) { {
      :kernel => 'Linux',
    } }
    it { should include_class('zfsonlinux::install') }
  end
end
