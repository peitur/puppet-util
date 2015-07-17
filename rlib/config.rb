
require 'util'

class EncConfig
   
   DEFAULT_ENV = "production"
   DEFAULT_CT = "parameters"
   DEFAULT_DEBUG = false
   DEFAULT_MATCH = "strict"
   DEFAULT_ENGINE = "db"
 
   
    @@defaults = {
       'enc.env'   => { 'value' => DEFAULT_ENV, 'desc' => "Using Puppet environment." },
       'enc.ctype' => { 'value' => DEFAULT_CT, 'desc' => "Configuration type to use when only one (classes or parameters) is needed." },
       'enc.debug' => { 'value' => DEFAULT_DEBUG, 'desc' => "Enable debugging. Only use when running manually."},
       'enc.match' => { 'value' => DEFAULT_MATCH, 'desc' => "How strict the puppet hose mapping should be when provisioning hosts. Strict will stop all output if host is not found."},
       'db.engine' => { 'value' => DEFAULT_ENGINE, 'desc' => "Profile lookup method (engine) to use when getting configuration." },
       'dir.db'    => { 'value' => "enc", 'desc' => "Direrctory path." },
       'psql.host' => { 'value' => '127.0.0.1', 'desc' => "" },
       'psql.db'   => { 'value' => "puppet_enc", 'desc' => "" },
       'sqlite.db' => { 'value' => "", 'desc' => "SQLite database path" }
       
    }
   
    attr_accessor :debug
    attr_reader :filename, :config
    
    def initialize( filename, debug = false )
        @filename = filename
        @debug = debug
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Loading configuration from #{@filename}") if( @debug )
        
        begin
            @config = EncUtil.load_json( @filename )

            @config['enc.env'] = DEFAULT_ENV if( not @config.key?( 'enc.env') )
            @config['enc.ctype'] = DEFAULT_CT if( not @config.key?( 'enc.ctype') )
            @config['enc.debug'] = DEFAULT_DEBUG if( not @config.key?( 'enc.debug') )
            @config['enc.match'] = DEFAULT_MATCH if( not @config.key?( 'enc.match') )
            @config['enc.engine'] = DEFAULT_ENGINE if( not @config.key?( 'enc.engine') )

        rescue error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not load configuration #{filename}: "+error.to_s+"\n"
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
    
    def default( key )
        
        if( @@defaults.key?( key ) )
            data = @@defaults[ key ]
            return data[ 'value' ]
        end
        
        return nil
    end
    
    def options( )
        return @@defaults.keys()
    end
    
    def to_s
        return "\"filenmae\"=>\"#{@filename}\", \"debug\"=>\"#{@debug}\", \"config\"=>\"#{@config}\""
    end
    
end