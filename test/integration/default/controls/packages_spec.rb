control 'Shibboleth package' do
  title 'should be installed'

  describe package('shibboleth') do
    it { should be_installed }
  end
end
