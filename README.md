[![Build Status](https://travis-ci.org/dodecaphonic/ruby-mapsource.png?branch=master)](https://travis-ci.org/dodecaphonic/ruby-mapsource)

ruby-mapsource is a library that allows ruby programs to read files created by Garmin's MapSource and BaseCamp.

# Usage

    gdb = MapSource.read('/path/to/gdb_file.gdb')
    # => #<MapSource::Reader:0x007fedfcb1b768>

    # Read waypoints
    gdb.waypoints.each { |wp|
      puts "#{wp.shortname} - (#{wp.latitude}, #{wp.longitude})"
    }

    # Read tracks
    gdb.tracks.each do |track|
      puts "#{track.name} has #{track.size} points"

      track.waypoints.each { |wp|
         puts "\t#{wp.shortname} - (#{wp.latitude}, #{wp.longitude})"
      }
    end

# TODO

 - read routes
 - comprehensive testing of different versions

# Thanks

[GPSBabel][1] - gdb.c was vital in understanding the format

[1]: http://www.gpsbabel.org/
