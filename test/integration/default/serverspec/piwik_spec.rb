require "serverspec"

set :backend, :exec

describe port("80") do
  it { should be_listening }
end

describe command("curl -L localhost/piwik") do
  its(:stdout) { should match /Piwik/ }
end
