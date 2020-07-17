# frozen_string_literal: true

RSpec.describe GitLS do
  it 'has a version number' do
    expect(GitLS::VERSION).not_to be nil
  end

  it 'works for itself' do
    expect(`git ls-files`.split("\n")).to eq(GitLS.files)
  end
end
