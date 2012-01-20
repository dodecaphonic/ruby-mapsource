# Defines the structure
module MapSource
  # Public: GDB header. Contains name of creator software, signature and
  # format version.
  class Header
    attr_accessor :created_by, :signed_by, :version
  end

  # Public: A Waypoint.
  class Waypoint
    attr_accessor :shortname, :latitude, :longitude, :altitude, :temperature, :depth, :notes, :creation_time, :proximity, :icon, :city, :state, :facility

    def initialize(latitude, longitude)
      @latitude = latitude
      @longitude = longitude
    end
  end

  # Public: A Track.
  class Track
    attr_reader :name, :color

    def initialize(name, color)
      @name = name
      @color = color
      @waypoints = []
    end

    def waypoints
      @waypoints.dup
    end

    def add_waypoint(wpt)
      @waypoints << wpt
    end

    def size
      @waypoints.size
    end

    def each
      @waypoints.each { |wpt| yield wpt if block_given? }
    end
  end
end
