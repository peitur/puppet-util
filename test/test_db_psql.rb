#!/usr/bin/env ruby -I../rlib
require "fileutils"
require "config"
require 'json'
require "test/unit"

require "database"
require "database/psql"

require "pg"

class TestDatabasePsql < Test::Unit::TestCase
    
    @@prepare = true
    @@cleanup = true
    @@debug = false
    DIR_PROFILES        = ["dd.domain.com", "test00.test.com","test01.test.com","default"]
    DIR_PROFILES_PREP   = ["dd1.domain.com", "test10.test.com","default1"]

    DIR_HOSTS_OK = {
            "demo1.dot.com" => "dd.domain.com",  #ok
            "demo2.dot.com" => "dd.domain.com",  #ok
            "demo3.dot.com" => "test00.test.com", #ok
            "all" => "default" #ok
    } 
    
    DIR_HOSTS_NOK = {
            "demo1.dot.com" => "test00.test.com", #fail, host already exists
            "demoF2.dot.com" => "missing.test.com", #fail, missing profile
    }

#    DIR_PROFILES = []
    
    def setup()
        filename = "../test/test_enc.json"
        @conf = EncConfig.new( filename, @@debug )

        @db = PsqlDatabase.new( @conf, @@debug )
        @db.initdb()

        if( @@prepare )
            DIR_PROFILES_PREP.each do |profile|
                infile = File.dirname( __FILE__ )+"/"+profile+".json"
                data = EncUtil.load_json( infile )
                @db.insert( profile, data )
            end
        end
 
    end
   
    def teardown()
        return true if not @@cleanup

        @engine = "psql"
        filename = "../test/test_enc.json"
        conf = EncConfig.new( filename, @@debug )

        db = conf.key?( "#{@engine}.db" ) ? conf.key( "#{@engine}.db" ) : conf.default( "#{@engine}.db" )
        hostname = conf.key?( "#{@engine}.hostname" ) ? conf.key( "#{@engine}.hostname" ) : conf.default( "#{@engine}.hostname" )
        user = conf.key?( "#{@engine}.user" ) ? conf.key( "#{@engine}.user" ) : conf.default( "#{@engine}.user" )
        password = conf.key?( "#{@engine}.password" ) ? conf.key( "#{@engine}.password" ) : conf.default( "#{@engine}.password" )
        schema = conf.key?( "#{@engine}.schema" ) ? conf.key( "#{@engine}.schema" ) : conf.default( "#{@engine}.schema" )

        handle = PG::Connection.open(:dbname => db, :user => user, :host => hostname, :password => password )
        handle.transaction{ |conn|
            conn.exec( "DROP TABLE enc_profiles")
            conn.exec( "DROP TABLE enc_hosts")
        }
        handle.close
    end
   
    def test_search
        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end


        DIR_HOSTS_OK.each do |host, profile|
            assert_equal( [profile, host] , @db.bind( host, profile ) )
        end

        DIR_HOSTS_OK.each do |host, profile|
            assert_equal( [profile] , @db.search( host ))
        end
        
        assert_equal( [], @db.search( "noprofile" ) )
        assert_equal( nil, @db.search( nil ) )
    end

    def xtest_profile
    end
    
    def xtest_db
        
    end


    def test_insert

        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end
        
        assert_equal( false, @db.insert( "noprofile", nil ) )
        assert_equal( false, @db.insert( nil, EncUtil.load_json( "noprofile" )) )
    end
    
    def test_delete
        @@prepare = true

        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end

        DIR_PROFILES.each do |profile|
            assert_equal( true, @db.delete( profile ))
        end
        
        assert_equal( false, @db.delete( "noprofile" ) )
        assert_equal( false, @db.delete( nil ) )
    end

    def test_update
        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end


        DIR_HOSTS_OK.each do |host, profile|
            assert_equal( [profile, host] , @db.bind( host, profile ) )
        end


        ## overwrite second in list with first in list
        src = DIR_PROFILES[0]+".json"
        dprofile = DIR_PROFILES[1]
        assert_equal( true, @db.update( dprofile, EncUtil.load_json( src ) ) )

        ## overwrite dd.domain.com (first) with default profile content
        src = File.dirname( __FILE__ )+"/default.json"
        dprofile = "dd.domain.com"
        assert_equal( true, @db.update( dprofile, EncUtil.load_json( src ) ) )


        assert_equal( false, @db.update( "noprofile", EncUtil.load_json( "noprofile" )) )
        assert_equal( false, @db.update( nil, EncUtil.load_json( "noprofile" )) )
    end
    
    def test_fetch
        ok_string = '{"hostname":"test1.domain.com","ntp":["time11.domain.com","time12.domain.com"]}'
        ok_profile = "default"
        nok_profile = "missing"
        ok_reply = JSON.parse( ok_string )

        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end

        
        assert_equal( ok_reply, @db.fetch( ok_profile ) )
        assert_raise do @db.fetch( nok_profile ) end
    end
    
    def xtest_list
        

    end
    
    def test_bind
        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end


        DIR_HOSTS_OK.each do |host, profile|
            assert_equal( [profile, host] , @db.bind( host, profile ) )
        end

        DIR_HOSTS_NOK.each do |host, profile|
            assert_raise do @db.bind( host, profile ) end
        end

        assert_equal( nil, @db.bind( nil, "default" ) )
        assert_equal( nil, @db.bind( "demoC.dot.com", nil ) )
    end
    
   
end
