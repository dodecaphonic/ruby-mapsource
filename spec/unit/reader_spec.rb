require 'spec_helper'

describe MapSource::Reader do
  describe "when reading the header" do
    it "fails when first portion of the file doesn't pass validation" do
      gdb_file, sequence = *create_basic_valid_state(before: :start)

      bogus = mock('bogus')
      bogus.expects(:unpack).with('A*').returns ['Bogus']
      gdb_file.expects(:read).with(6).returns bogus

      lambda {
        MapSource::Reader.new gdb_file
      }.must_raise MapSource::InvalidFormatError
    end

    it "fails when header is malformed" do
      gdb_file, sequence = *create_basic_valid_state(before: :version)

      reclen = mock('reclen')
      reclen.expects(:unpack).with('l').returns [2]
      gdb_file.expects(:read).in_sequence(sequence).with(4).returns reclen

      gdb_file.expects(:read).in_sequence(sequence).with(3).returns "Am\x00"

      lambda {
        MapSource::Reader.new gdb_file
      }.must_raise MapSource::InvalidFormatError
    end

    it "fails when version is unsupported" do
      gdb_file, sequence = *create_basic_valid_state(before: :version)

      reclen = mock('reclen')
      reclen.expects(:unpack).with('l').returns [2]
      gdb_file.expects(:read).in_sequence(sequence).with(4).returns reclen

      gdb_file.expects(:read).in_sequence(sequence).with(3).returns "Dn\x00"

      lambda {
        MapSource::Reader.new gdb_file
      }.must_raise MapSource::UnsupportedVersionError
    end

    it "determines which version of the format it has" do
      gdb_file, _ = *create_basic_valid_state

      reader = MapSource::Reader.new(gdb_file)
      reader.header.version.must_equal 3
    end

    it "determines which software created the file" do
      gdb_file, _ = *create_basic_valid_state

      reader = MapSource::Reader.new(gdb_file)
      reader.header.created_by.must_equal 'MapSource'
    end

    it "determines which software signed the file" do
      gdb_file, _ = *create_basic_valid_state

      reader = MapSource::Reader.new(gdb_file)
      reader.header.signed_by.must_equal 'MapSource'
    end

    it "fails when creator is not recognized" do
      gdb_file, sequence = *create_basic_valid_state(before: :signer)

      gdb_file.expects(:read).in_sequence(sequence).with(10).returns 'BogusSoftw'
      gdb_file.expects(:read).in_sequence(sequence).with(1).times(3).returns 'x'
      gdb_file.expects(:read).in_sequence(sequence).with(1).returns "\x00"

      lambda {
        MapSource::Reader.new gdb_file
      }.must_raise MapSource::InvalidFormatError
    end
  end

  describe "when reading the content" do
    it "parses waypoints" do
      gdb_file, seq = *create_basic_valid_state

      gdb_file.expects(:read).in_sequence(seq).with(4).returns "\l\x00\x00\x00"
      gdb_file.expects(:read).in_sequence(seq).with(109).returns "W001\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\xFF\x00\x00\xFF\xFF\xFF\xFF\xE7\xB7\x85\xEF\xDE\xCB\x1D\xE0\x01\x00\x00\x00\x80\xF9X\x97@15-DEZ-11 12:06:43PM\x00\x00\x01\x00\x00\x00\x01\x00\x00\x00\x8D\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"
      gdb_file.expects(:read).in_sequence(seq).with(4).returns "\x01\x00\x00\x00"
      gdb_file.expects(:read).in_sequence(seq).with(2).returns "V\x00"

      reader = MapSource::Reader.new(gdb_file)

      reader.waypoints.size.must_equal 1
      wpt = reader.waypoints.first
      wpt.shortname.must_equal "001"
      wpt.latitude.must_be_close_to -23.17171306349337
      wpt.longitude.must_be_close_to -44.836323726922274
      wpt.notes.must_equal "15-DEZ-11 12:06:43PM"
      wpt.altitude.floor.must_be_close_to 1494
    end

    it "parses tracks" do
      track = open(SAMPLE_TRACK, 'rb').read
      gdb_file, seq = *create_basic_valid_state
      gdb_file.expects(:read).in_sequence(seq).with(4).returns "\xC0r\x00\x00"
      gdb_file.expects(:read).in_sequence(seq).with(29377).returns track
      gdb_file.expects(:read).in_sequence(seq).with(4).returns "\x01\x00\x00\x00"
      gdb_file.expects(:read).in_sequence(seq).with(2).returns "V\x00"

      reader = MapSource::Reader.new(gdb_file)
      reader.tracks.size.must_equal 1

      track = reader.tracks.first
      track.name.must_equal "ACTIVE LOG"
      track.color.name.must_equal "Red"
      track.size.must_equal 1223

      wpt = track.waypoints.first
      wpt.latitude.must_be_close_to -22.17333
      wpt.longitude.must_be_close_to -42.41256
      wpt.altitude.must_be_close_to 675.0, 0.5

      wpt = track.waypoints[1]
      wpt.latitude.must_be_close_to -22.17332
      wpt.longitude.must_be_close_to -42.41264
      wpt.altitude.must_be_close_to 673.0, 0.5
    end
  end
end

