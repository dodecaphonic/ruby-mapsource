$: << File.dirname(__FILE__) + '/../lib'

require 'bundler/setup'
require 'minitest/autorun'
require 'mocha'

require 'mapsource'

module MapSource::Spec
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
end

include MapSource::Spec
