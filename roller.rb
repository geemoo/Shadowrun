require 'optparse'
    
class Roller
    def initialize()
        @edge = false
        @extended = false
        
        @options = OptionParser.new()

        @options.on("--edge", "-e") {|val| @edge = true }
        @options.on("--extended", "-x") {|val| @extended = true }
        @options.on("--help", "-h") {|val| puts @options.to_s(); exit; }

        @dice = @options.parse(ARGV)[0].to_i()
    end

    # rolls random dice
    # return an array of [ fives, sixes, ones ] rolled
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
        return [ fives, sixes, ones ]
    end

    def output(ones, hits)
        if( (ones * 2) >= @dice )
            if( hits <= 0 )
                puts("CRITICAL GLITCH!!!")
            else
                puts("Glitch!")
            end
        else
            puts(hits)
        end
    end
    
    def standard()
        result = roll( @dice )
        output( result[2], result[0] + result[1] )
    end
    
    def edge()
        result = roll( @dice )
        hits = 0
        ones = 0

        until( result[1] <= 0 )
            hits += result[0] + result[1]
            ones += result[2]
            result = roll( result[1] )
        end

        output(ones, hits)
    end
    
    roller = Roller.new()

    if(@edge)
        puts("EDGE")
        roller.edge()
    elsif(@extended)
        roller.extended()
    else
        roller.standard()
    end
end # Roller
