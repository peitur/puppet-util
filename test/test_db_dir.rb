#!/usr/bin/env ruby -I../rlib
require "fileutils"
require "config"
require 'json'
require "test/unit"
require "database/dir"

class TestDatabaseDir < Test::Unit::TestCase
    
    DIR_PROFILES = ["dd.domain.com", "test00.test.com","default"]

    def setup()
        filename = "../test/test_enc.json"
        @conf = EncConfig.new( filename, true )
        @db = DirDatabase.new( @conf, true )
        
        DIR_PROFILES.each do |fname|
            src = File.dirname( __FILE__ )+"/"+fname+".json"
            dst = @conf.key( "dir.db" )+"/"+fname+".json"
            FileUtils.copy( src, dst )
        end
    end
   
    def teardown()
        
        FileUtils.rmtree( @conf.key( "dir.db" ) )
        
    end
   
    def test_search
        pattern = ""
    end

    def test_profile
    end
    
    def test_db
        
    end


    def test_insert
        profile = ""
        value = ""
    end
    
    def test_delete
        profile = ""
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