require 'spec_helper'

describe MapSource::Reader do
  it "parses the header correctly" do
    gdb_file = open(File.dirname(__FILE__) + '/../assets/sample.gdb')

    reader = MapSource::Reader.new(gdb_file)
    reader.header.created_by.must_equal 'MapSource'
    reader.header.signed_by.must_equal 'MapSource'
  end
end
