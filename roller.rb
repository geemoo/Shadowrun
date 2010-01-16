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
        attr :hits

        def initialize( hits )
            @hits = hits
        end

        def to_s()
            if( @hits <= 0 )
                return "CRITICAL GLITCH!!!"
            else
                return "Glitch (#{@hits})!"
            end
        end
    end
    
    def initialize()
        @maximum = 1000

        edge = false
        extended = false
        team = false

        threshold = 0
        assist = [ nil ]
        
        @options = OptionParser.new()

        @options.on("--edge", "-e", "Hits") {|val| edge = true }
        @options.on("--extended=THRESHOLD", "-x", "Intervals") do |val| 
            extended = true
            threshold = val.to_i()
        end
        @options.on("--max=MAXIMUM", "-m", "Limit hits to maximum per roll") {|val| @maximum = val.to_i(); }
        @options.on("--help", "-h", "--about", "This message") {|val| puts @options.to_s(); exit; }

        @dice = @options.parse(ARGV).sort.map! {|x| x.to_i(); }
    
        if(edge)
            puts(edge())
        elsif(extended)
            puts(extended(threshold))
        else
            puts(standard())
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

        if( (ones * 2) >= @dice[0] )
            raise GlitchException.new(fives + sixes)
        end
        return [ fives, sixes ]
    end

    # Garuantees that the input is <= @maximum
    def max(hits)
        if(hits > @maximum)
            return @maximum
        else
            return hits
        end
    end
    
    # Rolls a standard (non-edge, non-extended) test
    def standard()
        hits = 0
        begin
                team = 0
                begin
                        team = max(teamwork( @dice[0..-2] )) 
                rescue GlitchException #Must be Critical to get here
                        hits = hits - 1
                end
                result = roll( @dice[0] + team )
                hits = max(result[0] + result[1])
                return hits
        rescue GlitchException
                print($!.to_s())
                return ""
        end
    end
    
    # Rolls an edge test, which rerolls 6's recursively
    def edge()
        begin
                hits = 0
                team = 0
                begin
                        team = max(teamwork( @dice[0..-2] ))
                rescue GlitchException #Must be Critical to get here
                        hits = hits - 1
                end
                result = roll( @dice[0] + team ) # This is probably not what the rules intend
        rescue GlitchException
                print($!.to_s())
                return ""
        end

        hits = result[0] + result[1]

        begin
            until( result[1] <= 0 )
                result = roll( result[1] )
                hits = hits + max(result[0] + result[1])
            end
        rescue GlitchException
            retry
        end

        return hits
    end

    # Returns number of rolls (intervals) required to complete the test
    # or -1 if the number of rolls exceeds the original dice + 1
    def extended(threshold)
        total_hits = 0
        rolls = 0
        clone = @dice
        team = 0
        
        begin
            while( total_hits < threshold && clone[0] > 0 )
                begin
                        team = max(teamwork( @dice[0..-2] ))
                rescue GlitchException #Must be Critical to get here
                        hits = hits - 3
                end
                result = roll( clone[0] + team )
                total_hits = total_hits + max(result[0] + result[1])
                clone.map! {|d| d - 1;}
                rolls = rolls + 1
            end
        rescue GlitchException
            if($!.hits <= 0)
                return "#{$!.to_s()}   #{rolls}" 
            else
                total_hits = total_hits - ( rand(6) + 1 )
                retry
            end
        end

        if(rolls <= @dice[0])
                return rolls
        else
                return "Fail"
        end
    end

    # Returns the number of extra dice achieved by teamwork
    def teamwork(teammates)
        assist_dice = 0

        if( teammates != nil)
                teammates.each do |t|
                        begin
                                result = roll(t)
                        rescue GlitchException
                                if($!.hits > 0)
                                        retry
                                else 
                                        raise
                                end
                        end

                        assist_dice = assist_dice + result[0] + result[1]
                end
        end

        return assist_dice 
    end
    
end # Roller

roller = Roller.new()
