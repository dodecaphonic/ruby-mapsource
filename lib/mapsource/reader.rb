module MapSource
  class InvalidFormatError < StandardError; end
  class UnsupportedVersionError < StandardError; end

  # Public: GDB header. Contains name of creator software, signature and
  # format version.
  class Header
    attr_accessor :created_by, :signed_by, :version
  end

  # Public: A Waypoint.
  class Waypoint
    attr_reader :shortname, :latitude, :longitude, :altitude, :notes

    def initialize(shortname, latitude, longitude, altitude, proximity, notes)
      @shortname = shortname
      @latitude = latitude
      @longitude = longitude
      @altitude = altitude
      @proximity = proximity
      @notes = notes
    end
  end

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

    # Internal: Reads a waypoint record from the GDB.
    #
    # record - a binary string containing waypoint data.
    #
    # Returns waypoint.
    def read_waypoint(record)
      _, shortname, wptclass, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, lat, lon, alt, notes, prox = record.unpack('AZ*lZ*aaaaaaaaaaaaaaaaaaaaaallEZ*E')

      Waypoint.new shortname, semicircle_to_degrees(lat), semicircle_to_degrees(lon), alt, prox, notes
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
