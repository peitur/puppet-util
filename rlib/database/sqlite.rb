
require 'sqlite3'

require "database/abstract"
require "fileutils"

################################################################################
class SqliteDatabase < AbstractEncDatabase

	## Pease ensure that the sqlite3 package for ruby is installed
    
    @@profile_table = "enc_profiles"
    @@host_table = "enc_hosts"

    @@profile_id = "id"
    @@profile_name = "name"
    @@profile_value = "value"

    @@host_id = "id"    
    @@host_host = "host"
    @@host_profile_id = "profile_id"

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
	    
	    	handle.execute( "CREATE TABLE IF NOT EXISTS #{@@profile_table}( #{@@profile_id} INTEGER PRIMARY KEY AUTOINCREMENT, #{@@profile_name} TEXT UNIQUE, #{@@profile_value} TEXT )" )
	    	handle.execute( "CREATE TABLE IF NOT EXISTS #{@@host_table}( #{@@host_id} INTEGER PRIMARY KEY AUTOINCREMENT, #{@@host_profile_id} INTEGER, #{@@host_host} TEXT UNIQUE  )" )

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

        squery_search = "SELECT #{@@host_table}.#{@@host_host} as host, #{@@profile_table}.#{@@profile_name} as profile, #{@@profile_table}.#{@@profile_value} as value FROM #{@@profile_table} INNER JOIN #{@@host_table} ON #{@@host_table}.#{@@host_profile_id} = #{@@profile_table}.#{@@profile_id} WHERE host LIKE '#{pattern}'"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Searching SQL #{squery_search}\n" ) if( @debug )

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
        
        squery = "SELECT id,name,value FROM #{@@profile_table} WHERE #{@@profile_table}.#{@@profile_name} = '#{name}'"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Load profile SQL: #{squery}\n" ) if( @debug )    

        begin
            rsX = @dbhandle.execute( squery )
            if( rsX.length() == 0 )
                raise RuntimeError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile}"+"\n"
#                return false
            end

    		nodedata = JSON.parse( rsX[0]["value"] )

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
        iquery = "INSERT INTO #{@@profile_table}( #{@@profile_name}, #{@@profile_value} ) VALUES( '#{profile}', '#{config_json_str}' )"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Insert profile SQL: #{iquery}\n" ) if( @debug )    

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
        iquery_profile = "DELETE FROM #{@@profile_table} WHERE #{@@profile_name} = '#{profile}'"
        iquery_host = "DELETE FROM #{@@host_table} WHERE #{@@host_host} = '#{profile}'"

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Delete profile SQL: #{iquery_profile}\n" ) if( @debug )    
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Delete host SQL: #{iquery_host}\n" ) if( @debug )    


        iquery_xec = Array.new()

        begin

            squery_host    = "SELECT #{@@host_host} as name FROM #{@@host_table} WHERE name = '#{profile}'"
            squery_profile = "SELECT #{@@profile_name} as name FROM #{@@profile_table} WHERE name = '#{profile}'"
        
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Check Delete host SQL: #{squery_host}\n" ) if( @debug )    
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Check Delete profile SQL: #{squery_profile}\n" ) if( @debug )    


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
        iquery = "UPDATE #{@@profile_table} SET #{@@profile_value} = '#{config_json_str}' WHERE #{@@profile_name} = '#{profile}' "
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Update profile SQL: #{iquery}\n" ) if( @debug )    

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
        
        squery_profile = "SELECT #{@@profile_name} FROM #{@@profile_table} ORDER BY #{@@profile_name}"
        squery_host = "SELECT #{@@host_table}.#{@@host_host} as host, #{@@profile_table}.#{@@profile_name} as profile, #{@@profile_table}.#{@@profile_value} as value FROM #{@@profile_table} INNER JOIN #{@@host_table} ON #{@@host_table}.#{@@host_profile_id} = #{@@profile_table}.#{@@profile_id}"
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: List profile SQL: #{squery_profile}\n" ) if( @debug )    
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: List host SQL: #{squery_host}\n" ) if( @debug )    


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
            squery_bind = "SELECT #{@@profile_id},#{@@profile_name} FROM #{@@profile_table} WHERE #{@@profile_name} ='#{profile}'"
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Bind Check profile SQL: #{squery_bind}\n" ) if( @debug )    
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
            iquery_bind = "INSERT INTO #{@@host_table}( #{@@host_host}, #{@@host_profile_id} ) VALUES( '#{hostname}','#{profile_id}')"
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
