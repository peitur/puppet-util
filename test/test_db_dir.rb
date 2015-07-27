#!/usr/bin/env ruby -I../rlib
require "fileutils"
require "config"
require 'json'
require "test/unit"
require "database/dir"

class TestDatabaseDir < Test::Unit::TestCase
    
    @@prepare = true
    @@cleanup = false
    DIR_PROFILES = ["dd.domain.com", "test00.test.com","default"]
#    DIR_PROFILES = []
    
    def setup()
        filename = "../test/test_enc.json"
        @conf = EncConfig.new( filename, true )
        @db = DirDatabase.new( @conf, true )
 
        if( @@prepare )
            DIR_PROFILES.each do |fname|
                src = File.dirname( __FILE__ )+"/"+fname+".json"
                dst = @conf.key( "dir.db" )+"/"+fname+".json"
                
                puts "COPY "+src+" => "+dst+"\n"
                FileUtils.copy( src, dst )
            end
        end
    end
   
    def teardown()
        FileUtils.rmtree( @conf.key( "dir.db" ) ) if( @@cleanup )
    end
   
    def test_search
        pattern = ""
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
        profile = ""
        config = ""
    end
    
    def test_fetch
        profile = ""
    end
    
    def test_list
        
    end
    
    def test_bind
        hostname = ""
        profile = ""
    end
    
   
end