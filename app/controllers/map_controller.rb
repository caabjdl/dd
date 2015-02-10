class MapController < ApplicationController
	
	layout :false
	def baidumap
		@start = 116.404
		@end = 39.915
		@start1 = 116.389
		@end1 = 39.811
	end

	def googlemap
		@start = 116.404
		@end = 39.915
		@start1 = 116.389
		@end1 = 39.811
	end

	def gaodemap
		@start = 116.404
		@end = 39.915
		@start1 = 116.389
		@end1 = 39.811
	end

end
