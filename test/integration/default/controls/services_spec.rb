control 'Shibboleth service' do
  impact 0.5
  title 'should be running and enabled'

  describe service('shibd') do
    it { should be_enabled }
    it { should be_running }
  end
end
