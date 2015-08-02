#!/usr/bin/env ruby -I../rlib
require "config"
require 'json'
require "test/unit"

class TestDatabaseDir < Test::Unit::TestCase
    
    @@debug = false
    def setup()
        
        filename = "test_enc.json"
        @conf = EncConfig.new( filename, @@debug )
    end
   
    def teardown()
    end
   

    def test_key
       assert_equal( true, @conf.key?( "db.engine" ) )
       assert_equal( false, @conf.key?( "enc.engine" ) )
       assert_equal( false, @conf.key?( "engine" ) )
       assert_equal( true, @conf.key?( "enc.match" ) )

       assert_equal( "dir", @conf.key( "db.engine" ) )
       assert_equal( "strict", @conf.key( "enc.match" ) )
       
       assert_equal( "default", @conf.key!( "enc.match", "default" ) )
       assert_equal( "faulty", @conf.key!( "enc.match", "faulty" ) )
       assert_equal( "psql", @conf.key!( "db.engine", "psql" ) )
       
       assert_equal( "faulty", @conf.key( "enc.match" ) )
       assert_equal( "psql", @conf.key( "db.engine" ) )
    end
    
    def test_defaults
        
    end

end