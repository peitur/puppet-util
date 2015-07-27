
require "database/abstract"
require "fileutils"

################################################################################
class SqliteDatabase < AbstractEncDatabase

	## Pease ensure that the sqlite3 package for ruby is installed
    require 'sqlite3'
    
    @@handle = nil
    def initialize( conf, debug )
         super( 'sqlite', conf, debug )
         
         begin
    		
    		if( not File.exists?( @db ) )
    			initdb()
    		end

            @@handle = SQLite3::Database.open( @db )

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using SQLite based host lookup : "+ @config.key( 'sqlite.db' ) if( @debug )
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
        end
        
    end
    
    def terminate( )
        if( @@handle )
            @@handle.close()
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
        squery_host = "SELECT enc_hosts.host, enc_profiles.name,enc_profiles.value  FROM enc_profiles INNER JOIN enc_hosts ON enc_hosts.profile_id = enc_profiles.id WHERE enc_hosts.host LIKE '#{pattern}'"
        return nil
    end

    def profile( name )
        return fetch( name )
    end
    
    def db
        return @config["#{engine}.db"]
    end


    def insert( profile, config )
        
        iquery = "INSERT INTO enc_profiles(name, value) VALUES( '#{profile}', '#{config}' )"
        
    end
    
    def delete( profile )
        return nil
    end
    
    def update( profile, config )
        return nil
    end
    
    def fetch( profile )
        squery = "SELECT name,value FROM enc_profiles WHERE enc_profiles.name = '#{profile}'"
        return nil
    end
    
    def list()
        
        squery_profile = "SELECT name FROM enc_profiles ORDER BY name"
        squery_host = "SELECT enc_hosts.host, enc_profiles.name  FROM enc_profiles INNER JOIN enc_hosts ON enc_hosts.profile_id = enc_profiles.id"
        
        return nil
    end
    
    def bind( hostname, profile )
        
        profile_id = nil
        
        squery_profile = "SELECT id,name FROM enc_profiles WHERE enc.profile = '#{profile}'"
        ## If profile query returns nothing, raise exceptions, can not bind to a profile that does not exist.
        
        if( profile_id )
            iquery_bind = "INSERT INTO enc_hosts( host, profile_id ) VALUES( '#{hostname}','#{profile_id}')"
        end
        
        return nil
    end
    

end
