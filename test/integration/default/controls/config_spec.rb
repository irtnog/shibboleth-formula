control 'Shibboleth configuration' do
  title 'should match desired lines'

  describe file('/etc/shibboleth/shibboleth2.xml') do
    it { should be_file }
    it { should be_owned_by 'root' }
    it { should be_grouped_into 'root' }
    its('mode') { should cmp '0644' }
    its('content') { should include 'The ApplicationDefaults element is where most of Shibboleth\'s SAML bits are defined.' }
  end
end
