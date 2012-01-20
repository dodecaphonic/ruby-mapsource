module MapSource
  class InvalidFormatError < StandardError; end
  class UnsupportedVersionError < StandardError; end

  # Public: Parses GDB files and extracts waypoints, tracks and routes.
  #
  # Examples:
  #
  #   reader = MapSource::Reader.new(open('around_the_world.gdb'))
  #   reader.waypoints
  #   # => [MapSource::Waypoint<...>, ...]
  class Reader
    # Public: Range of format versions supported.
    SUPPORTED_VERSIONS = (1..3)

    attr_reader :header, :waypoints

    # Public: Creates a Reader.
    #
    # gdb - An IO object pointing to a GDB.
    def initialize(gdb)
      @gdb = gdb
      @header = read_header

      @parsed = false
    end

    # Public: Read waypoints from file.
    #
    # Returns a list of waypoints.
    def waypoints
      read_data
      @waypoints
    end

    def tracks
      read_data
      @tracks
    end

    private
    # Internal: Reads data from the GDB file.
    #
    # Returns list of waypoints, list of tracks, list of routes.
    def read_data
      return if @parsed

      @waypoints = []
      @tracks = []
      @routes = []

      while true
        len = @gdb.read(4).unpack('l').shift
        record = @gdb.read(len + 1)

        case record
        when /^W/
          @waypoints << read_waypoint(record)
        when /^T/
          @tracks << read_track(record)
        when /^V/
          break
        else
        end
      end

      @parsed = true
    end

    # Internal: Converts coordinates in semicircles to degrees.
    #
    # v - coordinate as semicircle
    #
    # Returns coordinate in degrees.
    def semicircle_to_degrees(v)
      (v.to_f / (1 << 31)) * 180.0
    end

    # Internal: Reads a waypoint record from the GDB.
    #
    # record - a binary string containing waypoint data.
    #
    # Returns waypoint.
    def read_waypoint(record)
      io = StringIO.new(record)

      read_char io
      shortname = read_string(io)
      wptclass = read_int(io)

      read_string(io)
      io.read 22 # skip 22 bytes

      lat = semicircle_to_degrees(read_int(io))
      lon = semicircle_to_degrees(read_int(io))

      wpt = Waypoint.new(lat, lon)
      wpt.shortname = shortname

      if read_char(io) == 1
        alt = read_double(io)

        wpt.altitude = alt if alt < 1.0e24
      end

      wpt.notes = read_string(io)
      wpt.proximity = read_double(io) if read_char(io) == 1

      read_int io # display
      read_int io # color, not implemented

      wpt.icon = read_int(io)
      wpt.city = read_string(io)
      wpt.state = read_string(io)
      wpt.facility = read_string(io)

      wpt.depth = read_double(io) if read_char(io) == 1

      wpt
    end

    def read_track(record)
      header = record.unpack('AZ*all')
      _, name, _, color, npoints = *header
      contents = record.sub(/^#{Regexp.quote(header.pack('AZ*all'))}/, '')

      track = Track.new(name, Color::from_index(color))
      io = StringIO.new(contents)

      0.upto(npoints - 1) do
        lat = semicircle_to_degrees(read_int(io))
        lon = semicircle_to_degrees(read_int(io))

        wpt = Waypoint.new(lat, lon)

        if read_char(io) == 1
          alt = read_double(io)
          wpt.altitude = alt if alt < 1.0e24
        end

        wpt.creation_time = read_int(io) if read_char(io) == 1
        wpt.depth = read_double(io) if read_char(io) == 1
        wpt.temperature = read_double(io) if read_char(io) == 1

        track.add_waypoint wpt
      end

      track
    end

    def read_string(io)
      str = ''

      while c = io.read(1)
        break if c == "\x00"
        str += c
      end

      str
    end

    def read_int(io)
      io.read(4).unpack('l').shift
    end

    def read_double(io)
      io.read(8).unpack('E').shift
    end

    def read_char(io)
      io.read(1).unpack('c').shift
    end

    # Internal: Reads a GDB's header to determine the version being parsed, its creator
    # and signer.
    #
    # Returns a properly filled header.
    # Raises MapSource::InvalidFormatError if it's not a GDB file.
    # Raises MapSource::InvalidFormatError if GDB is malformed.
    # Raises MapSource::UnsupportedVersionError if file format version is not supported.
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
