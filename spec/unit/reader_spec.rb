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
end

