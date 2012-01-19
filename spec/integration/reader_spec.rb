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

  it "parses every track" do
    tracks = @reader.tracks
    al = tracks.find { |t| t.name == 'ACTIVE LOG 009' }
    al.wont_be_nil
    al.size.must_equal 296

    wpt = al.waypoints[9]
    wpt.latitude.must_be_close_to -23.17172
    wpt.longitude.must_be_close_to -44.83632
    wpt.altitude.must_be_close_to 1471, 0.05
  end
end
