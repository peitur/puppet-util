
require 'sqlite3'

require "database/abstract"
require "fileutils"

################################################################################
class SqliteDatabase < AbstractEncDatabase

	## Pease ensure that the sqlite3 package for ruby is installed
    
    @dbhandle = nil
    def initialize( conf, debug )
         super( 'sqlite', conf, debug )
         
         begin
    		
    		if( not File.exists?( @db ) )
    			initdb()
    		end

            @dbhandle = SQLite3::Database.open( @db )
            @dbhandle.results_as_hash = true
            
            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using SQLite based host lookup : "+ @config.key( 'sqlite.db' ) if( @debug )
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
        end
        
    end
    
    def terminate( )
        if( @dbhandle )
            @dbhandle.close()
            return true
        end
        
        return false
    end
    
    def initdb( )
    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Initializing dbschema for sqlite : #{@db}" if( @debug )

    	if( not Dir.exists?( File.dirname( @db ) ) )
	    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Creating home directory for sqlite : #{@db}" if( @debug )

    		FileUtils.mkdir_p( File.dirname( @db ) )
    	end

		begin

	    	STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Creating tables for sqlite : #{@db}" if( @debug )

	    	SQLite3::Database.new( @db )
	    	handle = SQLite3::Database.open( @db )
	    
	    	handle.execute( "CREATE TABLE IF NOT EXISTS enc_profiles( id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT UNIQUE, value TEXT )" )
	    	handle.execute( "CREATE TABLE IF NOT EXISTS enc_hosts( id INTEGER PRIMARY KEY AUTOINCREMENT, profile_id INTEGER, host TEXT UNIQUE  )" )

	    	handle.close()
    
		rescue SQLite3::Exception => error
		    
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
		    
		ensure
		   	handle.close if handle
		end

    	return true
    end



    def dropdb()
        
        return true
    end


    def search( pattern )
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Searching for #{pattern}\n" ) if( @debug )

        return nil if( not pattern )

        squery_search = "SELECT enc_hosts.host as host, enc_profiles.name as profile, enc_profiles.value as value FROM enc_profiles INNER JOIN enc_hosts ON enc_hosts.profile_id = enc_profiles.id WHERE enc_hosts.host LIKE '#{pattern}'"
        
        result = Array.new()

        begin
            rsX = @dbhandle.execute( squery_search )
            rsX.each do |row|
                result.push( row['profile'] )
            end            
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Search profile #{pattern} failed: "+error.to_s+"\n"
        end

        return result
    end



    def load_profile( name )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Loading profile #{name}\n" ) if( @debug )

        return false if( not name )
        
        squery = "SELECT id,name,value FROM enc_profiles WHERE enc_profiles.name = '#{name}'"
    
        begin
            rsX = @dbhandle.execute( squery )
            if( rsX.length() == 0 )
                raise RuntimeError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile}"+"\n"
