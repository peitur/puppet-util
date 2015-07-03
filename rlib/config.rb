
require 'util'

class EncConfig
   
    attr_accessor :debug
    attr_reader :filename, :config
    
    def initialize( filename, debug = false )
        @filename = filename
        @debug = debug
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Loading configuration from #{@filename}") if @debug
        
        begin
            @config = EncUtil.load_json( @filename )
        rescue error
            raise "ERROR #{__FILE__}/#{__LINE__}:Could not load configuration #{filename}: "+error.to_s
        end

    end
    
    def key?( key )
        return @config.key?( key )
    end
   
    def key( key )
        return @config[key]
    end
   
    def key!(key, val)
        @config[key] = val
        return @config[key]
    end
    
    def to_s
        return "\"filenmae\"=>\"#{@filename}\", \"debug\"=>\"#{@debug}\", \"config\"=>\"#{@config}\""
    end
    
end