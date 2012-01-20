$: << File.dirname(__FILE__) + '/../lib'

require 'bundler/setup'
require 'minitest/autorun'
require 'mocha'

require 'mapsource'

module MapSource::Spec
  # Internal: Creates a basic mock object containing expectations for a part of
  # (or all of) the header. How much is created is determined by the _options_
  # hash.
  #
  # options - a hash of options. Currently supports ":before" and the following
  #   states:
  #     - :start - before expecting on the first string in the file
  #     - :version - before expectations regarding the version
  #     - :creator - before expectations regarding the creator of the file
  #     - :signer - before expectations regarding the signer of the file
  #
  # Returns an array with a mocha mock object and a mocha sequence object.
  def create_basic_valid_state(options={ before: nil })
    gdb_file = mock('gdb')
    header = sequence('parsing')

    unless options[:before] == :start
      gdb_file.expects(:read).in_sequence(header).with(6).returns "MsRcf\x00"
    else
      return [gdb_file, header]
    end

    unless options[:before] == :version
      reclen = mock('reclen')
      reclen.expects(:unpack).with('l').returns [2]
      gdb_file.expects(:read).in_sequence(header).with(4).returns reclen

      gdb_file.expects(:read).in_sequence(header).with(3).returns "Dm\x00"
    else
      return [gdb_file, header]
    end

    unless options[:before] == :creator
      reclen = mock('reclen 2')
      reclen.expects(:unpack).with('l').returns [27]
      gdb_file.expects(:read).in_sequence(header).with(4).returns reclen

      creator = mock('creator')
      creator.expects(:unpack).with('Z*').returns ["Ae\u0002SQA"]
      gdb_file.expects(:read).in_sequence(header).with(28).returns creator
    else
      return [gdb_file, header]
    end

    unless options[:before] == :signer
      gdb_file.expects(:read).in_sequence(header).with(10).returns "MapSource\x00"
    else
      return [gdb_file, header]
    end

    [gdb_file, header]
  end

  SAMPLE_TRACK = File.dirname(__FILE__) + '/assets/track.bin'
end

include MapSource::Spec