#                return false
            end

    		nodedata = JSON.parse( rsX[0]["value"] )

    		if( @config != nil and nodedata != nil and nodedata.key?("include") )
    			include_profiles = nodedata["include"].class.name == "String" ? [nodedata["include"]] : nodedata["include"]

                include_profiles.each do |include_profile|
    			
        			self.load_profile( include_profile ).each do |k,v|
        				if( ! nodedata.key?( k ) )
        					nodedata[k] = v
        				end
        			end

                end
    			
    			STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Including #{include_profile}" if( @debug )
    			nodedata.delete( "include" )
    		end
    
    		return nodedata
            
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not get profile #{name} : "+error.to_s+"\n"
        end

    end
    
    def fetch( profile )
        return self.load_profile( profile )
    end    
    
    def db
        return @config["#{engine}.db"]
    end


    def insert( profile, config )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Inserting profile #{profile} with config "+config.to_s+" \n" ) if( @debug )

        return false if( not profile )
        return false if( not config )
        
        config_json_str = JSON.generate( config )
        iquery = "INSERT INTO enc_profiles(name, value) VALUES( '#{profile}', '#{config_json_str}' )"
        begin
            @dbhandle.transaction
            @dbhandle.execute( iquery )
            @dbhandle.commit
            
            return true
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not register profile #{profile} : "+error.to_s+"\n"
        end
        
    end
    
    def delete( profile )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Deleting profile #{profile} \n" ) if( @debug )

        return false if( not profile )

        ## Since a false is expected when no profile is found to delete, an extra check is needed.
        ## This should be changed
        iquery_profile = "DELETE FROM enc_profiles WHERE name = '#{profile}'"
        iquery_host = "DELETE FROM enc_hosts WHERE host = '#{profile}'"
        iquery_xec = Array.new()

        begin

            squery_host    = "SELECT host as name FROM enc_hosts WHERE name = '#{profile}'"
            squery_profile = "SELECT name as name FROM enc_profiles WHERE name = '#{profile}'"
        
            rsH = @dbhandle.execute( squery_host )
            rsP = @dbhandle.execute( squery_profile )
            rsN = [rsH.length, rsP.length]

            iquery_xec.push( iquery_profile ) if( rsP.length() > 0 )
            iquery_xec.push( iquery_host )    if( rsH.length() > 0 )

            return false  if( iquery_xec.length == 0 )
        rescue => error
            STDERR.puts( "ERROR #{__FILE__}/#{__LINE__}: Nothing found to delete "+rsN.to_s+": "+error.to_s+"\n" ) if( @debug )
            return false
        end


        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Deleting query: "+iquery_xec.to_s()+"\n" ) if( @debug )
        begin
            iquery_xec.each do |iquery|
                @dbhandle.transaction
                @dbhandle.execute( iquery )
                @dbhandle.commit
            end

            return true
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not delete #{profile}: "+error.to_s+"\n"    
        end
        
    end
    
    def update( profile, config )
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Updating profile #{profile} with config "+config.to_s+" \n" ) if( @debug )

        return false if( not profile )
        return false if( not config )
        
        config_json_str = JSON.generate( config )
        iquery = "UPDATE enc_profiles SET value = '#{config_json_str}' WHERE name = '#{profile}' "
        begin
            @dbhandle.transaction
            @dbhandle.execute( iquery )
            @dbhandle.commit
            
            return true
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not update profile #{profile} : "+error.to_s+"\n"
        end
    end
    

    
    def list()
        
        squery_profile = "SELECT name FROM enc_profiles ORDER BY name"
        squery_host = "SELECT enc_hosts.host as host, enc_profiles.name as profile FROM enc_profiles INNER JOIN enc_hosts ON enc_hosts.profile_id = enc_profiles.id"
        
        result = Hash.new()
        result['profile'] = Array.new()
        result['host'] = Array.new()    

        ## First just get all unique profiles
        begin
            rsX = @dbhandle.execute( squery_profile )
            rsX.each do |row|
                result['profile'].push( row['name'] )
            end            
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Listing profile list failed: "+error.to_s+"\n"
        end

        ## Get all hosts with their corresponding profiles
        begin
            rsX = @dbhandle.execute( squery_host )
            rsX.each do |row|
                result['host'].push( [row['host'], row['profile']] )
            end            
        rescue => error
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Listing profile list failed: "+error.to_s+"\n"
        end


        return result
        
    end
    
    def bind( hostname, profile )
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Binidng profile #{profile} to host #{hostname} \n" ) if( @debug )
        
        return nil if( not hostname )
        return nil if( not profile )
        
        profile_id = nil
        begin
            squery_bind = "SELECT id,name FROM enc_profiles WHERE name ='#{profile}'"
            rsX = @dbhandle.execute( squery_bind )
            
            if( rsX.length() == 0 )
                raise RuntimeError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile}"+"\n"
#                return false
            end

    		profile_id = rsX[0]["id"]
            
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: SQL error looing for profile #{profile} to bind to host #{hostname}: "+error.to_s+"\n"    
        end
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Found binidng profile #{profile} " ) if( @debug )
        
        return nil if( not profile_id )

        ## If profile query returns nothing, raise exceptions, can not bind to a profile that does not exist.
        
        if( profile_id )
            iquery_bind = "INSERT INTO enc_hosts( host, profile_id ) VALUES( '#{hostname}','#{profile_id}')"

            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Binding SQL: #{iquery_bind} \n" ) if( @debug )

            begin
    
                @dbhandle.transaction
                @dbhandle.execute( iquery_bind )
                @dbhandle.commit
                
                return [profile, hostname]
                
            rescue => error
                raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not delete #{profile}: "+error.to_s+"\n"    
            end
        end
        
        return nil
    end
    

end
