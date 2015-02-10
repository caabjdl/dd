module Helpers
  class Haversine
    include Singleton

    RAD_PER_DEG = 0.017453293  #  PI/180  
  
    # the great circle distance d will be in whatever units R is in  
      
    Rmiles = 3956           # radius of the great circle in miles  
    Rkm = 6371              # radius in kilometers...some algorithms use 6367  
    Rfeet = Rmiles * 5282   # radius in feet  
    Rmeters = Rkm * 1000    # radius in meters  
      
    # @distances = Hash.new   # this is global because if computing lots of track point distances, it didn't make  
                            # sense to new a Hash each time over potentially 100's of thousands of points  
      
    def haversine_distance( lat1, lon1, lat2, lon2 )  
      dlon = lon2 - lon1  
      dlat = lat2 - lat1  
       
      dlon_rad = dlon * RAD_PER_DEG  
      dlat_rad = dlat * RAD_PER_DEG  
       
      lat1_rad = lat1 * RAD_PER_DEG  
      lon1_rad = lon1 * RAD_PER_DEG  
       
      lat2_rad = lat2 * RAD_PER_DEG  
      lon2_rad = lon2 * RAD_PER_DEG  
       
      # puts "dlon: #{dlon}, dlon_rad: #{dlon_rad}, dlat: #{dlat}, dlat_rad: #{dlat_rad}"  
      a = Math.sin(dlat_rad/2)**2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin(dlon_rad/2)**2  
      c = 2 * Math.asin( Math.sqrt(a))  
       
      dMi = Rmiles * c          # delta between the two points in miles  
      dKm = Rkm * c             # delta in kilometers  
      dFeet = Rfeet * c         # delta in feet  
      dMeters = Rmeters * c     # delta in meters  
      
      # @distances["mi"] = dMi  
      # @distances["km"] = dKm  
      # @distances["ft"] = dFeet  
      # @distances["m"] = dMeters  
      return dMeters
    end 

    def test_haversine  
      lon1 = -104.88544  
      lat1 = 39.06546  
       
      lon2 = -104.80  
      lat2 = lat1  
       
      haversine_distance( lat1, lon1, lat2, lon2 )  
       
      puts "the distance from  #{lat1}, #{lon1} to #{lat2}, #{lon2} is:"  
      puts "#{@distances['mi']} mi"  
      puts "#{@distances['km']} km"  
      puts "#{@distances['ft']} ft"  
      puts "#{@distances['m']} m"  
       
      if @distances['km'].to_s =~ /7\.376*/  
        puts "Test: Success"  
      else
        puts "Test: Failed"  
      end
    end  

    #Helpers::Haversine.instance.haversine_with_more_points([[39.06546, -104.88544],[39.06546, -104.80]])
    def haversine_with_more_points(points_ary)
      total_meters = 0.0
      for i in 0...(points_ary.length-1)
        if !(points_ary[i][0] == points_ary[i+1][0] && points_ary[i][1] == points_ary[i+1][1])
          total_meters = total_meters + haversine_distance(points_ary[i][0], points_ary[i][1], points_ary[i+1][0], points_ary[i+1][1])
        end
      end
      return total_meters
    end

  end
end