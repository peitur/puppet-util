
require 'util'
require 'config'
################################################################################
class AbstractEncDatabase
    
    
    attr_accessor :engine, :debug
    attr_reader :config, :db, :schema, :user, :password
    attr_reader :strict
    def initialize( engine, conf, debug = false )
        @debug = debug
        @engine = engine
        @config = conf
        
        if( @config.key?( "#{@engine}.db" ) )
            @db = @config.key( "#{@engine}.db" )
        end
        
    end
    
    def search( pattern )
        return nil
    end

    def profile( name )
        return nil
    end
    
    def db
        return @config["#{engine}.db"]
    end

end



################################################################################
class DirDatabase < AbstractEncDatabase

    def initialize( conf, debug )
        super( 'dir', conf, debug )
        
        
		STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using directory based host lookup : "+ @config.key( 'dir.db' ) if @debug
    end
        
    ## Scan the enc directory for a pattern file
    def search( pattern )
    	return nil if ! pattern
        return nil if ! @config.key?( 'dir.db' )

        dir = @config.key( 'dir.db' )
    	filelist = Array.new()
    	
    	if Dir.exists?( dir )
    		Dir.foreach( dir ) do |filename| 
    			if(  filename.match( /^\./ ) )
    				next
    			end	
    
    			if( /^#{pattern}#{JSON_ENDING}$/.match( filename ) )
    				filelist.push( filename )
    			end
    		end
    		
    	else
    		
    		STDERR.puts "ERROR #{__FILE__}/#{__LINE__}: Could not find directory to scan #{dir}" if @debug
    		return nil
    	end

    
    	return filelist
    end
    


    def load_profile( name )
        return nil if ! name
        return nil if ! @config.key?( 'dir.db' )
    
    
        if( ! /\.json/.match( name ) )
            name += JSON_ENDING
        end
        
    	## 
    	filename = @config.key( 'dir.db' )+"/"+name
    	if( File.exists?( filename ) )		
    		## Lets open it and parse it into a config object (hash)
    		begin
    
    			nodedata = JSON.load( File.open( filename ) )
    			if( @config != nil and nodedata != nil and nodedata.key?("include") )
    				include_profile = nodedata["include"]
    				
    				self.load_profile( include_profile ).each do |k,v|
    					if( ! nodedata.key?( k ) )
    						nodedata[k] = v
    					end
    				end
    				
    				STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Including #{include_profile}" if( @debug )
    				nodedata.delete( "include" )
    			end
    			return nodedata
    			
    		rescue => error  ## Catching everything this time, no need to be picky
    			
    			STDERR.puts "ERROR #{__FILE__}/#{__LINE__}: #{error} \n" if( @debug )
    
    			return nil
    		end
    	else
    		STDERR.puts "ERROR #{__FILE__}/#{__LINE__}: Could not find config file #{filename} \n" if( @debug )
    
    		return nil
    	end
        
        
        
    end
    
end

################################################################################
class FileDatabase < AbstractEncDatabase

    attr_accessor :path
    def initialize( conf, debug )
         super( 'file', conf, debug )
         
    end
    
    
    
end


################################################################################
class EncDatabase 


    attr_accessor :debug
    attr_reader :db
    def initialize( engine, conf, debug )
        @debug = debug

        case engine
            when "dir" 
                @db = DirDatabase.new( conf, debug )
                
            else
                STDERR.puts( "ERROR #{__FILE__}/#{__LINE__}: Requested access engine #{engine} not supported")
                throw "ERROR: unsupported engine"
                
        end
    
    end

    def search( pattern )
        
        return nil if( ! @db )
        return nil if( ! pattern )
        
        
        return @db.search( pattern )
    end
   
    def load_profile( name )
        return nil if( ! @db )
        return nil if( ! name )
        
        return @db.load_profile( name )
    end
   
    
end