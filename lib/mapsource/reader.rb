require 'ostruct'

module MapSource
  class InvalidFormatError < StandardError; end
  class UnsupportedVersionError < StandardError; end

  class Header
    attr_accessor :created_by, :signed_by, :version
  end

  class Reader
    SUPPORTED_VERSIONS = (1..3)

    attr_reader :header, :waypoints

    # TODO: determine who should close this IO object
    def initialize(gdb)
      @gdb = gdb
      @header = read_header

      @parsed = false
    end

    def waypoints
      read_data unless @parsed

      @waypoints
    end

    private
    # Private: After read_header, receives the IO object set at the point where data
    # can be read. It determines per record what should be parsed and returns the
    # right structures.
    #
    # Returns list of waypoints, list of tracks, list of routes.
    def read_data
      @waypoints = []
      @tracks = []
      @routes = []

      while true
        len = @gdb.read(4).unpack('l').shift
        record = @gdb.read(len + 1)

        case record
        when /^W/
          @waypoints << read_waypoint(record)
        when /^V/
          break
        else
        end
      end

      @parsed = true
    end

    def semicircle_to_degrees(v)
      (v.to_f / (1 << 31)) * 180.0
    end

    # Private: Reads a waypoint record from the GDB.
    #
    # Returns waypoint.
    def read_waypoint(record)
      waypoint = OpenStruct.new
      _, shortname, wptclass, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, lat, lon, alt, notes, prox = record.unpack('AZ*lZ*aaaaaaaaaaaaaaaaaaaaaallEZ*E')
      waypoint.shortname = shortname
      waypoint.latitude = semicircle_to_degrees(lat)
      waypoint.longitude = semicircle_to_degrees(lon)
      waypoint.altitude = alt if alt < 1.0e24
      waypoint.proximity = prox
      waypoint.notes = notes

      waypoint
    end

    # Private: Reads a GDB's header to determine the version being parsed, its creator
    # and signer.
    #
    # Returns a properly filled header.
    def read_header
      header = Header.new

      mscrf = @gdb.read(6).unpack('A*').shift

      raise InvalidFormatError, "Invalid gdb file" if mscrf != 'MsRcf'

      record_length = @gdb.read(4).unpack('l').shift
      buffer = @gdb.read(record_length + 1)

      raise InvalidFormatError, "Invalid gdb file" if buffer[0] != ?D
      gdb_version = buffer[1].getbyte(0) - ?k.getbyte(0) + 1

      raise UnsupportedVersionError, "Unsupported version: #{gdb_version}. Supported versions are #{SUPPORTED_VERSIONS.to_a.join(', ')}" if !SUPPORTED_VERSIONS.member?(gdb_version)

      header.version = gdb_version

      record_length = @gdb.read(4).unpack('l').shift
      buffer = @gdb.read(record_length + 1)
      creator = buffer.unpack('Z*').shift

      header.created_by = if creator =~ /SQA$/
                            'MapSource'
                          elsif creator =~ /neaderhi$/
                            'MapSource BETA'
                          end

      signer = @gdb.read(10)
      signer += @gdb.read(1) until signer =~ /\x00$/

      signer = signer.unpack('Z*').shift

      if signer !~ /MapSource|BaseCamp/
        raise InvalidFormatError, "Unknown file signature: #{signer}"
      end

      header.signed_by = signer

      header
    end
  end
end
