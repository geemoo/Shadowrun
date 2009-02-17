#!/usr/bin/ruby

#  This program is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#  
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#  
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# Copyright Steven Lusk, 2009

require 'optparse'
 
class Roller

    class GlitchException < RuntimeError
        attr :critical

        def initialize( critical )
            @critical = critical
        end

        def to_s()
            if( critical )
                return "CRITICAL GLITCH!!!"
            else
                return "Glitch!"
            end
        end
    end
    
    def initialize()
        edge = false
        extended = false
        threshold = 0
        
        maximum = 1000
        
        @options = OptionParser.new()

        @options.on("--edge", "-e") {|val| edge = true }
        @options.on("--extended=THRESHOLD", "-x") do |val| 
            extended = true
            threshold = val.to_i()
        end
        @options.on("--max=MAXIMUM_HITS", "-m") {|val| maximum = val.to_i(); }
        @options.on("--help", "-h") {|val| puts @options.to_s(); exit; }

        @dice = @options.parse(ARGV)[0].to_i()
    
        if(edge)
            edge(maximum)
        elsif(extended)
            extended(threshold, maximum)
        else
            standard(maximum)
        end
    end

    # rolls random dice
    # return an array of [ fives, sixes ] rolled
    def roll(dice)
        fives = 0
        sixes = 0
        ones = 0
    
        dice.times() do |i|
            case rand(6)
            when 0
                sixes = sixes.next()
            when 1
                fives = fives.next()
            when 2
                ones = ones.next()
            end
        end

        if( (ones * 2) >= @dice )
            if( (fives + sixes) <= 0 )
                raise GlitchException.new(true) 
            else
                raise GlitchException.new(false) 
            end
        end
        return [ fives, sixes ]
    end

    def max(maximum, hits)
        if(hits > maximum)
            return maximum
        else
            return hits
        end
    end
    
    def standard(maximum)
        begin
            result = roll( @dice )
            hits = max(maximum, result[0] + result[1])
            puts( "Hits:  #{hits}" )
            return hits
        rescue GlitchException
            puts($!.to_s())
        end
    end
    
    def edge(maximum)
        begin
            result = roll( @dice )
        rescue GlitchException
            puts($!.to_s())
            return 0
        end

        hits = result[0] + result[1]

        begin
            until( result[1] <= 0 )
                result = roll( result[1] )
                hits += max(maximum, result[0] + result[1])
            end
        rescue GlitchException
            retry
        end

        puts( "Hits:  #{hits}" )
        return hits
    end

    def extended(threshold, maximum)
        total_hits = 0
        rolls = 0
        
        begin
            while( total_hits < threshold )
                rolls += 1
                result = roll( @dice )
                total_hits += max(maximum, result[0] + result[1])
            end
            output = "Intervals:  #{rolls}"

        rescue GlitchException
            if($!.critical)
                output = "#{$!.to_s()}   Intervals:  #{rolls}  Hits:  #{total_hits}"
            else
                total_hits -= ( rand(6) + 1 )
                retry
            end
        end

        if( rolls <= @dice * @dice )
            puts( output )
        else
            puts( "#{output}!" )
        end
    end
    
end # Roller

roller = Roller.new()
