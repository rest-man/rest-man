require_relative '../_lib'

describe RestMan::ServerBrokeConnection do
  it "should have a default message of 'Server broke connection'" do
    e = RestMan::ServerBrokeConnection.new
    expect(e.message).to eq 'Server broke connection'
  end
end