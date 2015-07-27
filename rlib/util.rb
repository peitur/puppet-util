
module EncUtil

	def EncUtil.load_json( filename, debug = false )
		## 
		if( File.exists?( filename ) or File.symlink?( filename ) )		
			## Lets open it and parse it into a config object (hash)
			begin
	
				return JSON.load( File.open( filename ) )
	
			rescue => error  ## Catching everything this time, no need to be picky
				
				STDERR.puts "ERROR #{__FILE__}/#{__LINE__}: #{error} \n" if( debug )
	
				return nil
			end
		else
			STDERR.puts "ERROR #{__FILE__}/#{__LINE__}: Could not find config file #{filename} \n" if( debug )
	
			return nil
		end

	end

end