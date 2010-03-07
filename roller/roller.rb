#!/usr/bin/ruby1.9 -w

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
# Copyright Steven Lusk, 2009, 2010

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
        @verbose = false
        @dramatic = nil
        @abort = 0

        switch = "roll"
        leader = false

        threshold = 0
        assist = [ ]
        leader_dice = 0

        @options = OptionParser.new()

        @options.banner = "roller is a dice rolling program for the Shadowrun 20th Anniversary game system. 
  Usage: roller [options] dice | diceDfacets
  Options:"
        @options.on("--max MAXIMUM", "-m", "Limit hits to MAXIMUM per roll", Integer) {|val| @maximum = val; }
        @options.on("--edge", "-e", "Result in hits.") {|val| switch = "edge" }
        @options.on("--extended THRESHOLD", "-x", "Result in intervals.", Integer) do |val| 
            switch = "extended"
            threshold = val
        end
        @options.on("--unlimited THRESHOLD", "-u", "Unlimited extended.  Result in intervals.", Integer) do |val| 
            switch = "unlimited"
            threshold = val
        end
        @options.on("--abort [POOL]", "-a", "Abort any roll with a pool less than or equal to POOL.", Integer) do |val| 
                if(val == nil)
                        @abort = 2
                else
                        @abort = val
                end
        end
        @options.on("--leader DICE", "-l", "Explicit Leader.", Integer) do |val| 
                leader = true
                leader_dice = val
        end
        @options.on("--drama [TIME]", "-d", "Wait for 1 to TIME (default 5.0) seconds between rolls.", Float) do |val| 
                if(val == nil)
                        @dramatic = 5.0
                else
                        @dramatic = val
                end
        end
        @options.on("--verbose", "-v", "Report every roll.") {|val| @verbose = true; }
        @options.on("--help", "-h", "--about", "This message.") {|val| puts @options.to_s(); exit; }

        # Here we handle the ugliness of "doing the right thing"
        # with either ## or ##d##
        # This code is fragile, and will break if 
        # the two formats are combined in the same command line
        @dice = @options.parse(ARGV).map! do |x| 
                regex = Regexp.new('([0-9]+)([Dd]([0-9]+))?')
                matches = regex.match(x)
                if(matches[2] != nil)
                        switch = "facets"
                        die = matches[1].to_i()
                        facet = matches[3].to_i()
                        # Return an array, which will be flatened shortly
                        [die, facet]
                else
                        matches[1].to_i()
                end
        end
        @dice = @dice.flatten.sort

        if(leader) 
                @dice.push(leader_dice)
        end

        if((@dice.length() < 1) && (switch != "roll"))
                puts("Dice pool not supplied, error")
                puts(@options.to_s())
                exit
        end
    
        case switch

        when "edge"
            puts(edge())
        when "extended"
            puts(extended(threshold) { @dice.map! {|d| d - 1;}; } )
        when "unlimited"
            puts(extended(threshold) { })
        when "facets"
            puts(facets())
        when "roll"
            puts(standard())
        else
            puts("Error:  #{ARGV}")
        end
    end

    # rolls random dice
    # return an array of [ fives, sixes ] rolled
    def roll(dice)
        fives = 0
        sixes = 0
        ones = 0
        display = 0

        output = [ ]
    
        if(dice > @abort)
                dice.times() do |i|
                        display = rand(6)

                        output.push(display + 1)

                        case display
                        when 5
                                sixes = sixes.next()
                        when 4
                                fives = fives.next()
                        when 0
                                ones = ones.next()
                        end
                end
                if(@dramatic != nil)
                        sleep(rand(@dramatic))
                        put(".")
                end
        end

        if(@verbose)
                puts(output.sort.to_s())
        end

        if( (ones * 2) >= dice)
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
                team = max(teamwork( @dice[0..-2] ) { hits = hits - 1 } )
                result = roll( @dice.last() + team )
                hits = max(result[0] + result[1])
                return hits
        rescue GlitchException
                print($!.to_s())
                return ""
        end
    end
    
    # Rolls an edge test, which rerolls 6's recursively
    def edge()
        # Bootstrap a standard test
        hits = 0 
        begin
                team = max(teamwork( @dice[0..-2] ) { hits = hits - 1 } )
                result = roll( @dice.last() + team ) # This is probably not what the rules intend
        rescue GlitchException
                print($!.to_s())
                return ""
        end

        hits = result[0] + result[1]

        # Reroll 6's recursively for Edge
        # Ignore glitches because Catalyst told me so when asked by email
        begin
            until( result[1] <= 0 )
                result = roll( result[1] )
                hits += max(result[0] + result[1])
            end
        rescue GlitchException
            retry
        end

        return hits
    end

    # Returns number of rolls (intervals) required to complete the test
    # or -1 if the number of rolls exceeds the original dice + 1
    def extended(threshold)
        hits = 0
        rolls = 0

        begin
            # @dice.list() is a synonym for Leader
            while( hits < threshold && @dice.last() > @abort && hits >= 0)
                rolls += 1
                # If this is a teamwork test, roll team dice
                # All team members are limited by the leaders skill (--max), if provided
                # Critical glitches will reduce net hits by 3
                team = max(teamwork( @dice[0..-2] ) { hits = hits -3 } )
                # Do a standard roll, adding the team hits to Leader
                result = roll( @dice.last() + team )
                # Sum the hits
                hits += max(result[0] + result[1])
                # Reduce the dice pools if using the extended test time restriction
                # (normal extended tests should do this)
                yield
            end
        rescue GlitchException
            if($!.hits <= 0)
                return "#{$!.to_s()}   #{rolls}" 
            else
                hits -=  rand(6) + 1 
                if( hits <= 0 )
                        return "Fail (#{rolls})"
                else
                        retry
                end
            end
        end

        if(@verbose)
                puts("Hits: #{hits}")
        end

        if(hits >= threshold)
                return rolls
        else
                return "Fail (#{rolls})"
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
                                if($!.hits < 1)
                                        # Critical glitch
                                        # Let the caller modify it's own variable
                                        yield
                                        result = [0, 0]
                                else
                                        # Ignore regular glitches;
                                        # do this by restarting the loop.  
                                        # Harmless.
                                        retry
                                end
                        end

                        assist_dice += result[0] + result[1]
                end
        end

        return assist_dice 
    end

    def facets()
        output = [ ]

        @dice[0].times() do |i|
                output.push(rand(@dice[1]) + 1)
        end
        
        if(@dramatic != nil)
                sleep(rand(@dramatic))
                put(".")
        end

        puts(output.sort.to_s())
    end
    
end # Roller

roller = Roller.new()
