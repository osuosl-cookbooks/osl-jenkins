control 'jenkins1' do
  describe package 'graphviz' do
    it { should be_installed }
  end
end
