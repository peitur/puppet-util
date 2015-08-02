#!/usr/bin/env ruby -I../rlib
require "fileutils"
require "config"
require 'json'
require "test/unit"

require "database"
require "database/dir"

class TestDatabaseDir < Test::Unit::TestCase
    
    @@prepare = true
    @@cleanup = true
    @@debug = false
    DIR_PROFILES = ["dd.domain.com", "test00.test.com","default"]
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
        @db = DirDatabase.new( @conf, @@debug )
 
        if( @@prepare )
            DIR_PROFILES.each do |fname|
                src = File.dirname( __FILE__ )+"/"+fname+".json"
                dst = @conf.key( "dir.db" )+"/"+fname+".json"
                
                puts "COPY "+src+" => "+dst+"\n" if @@debug
                FileUtils.copy( src, dst )
            end
        end
    end
   
    def teardown()
        FileUtils.rmtree( @conf.key( "dir.db" ) ) if( @@cleanup )
    end
   
    def test_search
        DIR_PROFILES.each do |profile|
            assert_equal( [profile+".json"] , @db.search( profile ))
        end
        
        assert_equal( [], @db.search( "noprofile" ) )
        assert_equal( nil, @db.search( nil ) )
    end

    def test_profile
    end
    
    def test_db
        
    end


    def test_insert

        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            data = EncUtil.load_json( infile )
            assert_equal( true, @db.insert( profile, data ))
        end
        
        assert_equal( false, @db.insert( "noprofile", EncUtil.load_json( "noprofile" )) )
        assert_equal( false, @db.insert( nil, EncUtil.load_json( "noprofile" )) )
    end
    
    def test_delete
        @@prepare = true

        DIR_PROFILES.each do |profile|
            infile = File.dirname( __FILE__ )+"/"+profile+".json"
            assert_equal( true, @db.delete( profile ))
        end
        
        assert_equal( false, @db.delete( "noprofile" ) )
        assert_equal( false, @db.delete( nil ) )
    end
    
    def test_update

        ## overwrite second in list with first in list
        src = @conf.key( "dir.db" )+"/"+DIR_PROFILES[0]+".json"
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
        
        assert_equal( ok_reply, @db.fetch( ok_profile ) )
        assert_raise do @db.fetch( nok_profile ) end
    end
    
    def test_list
        

    end
    
    def test_bind

        DIR_HOSTS_OK.each do |host, profile|
            assert_equal( [profile+".json", host+".json"] , @db.bind( host, profile ) )
        end

        DIR_HOSTS_NOK.each do |host, profile|
            assert_raise do @db.bind( host, profile ) end
        end

        assert_equal( nil, @db.bind( nil, "default" ) )
        assert_equal( nil, @db.bind( "demoC.dot.com", nil ) )
    end
    
   
end