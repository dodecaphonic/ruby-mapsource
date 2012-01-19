module MapSource
  # Public: A Color attributed to a Track, Route or Waypoint.
  class Color
    attr_reader :name, :r, :g, :b

    def initialize(name, r=-1, g=-1, b=-1)
      @name = name
      @r = @r
      @g = @g
      @b = @b
    end

    # Public: Converts GDB color index to color object.
    #
    # idx - GDB index
    #
    # Returns Color corresponding to index.
    def self.from_index(idx)
      COLORS[idx] || COLORS.first
    end
  end

  # Public: A set of default colors.
  COLORS = [
            Color.new('Unknown'),
            Color.new('Black', 0, 0, 0),
            Color.new('DarkRed', 139, 0, 0),
            Color.new('DarkGreen', 0, 100, 0),
            Color.new('DarkYellow', 139, 139, 0),
            Color.new('DarkBlue', 0, 0, 139),
            Color.new('DarkMagenta', 139, 0, 139),
            Color.new('DarkCyan', 0, 139, 139),
            Color.new('LightGray', 211, 211, 211),
            Color.new('DarkGray', 169, 169, 169),
            Color.new('Red', 255, 0, 0),
            Color.new('Green', 0, 255, 0),
            Color.new('Yellow', 255, 255, 0),
            Color.new('Blue', 0, 0, 255),
            Color.new('Magenta', 255, 0, 255),
            Color.new('Cyan', 0, 255, 255),
            Color.new('White', 255, 255, 255),
            Color.new('Transparent')
           ]
end
