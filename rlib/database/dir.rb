require "database/abstract"
require "fileutils"

class DirDatabase < AbstractEncDatabase
    JSON_ENDING = ".json"

    def initialize( conf, debug )
        super( 'dir', conf, debug )
		STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using directory based host lookup : "+ @config.key( 'dir.db' ) if( @debug )
    end

    def initdb()    	
    	if( @config['dir.db'] )
	    	FileUtils.mkdir_p( @config['dir.db'] ) if( not Dir.exists?( @config['dir.db'] ) )
	    else
    		raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Can not initialize db : "+@config['dir.db']+"\n"
	    end
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
    		
    		raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not find directory to scan #{dir}"+"\n"
    		
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
    			raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
    		end
    	else
    
    		raise ArgumentError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find config file #{filename}"+"\n"
        
    	end
        

    end

    def insert( profile, config )

        dir = @config.key( 'dir.db' )
        filename = dir+"/"+profile+".json"
        
        fd = File.new( filename, mode="w" )
        fd.write( config )
        fd.close()

    end
    
    def delete( what )
        dir = @config.key( 'dir.db' )
        filename = dir+"/"+what+JSON_ENDING
        
        if( File.symlink?( filename ) )
            File.unlink( filename ) 
        else
            File.unlink( filename ) if( File.exists?( filename ) )
        end    
    end
    
    def update( profile, config )
    end
    
    def fetch( profile )
        return load_profile( profile )
    end
    
    def list()
        dir = @config.key( 'dir.db' )
    	filelist = Hash.new()
    	filelist["profile"] = Array.new()
    	filelist["host"] = Array.new()
    	
    	
    	if Dir.exists?( dir )
    		Dir.foreach( dir ) do |filename| 
    			next if(  filename.match( /^\./ ) )

                if( File.symlink?( dir+"/"+filename ) )
                    realfile = File.readlink( dir+"/"+filename )
                    filelist["host"].push( [ filename.sub( /\.json/, "" ),  realfile.sub( /\.json/, "" ) ] )
                else
                    filename.sub!( /\.json/, "" )
    				filelist["profile"].push( filename )
				end
				
    		end
    	else
    		raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not find directory to scan #{dir}"+"\n"
    	end
    
    	return filelist    
    end
    

    def bind( hostname, profile )
        dir = @config.key( 'dir.db' )

        profile_file = dir+"/"+profile+JSON_ENDING
        host_file = dir+"/"+hostname+JSON_ENDING
      
        if( File.exists?( profile_file ) )
            File.symlink( profile_file, host_file )
            return [ profile_file, host_file ]
        else
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile} to bind with host #{hostname}"+"\n"
        end
    end
    
end
