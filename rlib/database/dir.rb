require "database/abstract"
require "fileutils"

class DirDatabase < AbstractEncDatabase
    JSON_ENDING = ".json"



    def initialize( conf, debug )
        super( 'dir', conf, debug )

    	if( @config.key?('dir.db') and not Dir.exists?( @config.key('dir.db') ) )
    		STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Initializing storage: "+ @config.key( 'dir.db' ) if( @debug )
	    	FileUtils.mkdir_p( @config.key('dir.db') ) 
	    end
        
		STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using directory based host lookup : "+ @config.key( 'dir.db' ) if( @debug )
    end

    ## Initialize the databsae structure.
    ## This module will initialize the directory path, i.e. it will create the directory found in the configuration.
    def initdb()    	
    	if( @config.key?('dir.db') )
	    	FileUtils.mkdir_p( @config.key('dir.db') ) if( not Dir.exists?( @config.key('dir.db') ) )
	    else
    		raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Can not initialize db : "+@config.key('dir.db')+"\n"
	    end
    end

    def connect( )
        return true
    end
    
    def terminate( )
        return true
    end
    
    ## Scan the enc directory for a pattern file
    # Returns list of files
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
    
    
    ## Loads the profile structure from file to
    def load_profile( name )
        return nil if ! name
        return nil if ! @config.key?( 'dir.db' )
    
    
        if( ! /\.json/.match( name ) )
            name += JSON_ENDING
        end
        
    	## 
    	filename = @config.key( 'dir.db' )+"/"+name
    	if( File.exists?( filename ) or File.symlink?( filename ) )		
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

    ##
    # Creates a profile with content config. 
    # Config must be in json format.
    def insert( profile, config )
    
        return false if( not config )
        
        dir = @config.key( 'dir.db' )
        filename = dir+"/"+profile+".json"
        
        begin
            fd = File.new( filename, mode="w" )
            fd.write( JSON.generate( config ) )
            fd.close()
        
            return true
            
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not copy profile #{profile} data to #{filenmae} : "+error.to_s+"\n"
        end
        
    end
    
    ## Deletes a host or profile
    def delete( what )
        
        return false if( not what )
        
        dir = @config.key( 'dir.db' )
        filename = dir+"/"+what+JSON_ENDING
        
        return false if( not File.exists?( filename ) )
        
        begin
            if( File.symlink?( filename ) )
                File.unlink( filename ) 
            else
                File.unlink( filename ) if( File.exists?( filename ) )
            end    
    
            return true
    
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not delete #{what}: "+error.to_s+"\n"
        end
    end
    
    
    ##
    # Updates a host or profile 
    def update( profile, config )

        return false if( not profile )
        return false if( not config )

        dir = @config.key( 'dir.db' )
        filename = dir+"/"+profile+".json"
        return nil if( not File.exists?( filename ) )
        
        begin
            File.unlink( filename )
            
            fd = File.new( filename, mode="w" )
            fd.write( JSON.generate( config ) )
            fd.close()
            
            return true
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not update profile #{profile} data with new data : "+error.to_s+"\n"
        end
    end
    
    ##
    # Alias for load_profile( profile )
    def fetch( profile )
        return load_profile( profile )
    end
    
    ##
    # Gets a list of profiles and hosts. Symbolic lists at considered to be host bindings and actual files are profiles.
    # Returns: hash of two keys containing individual lists lists, profile and host.
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
    

    ##
    # Returns a two element array, profile and the host file (symlink) is has created. 
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
