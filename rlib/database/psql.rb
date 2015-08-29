
require 'pg'
require "database/abstract"

################################################################################
class PsqlDatabase < AbstractEncDatabase

    
    def initialize( conf, debug )
         super( 'psql', conf, debug )

        STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using PostgreSQL based host lookup : "+ @config.to_s if( @debug )

        begin
            initdb()
        rescue => error
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Database init failed : #{error}"+"\n"            
        end

         
        begin
            
            @dbhandle = PG::Connection.open(:dbname => @db, :user => @user, :host => @hostname, :password => @password )

            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Using PostgreSQL based host lookup : "+ @config.key( 'psql.db' ) if( @debug )
        rescue => error
            STDERR.puts( error.backtrace )
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: #{error}"+"\n"
        end
        
    end
    

    def initdb( )
        STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Initializing dbschema for #{@engine} : #{@db}" if( @debug )

        begin

            STDERR.puts "DEBUG #{__FILE__}/#{__LINE__}: Creating tables for #{@engine} : #{@db}" if( @debug )

            handle = PG::Connection.open(:dbname => @db, :user => @user, :host => @hostname, :password => @password )
            handle.transaction {|conn|
                conn.exec( "CREATE TABLE IF NOT EXISTS #{@@profile_table}( #{@@profile_id} SERIAL, #{@@profile_name} TEXT UNIQUE, #{@@profile_value} TEXT )" )
                conn.exec( "CREATE TABLE IF NOT EXISTS #{@@host_table}( #{@@host_id} SERIAL, #{@@host_profile_id} INTEGER, #{@@host_host} TEXT UNIQUE  )" )
#                conn.exec( "CREATE INDEX IF NOT EXISTS profile_name_i ON #{@@profile_table}( #{@@profile_name} )" )
#                conn.exec( "CREATE INDEX IF NOT EXISTS host_host_i ON #{@@host_table}( #{@@host_host} )" )
#                conn.exec( "CREATE INDEX IF NOT EXISTS host_profile_id_i ON #{@@host_table}( #{@@host_profile_id} )" )
            }    
        rescue => error
            STDERR.puts( error.backtrace )
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Init error : #{error}"+"\n"
        ensure
            handle.close if handle
        end

        return true
    end


    def terminate( )
        
        if( @dbhandle and not @dbhandle.finished?() )
            @dbhandle.finish()
            return true
        end
        
        return false
    end
    
    def search( pattern )
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Searching for #{pattern}\n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return nil if( not pattern )

        squery_search = "SELECT #{@@host_table}.#{@@host_host} as host, #{@@profile_table}.#{@@profile_name} as profile, #{@@profile_table}.#{@@profile_value} as value FROM #{@@profile_table} INNER JOIN #{@@host_table} ON #{@@host_table}.#{@@host_profile_id} = #{@@profile_table}.#{@@profile_id} WHERE host LIKE '#{pattern}'"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Searching SQL #{squery_search}\n" ) if( @debug )

        result = Array.new()

        begin
            rsX = @dbhandle.exec( squery_search )
            rsX.each do |row|
                result.push( row['profile'] )
            end            
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Search profile #{pattern} failed: "+error.to_s+"\n"
        end

        return result
    end



    def load_profile( name )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Loading profile #{name}\n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return false if( not name )
        
        squery = "SELECT id,name,value FROM #{@@profile_table} WHERE #{@@profile_table}.#{@@profile_name} = '#{name}'"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Load profile SQL: #{squery}\n" ) if( @debug )    

        begin
            rsX = @dbhandle.exec( squery )
            if( rsX.ntuples() == 0 )
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
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not get profile #{name} : "+error.to_s+"\n"
        end

    end
    
    def fetch( name )
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Loading profile #{name}\n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return false if( not name )
        
        squery = "SELECT id,name,value FROM #{@@profile_table} WHERE #{@@profile_table}.#{@@profile_name} = '#{name}'"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Load profile SQL: #{squery}\n" ) if( @debug )    

        begin
            rsX = @dbhandle.exec( squery )
            if( rsX.ntuples() == 0 )
                raise RuntimeError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile}"+"\n"
