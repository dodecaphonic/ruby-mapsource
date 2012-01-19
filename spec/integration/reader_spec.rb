require 'spec_helper'

describe MapSource::Reader do
  before :each do
    @gdb_file = open(File.dirname(__FILE__) + '/../assets/sample.gdb')
    @reader = MapSource::Reader.new(@gdb_file)
  end

  after :each do
    @gdb_file.close
  end

  it "parses the header correctly" do
    @reader.header.created_by.must_equal 'MapSource'
    @reader.header.signed_by.must_equal 'MapSource'
  end

  it "parses all waypoints" do
    @reader.waypoints.size.must_equal 312
  end
end
