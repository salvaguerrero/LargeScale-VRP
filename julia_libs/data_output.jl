function nodes_to_json(nodes_df,nodes_map_base)
#Function Description: 
#		Appends node information to a geoson(map_base)
#Inputs:
#		node_df(dataframe) = DataFrame(Node_Name=[],Lat=[],Lng=[],Color=[]) 
#		map_base(geojson): base dictionary with a geojson structure
#Outputs:
#		map_base(geojson): geojson structure appended with the nodes_df data

	
	aux = Dict("type"=> "Feature",
	"properties"=> Dict("cluster" => "default",
						"name" => "default",
						"arc" => false,
						"color"=> "corner"),
	"geometry"=> Dict("type" => "Point",
					"coordinates" =>  [ 0.0, 0.0	]
					)
	)


	for n in 1:size(nodes_df)[1]

		aux["properties"]["name"] =  nodes_df[n,"Node_Name"]
		aux["properties"]["arc"]  = false
		aux["properties"]["color"] = nodes_df[n,"Color"]
		aux["geometry"]["type"] = "Point"
		aux["geometry"]["coordinates"] = [  nodes_df[n,"Lng"],nodes_df[n,"Lat"] ]
		push!(nodes_map_base["features"],deepcopy(aux))

	end

	return nodes_map_base
end

function arcs_to_json(arcs_df,arcs_map_base)
#Function Description: 
#		Appends arcs information to a geoson(map_base)
#Inputs:
#		arc_df(dataframe) = DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [], ColorF=[], ColorT=[]) 
#		map_base(geojson): base dictionary with a geojson structure
#Outputs:
#		map_base(geojson): geojson structure appended with the arcs_df data
	aux = Dict(

	
		"coordinates" => [ [0.0,0.0], [0.0,0.0] ],
		"properties"  => Dict( "colorF" =>[0,0,0],
							   "colorF" =>[0,0,0],
							)
					
	)
	for n in 1:size(arcs_df)[1]
		
		aux["properties"]["colorF"] = arcs_df[n,"ColorF"]
		aux["properties"]["colorT"] = arcs_df[n,"ColorT"]
		#aux["geometry"]["type"] = "MultiLineString"
		aux["coordinates"] = [ [ arcs_df[n,"FromLng"],  arcs_df[n,"FromLat"]], [ arcs_df[n,"ToLng"],arcs_df[n,"ToLat"]  ] ]
		push!(arcs_map_base["features"],deepcopy(aux))

	end

	return arcs_map_base
end

function to_geojson(nodes_df,arcs_df,base_path)
#Function Description: 
#		Generetes a geojson with arcs and nodes information
#Inputs:
#		arc_df(dataframe) = DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [], ColorF=[], ColorT=[]) 
#		nodes_df(dataframe)  = DataFrame(Node_Name=[],Lat=[],Lng=[],Color=[])
#		**************** If arcs should not be included in the geosjon, the variable arc_df should be a false
#Outputs:
#		geojson file stored in a the path: 

	element_json = 1000
	map_base = Dict(
		 			"features" => [],
				    "pagination" => [1,1])			#page 1 out of 1. Pagination starts at 1
	if arcs_df != false
		arc_num = size(arcs_df)[1]
		if  arc_num <= element_json				#No need for pagination
			map_data =  arcs_to_json(arcs_df,map_base)
			string_map_data = JSON.json(map_data)
			path = base_path*"/arcs_data_1.json"
			open(path, "w") do f
				write(f, string_map_data)
			end	
		else
			pages =  (arc_num/element_json) == (trunc(Int, arc_num/element_json)) ? trunc(Int, arc_num/element_json) : trunc(Int, arc_num/element_json) + 1
			l = 1
			u = element_json
			for p in 1:pages
				map_base["pagination"] = [p,pages]
				map_data = arcs_to_json(arcs_df[l:u,:],map_base)

				l = u + 1
				if arc_num - u < element_json		#If we are in the last page
					u = arc_num
				else
					u = u + element_json
				end

				string_map_data = JSON.json(map_data)
				path = base_path*"/arcs_data_"*string(p)*".json"
				open(path, "w") do f
					write(f, string_map_data)
				end	

			end
		end
	else
		string_map_data = JSON.json(map_base)
		path = base_path*"/arcs_data_1.json"
		open(path, "w") do f
			write(f, string_map_data)
		end	
	end

	map_base = Dict("type" => "FeatureCollection",
				"features" => [],
   			  "pagination" => [1,1])			#page 1 out of 1. Pagination starts at 1
	if nodes_df != false
		nod_num  = size(nodes_df)[1]
		if  nod_num <= element_json				#No need for pagination
			map_data =  nodes_to_json(nodes_df,map_base)
			string_map_data = JSON.json(map_data)
			path = base_path*"/nodes_data_1.geojson"
			open(path, "w") do f
				write(f, string_map_data)
			end	
		else
			pages = trunc(Int, nod_num/element_json) + 1
			pages =  (nod_num/element_json) == (trunc(Int, nod_num/element_json)) ? trunc(Int, nod_num/element_json) : trunc(Int, nod_num/element_json) + 1
 
			l = 1
			u = element_json
			for p in 1:pages
				map_base["pagination"] = [p,pages]

				map_data = nodes_to_json( nodes_df[l:u,:],map_base)

				l = u + 1
				if nod_num - u < element_json		#If we are in the last page
					u = nod_num
				else
					u = u + element_json
				end

				string_map_data = JSON.json(map_data)

				path = base_path*"/nodes_data_"*string(p)*".geojson"
				open(path, "w") do f
					write(f, string_map_data)
				end	

			end
		end
	else
		string_map_data = JSON.json(map_base)
		path = base_path*"/nodes_data_1.geojson"		
		open(path, "w") do f
			write(f, string_map_data)
		end	
	end


end
