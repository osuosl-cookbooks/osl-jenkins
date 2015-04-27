require 'serverspec'

set :backend, :exec

describe file('/var/lib/jenkins/credentials.xml') do
  it { should be_file }
  it { should contain '<username>alfred</username>' }
end

describe file('/var/lib/jenkins/users/alfred/config.xml') do
  it { should be_file }
  it do
    should contain 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2aaJit5+siL2HWkho' \
    'ObF/FHLlj+vQjIORq0VADAhzcLCywRA6cab68dobw31W/wGRbEhuhm9YxZRV+nncOkRykRX' \
    '3QDbRUeUSqGPFyE487OgPK9LaPve1Tu+gug0TDrOtEgXlFnzhKrQesglpF8R+cUmIYsJX2i' \
    'sgbtNdEUpFunl/Dyjo2iXSVkr1ZRjr99do89EwvUB2XflZYoPxnqT+uufMn2WxJM5PpqEkD' \
    'mdwVx0q2LxYvksxgsKcCdEvKBYgt0+sBpqFxLuCHMwgQPDPDh2rcMhBfu1Budc8Af8LGwAA' \
    '48gehZyC29ZkoY75QNgcPtocrg/2VVLNRX3qGjN9 jenkins@osuosl'
  end
end
