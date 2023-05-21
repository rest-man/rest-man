require_relative '../_lib'

describe RestMan::Exceptions::Timeout do

  describe 'OpenTimeout' do
    it '#message' do
      e = RestMan::Exceptions::OpenTimeout.new("error message...")
      expect(e.message).to eq("error message...")
    end

    it "#message - should have a default message of 'Timed out connection to server'" do
      e = RestMan::Exceptions::OpenTimeout.new
      expect(e.message).to eq("Timed out connecting to server")
    end

    it "#original_exception" do
      original_exception = StandardError.new('someting wrong')
      e = RestMan::Exceptions::OpenTimeout.new('error message...', original_exception)
      expect(e.original_exception).to eq(original_exception)
    end
  end

  describe 'ReadTimeout' do
    it '#message' do
      e = RestMan::Exceptions::ReadTimeout.new("error message...")
      expect(e.message).to eq("error message...")
    end

    it "#message - should have a default message of 'Timed out connection to server'" do
      e = RestMan::Exceptions::ReadTimeout.new
      expect(e.message).to eq("Timed out reading data from server")
    end

    it "#original_exception" do
      original_exception = StandardError.new('someting wrong')
      e = RestMan::Exceptions::ReadTimeout.new('error message...', original_exception)
      expect(e.original_exception).to eq(original_exception)
    end
  end

  describe 'WriteTimeout' do
    it '#message' do
      e = RestMan::Exceptions::WriteTimeout.new("error message...")
      expect(e.message).to eq("error message...")
    end

    it "#message - should have a default message of 'Timed out connection to server'" do
      e = RestMan::Exceptions::WriteTimeout.new
      expect(e.message).to eq("Timed out writing data to server")
    end

    it "#original_exception" do
      original_exception = StandardError.new('someting wrong')
      e = RestMan::Exceptions::WriteTimeout.new('error message...', original_exception)
      expect(e.original_exception).to eq(original_exception)
    end
  end

end