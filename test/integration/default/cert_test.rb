# frozen_string_literal: true

require_relative '../helpers'

node = json('/opt/chef/run_record/last_chef_run_node.json')['automatic']

owner_group =
  if node['platform_family'] == 'debian'
    'ssl-cert'
  else
    'root'
  end

alt_regex = 'subject_alt_name: \["DNS:www.funny.business", "DNS:funny.business", "DNS:www.me.also", "DNS:me.also"\]'
# rubocop:disable Metrics/LineLength
# alt_regex = 'subject_alt_name: \["DNS:www.funny.business", "DNS:funny.business", "DNS:www.localhost", "DNS:localhost", "DNS:www.me.also", "DNS:me.also"\]'
# rubocop:enable Metrics/LineLength

describe file('/opt/chef/run_record/http_cert_record.txt') do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match 'common_name: funny.business' }
  its(:content) { should match alt_regex }
  its(:content) { should match 'country: US' }
  its(:content) { should match 'state: Alaska' }
  its(:content) { should match 'city: Fairbanks' }
  its(:content) { should match 'org: fake_org' }
  its(:content) { should match 'org_unit: fake_unit' }
  its(:content) { should match 'email: fake-it@make-it' }
  its(:content) { should match 'expire: 365' }
  its(:content) { should match "group: #{owner_group}" }
  its(:content) { should match 'key_type: \'rsa\'' }
  its(:content) { should match 'key_length: 2048' }
end

describe file('/opt/chef/run_record/http_key_record.txt') do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match "group: #{owner_group}" }
  its(:content) { should match 'key_length: 2048' }
end

describe file(path_to_self_signed_key(node)) do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o640 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into key_group(node) }
  its(:content) { should match '-----BEGIN RSA PRIVATE KEY-----\nMIIE' }
end

describe key_rsa(path_to_self_signed_key(node)) do
  it { should be_public }
  it { should be_private }
  its('public_key') { should match '-----BEGIN PUBLIC KEY-----\nMIIB' }
  its('private_key') { should match '-----BEGIN RSA PRIVATE KEY-----\nMIIE' }
  its('key_length') { should eq 2048 }
end

describe file(path_to_self_signed_cert(node)) do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match 'BEGIN CERTIFICATE' }
end

describe x509_certificate(path_to_self_signed_cert(node)) do
  its('version') { should eq 2 }
  its('key_length') { should eq 2048 }
  its('signature_algorithm') { should eq 'sha256WithRSAEncryption' }
  its('validity_in_days') { should be > 364 }
  its('validity_in_days') { should be < 366 }

  its('subject.CN') { should eq 'funny.business' }
  its('subject.emailAddress') { should eq 'fake-it@make-it' }
  its('subject.C') { should eq 'US' }
  its('subject.ST') { should eq 'Alaska' }
  its('subject.L') { should eq 'Fairbanks' }
  its('subject.O') { should eq 'fake_org' }
  its('subject.OU') { should eq 'fake_unit' }

  its('extensions') { should include 'subjectAltName' }
  its('extensions.subjectAltName') { should include 'DNS:funny.business' }
  its('extensions.subjectAltName') { should include 'DNS:www.funny.business' }
  # its('extensions.subjectAltName') { should include 'DNS:localhost' }
  # its('extensions.subjectAltName') { should include 'DNS:www.localhost' }
  its('extensions.subjectAltName') { should include 'DNS:me.also' }
  its('extensions.subjectAltName') { should include 'DNS:www.me.also' }

  its('issuer.CN') { should eq 'funny.business' }
  its('issuer.emailAddress') { should eq 'fake-it@make-it' }
  its('issuer.C') { should eq 'US' }
  its('issuer.ST') { should eq 'Alaska' }
  its('issuer.L') { should eq 'Fairbanks' }
  its('issuer.O') { should eq 'fake_org' }
  its('issuer.OU') { should eq 'fake_unit' }
end

describe file(path_to_dh_config(node)) do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match '2048' }
end

describe file(path_to_dh_params(node)) do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match 'BEGIN DH PARAMETERS' }
end

describe file(File.join(cert_public_dir(node), 'http_platform_csr.pem')) do
  it { should exist }
  it { should be_file }
  it { should be_mode 0o644 }
  it { should be_owned_by 'root' }
  it { should be_grouped_into 'root' }
  its(:content) { should match 'BEGIN CERTIFICATE REQUEST' }
end
