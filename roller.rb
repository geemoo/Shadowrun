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
        
        @options = OptionParser.new()

        @options.on("--edge", "-e") {|val| edge = true }
        @options.on("--extended=THRESHOLD", "-x") do |val| 
            extended = true
            threshold = val.to_i()
        end
        @options.on("--help", "-h") {|val| puts @options.to_s(); exit; }

        @dice = @options.parse(ARGV)[0].to_i()
    
        if(edge)
            edge()
        elsif(extended)
            extended(threshold)
        else
            standard()
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
    
    def standard()
        begin
            result = roll( @dice )
            hits = result[0] + result[1]
            puts( "Hits:  #{hits}" )
            return hits
        rescue GlitchException
            puts($!.to_s())
        end
    end
    
    def edge()
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
                hits += result[0] + result[1]
            end
        rescue GlitchException
            retry
        end

        puts( "Hits:  #{hits}" )
        return hits
    end

    def extended(threshold)
        total_hits = 0
        rolls = 0
        
        begin
            while( total_hits < threshold )
                rolls += 1
                result = roll( @dice )
                total_hits += result[0] + result[1]
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