#                return false
            end

            return JSON.parse( rsX[0]["value"] )
            
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not get profile #{name} : "+error.to_s+"\n"
        end
    end    
    
    def db
        return @config["#{engine}.db"]
    end


    def insert( profile, config )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Inserting profile #{profile} with config "+config.to_s+" \n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return false if( not profile )
        return false if( not config )
        
        config_json_str = JSON.generate( config )
        iquery = "INSERT INTO #{@@profile_table}( #{@@profile_name}, #{@@profile_value} ) VALUES( '#{profile}', '#{config_json_str}' )"
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Insert profile SQL: #{iquery}\n" ) if( @debug )    

        begin
            @dbhandle.transaction { |conn|
                conn.exec( iquery )
            }
            
            return true
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not register profile #{profile} : "+error.to_s+"\n"
        end
        
    end
    
    def delete( profile )

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Deleting profile #{profile} \n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return false if( not profile )

        ## Since a false is expected when no profile is found to delete, an extra check is needed.
        ## This should be changed

        ## TODO: Cleanup of hosts when a profile is deleted
        iquery_profile = "DELETE FROM #{@@profile_table} WHERE #{@@profile_name} = '#{profile}'"
        iquery_host = "DELETE FROM #{@@host_table} WHERE #{@@host_host} = '#{profile}'"

        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Delete profile SQL: #{iquery_profile}\n" ) if( @debug )    
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Delete host SQL: #{iquery_host}\n" ) if( @debug )    


        iquery_xec = Array.new()

        begin

            squery_host    = "SELECT #{@@host_host} as name FROM #{@@host_table} WHERE name = '#{profile}'"
            squery_profile = "SELECT #{@@profile_id},#{@@profile_name} as name FROM #{@@profile_table} WHERE name = '#{profile}'"
        

            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Check Delete host SQL: #{squery_host}\n" ) if( @debug )    
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Check Delete profile SQL: #{squery_profile}\n" ) if( @debug )    


            rsH = @dbhandle.exec( squery_host )
            rsP = @dbhandle.exec( squery_profile )
            rsN = [rsH.ntuples, rsP.ntuples]

            iquery_xec.push( iquery_profile ) if( rsP.ntuples() > 0 )
            iquery_xec.push( iquery_host )    if( rsH.ntuples() > 0 )

            return false  if( iquery_xec.ntuples == 0 )
        rescue => error
            STDERR.puts( "ERROR #{__FILE__}/#{__LINE__}: Nothing found to delete "+rsN.to_s+": "+error.to_s+"\n" ) if( @debug )
            STDERR.puts( error.backtrace )
            return false
        end


        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Deleting query: "+iquery_xec.to_s()+"\n" ) if( @debug )
        begin
            iquery_xec.each do |iquery|
                @dbhandle.transaction {|conn|
                    conn.exec( iquery )
                }
            end

            return true
        rescue => error
            STDERR.puts( error.backtrace )
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not delete #{profile}: "+error.to_s+"\n"    
        end
        
    end
    
    def update( profile, config )
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Updating profile #{profile} with config "+config.to_s+" \n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle

        return false if( not profile )
        return false if( not config )
        
        config_json_str = JSON.generate( config )
        iquery = "UPDATE #{@@profile_table} SET #{@@profile_value} = '#{config_json_str}' WHERE #{@@profile_name} = '#{profile}' "
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Update profile SQL: #{iquery}\n" ) if( @debug )    

        begin
            @dbhandle.transaction {|conn|
                conn.execute( iquery )
            }        

            return true
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Could not update profile #{profile} : "+error.to_s+"\n"
        end
    end
    

    
    def list()
        
        squery_profile = "SELECT #{@@profile_name} AS name FROM #{@@profile_table} ORDER BY #{@@profile_name}"
        squery_host = "SELECT #{@@host_host} AS host FROM #{@@host_table} ORDER BY #{@@host_host}"
        squery_bound = "SELECT #{@@host_table}.#{@@host_host} as host, #{@@profile_table}.#{@@profile_name} as profile, #{@@profile_table}.#{@@profile_value} as value FROM #{@@profile_table} INNER JOIN #{@@host_table} ON #{@@host_table}.#{@@host_profile_id} = #{@@profile_table}.#{@@profile_id} ORDER BY host"
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: List profile SQL: #{squery_profile}\n" ) if( @debug )    
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: List host SQL: #{squery_host}\n" ) if( @debug )    
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: List bound SQL: #{squery_bound}\n" ) if( @debug )    
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle


        result = Hash.new()
        result['profile'] = Array.new()
        result['host'] = Array.new()
        result['bound'] = Array.new()    

        ## First just get all unique profiles
        begin
            rsX = @dbhandle.exec( squery_profile )
            rsX.each do |row|
                result['profile'].push( row['name'] )
            end            
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Listing profile list failed: "+error.to_s+"\n"
        end

        begin
            rsX = @dbhandle.exec( squery_host )
            rsX.each do |row|
                result['host'].push( row['host'] )
            end            
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Listing host list failed: "+error.to_s+"\n"
        end

        ## Get all hosts with their corresponding profiles
        begin
            rsX = @dbhandle.exec( squery_bound )
            rsX.each do |row|
                result['bound'].push( [row['host'], row['profile']] )
            end            
        rescue => error
            STDERR.puts( error.backtrace )
            raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Listing bound list failed: "+error.to_s+"\n"
        end

        return result
        
    end
    
    def bind( hostname, profile )
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Binidng profile #{profile} to host #{hostname} \n" ) if( @debug )
        raise RuntimeError, "ERROR #{__FILE__}/#{__LINE__}: Database handle not initialized\n" if not @dbhandle
        
        return nil if( not hostname )
        return nil if( not profile )
        
        profile_id = nil
        begin
            squery_bind = "SELECT #{@@profile_id},#{@@profile_name} FROM #{@@profile_table} WHERE #{@@profile_name} ='#{profile}'"
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Bind Check profile SQL: #{squery_bind}\n" ) if( @debug )    
            rsX = @dbhandle.exec( squery_bind )
            
            if( rsX.ntuples() == 0 )
                raise RuntimeError,  "ERROR #{__FILE__}/#{__LINE__}: Could not find profile #{profile}"+"\n"
#                return false
            end

            profile_id = rsX[0]["id"]
            
        rescue => error
            STDERR.puts( error.backtrace )
            raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: SQL error looing for profile #{profile} to bind to host #{hostname}: "+error.to_s+"\n"    
        end
        
        STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Found binidng profile #{profile} " ) if( @debug )
        
        return nil if( not profile_id )

        ## If profile query returns nothing, raise exceptions, can not bind to a profile that does not exist.
        
        if( profile_id )
            iquery_bind = "INSERT INTO #{@@host_table}( #{@@host_host}, #{@@host_profile_id} ) VALUES( '#{hostname}','#{profile_id}')"
            STDERR.puts( "DEBUG #{__FILE__}/#{__LINE__}: Binding SQL: #{iquery_bind} \n" ) if( @debug )

            begin
    
                @dbhandle.transaction {|conn|
                    conn.exec( iquery_bind )
                }
                
                return [profile, hostname]
                
            rescue => error
                STDERR.puts( error.backtrace )
                raise ArgumentError, "ERROR #{__FILE__}/#{__LINE__}: Could not delete #{profile}: "+error.to_s+"\n"    
            end
        end
        
        return nil
    end
    
end
