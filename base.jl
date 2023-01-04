import XLSX
using DataFrames
using DataStructures
using CSV
using JSON
using JLD


using Plots
using Distributions
using Random

using Dates

#Clusterin:
using Clustering

#optimization:
using JuMP
using GLPK
using Clp
using Cbc
using SCIP
using Gurobi

#proprietary libraries
include("julia_libs/data_parsing.jl")
include("julia_libs/data_output.jl")
include("julia_libs/models.jl")

function data_loader(company, project, file_name)

	base_path = "C:/Users/Usuario/OneDrive - Universidad Pontificia Comillas/Buzzzzz/Transporte/OR/kaggle/boston bus scheduling/solution/BBS/visualization/model_data"
	base_path = base_path*"/"*company
	if isdir(base_path) == false
		mkpath(base_path)
	end
	base_path = base_path*"/"*project
	if isdir(base_path) == false
		mkpath(base_path)
	end

	data = ReadData(base_path*"/"*file_name)
	save(base_path*"/julia_data.jld", "data", data)

end

function optimizer(company, project)
	# company = "lyma_1"
	# project = "1234_1"

	println("******************************************")
	println("....... Welcome to SGG Optimization ......")
	println("Model running: Boston Public Schools:     ")
	println("         Trasnportation Challenge         ")
	println("******************************************")

	######################################    Data Parsing    ################
	println("Loading Data:")
	t1 = DateTime(now())

	base_path = "C:/Users/Usuario/OneDrive - Universidad Pontificia Comillas/Buzzzzz/Transporte/OR/kaggle/boston bus scheduling/solution/BBS/visualization/model_data"
	base_path = base_path*"/"*company
	if isdir(base_path) == false
		mkpath(base_path)
	end
	base_path = base_path*"/"*project
	if isdir(base_path) == false
		mkpath(base_path)
	end

	django = false
	if django
		d = load(base_path*"/julia_data.jld")
		data = d["data"]
	else
		data = ReadData(base_path*"/data entry Aceite.xlsm")
	end
	
	reading_time = DateTime(now()) - t1

	######################################    Auxiliary Variables   ################
	Nod_Num = length(data["NodNam"])
	######################################    Model Execution       ################
	println("Model Execution:")

	model = 2
	if model == 1
		t2 = DateTime(now())
		println("Executing model: Stop creator")
		visualization_df, stops_df =  stop_cre(data)
		stop_time = DateTime(now()) - t2

		t3 = DateTime(now())
		println("Executing model: Vehicle Routing with the Stops module")
		arcs_df, nodes_df, succes =  veh_routing_stops(data,stops_df)
		routing_time = DateTime(now()) - t3
	end

	if model == 2
		stop_time = 0

		t2 = DateTime(now())
		println("Executing model: Greedy routing")
		arcs_df,meta_data = greedy_routing(data)
		
		visualization_df = DataFrame(Node_Name=[],Lng=[],Lat=[],Color=[]) 
		for n in 1:Nod_Num
			if data["NodTyp"][n] == "DepoO"
				color = [0,255,0]
			elseif data["NodTyp"][n] == "DepoF"
				color = [0,255,0]
			else
				color = [252, 186, 3]
			end
			push!(visualization_df,[ data["NodNam"][n], data["NodLng"][n], data["NodLat"][n],  color ] )
		end

		routing_time = DateTime(now()) - t2
	end



	######################################    Data Output    ################
	println("Saving and Exporting data:")
	t4 = DateTime(now())
	if model == 2
		meta_data_f = JSON.json(meta_data)
		path = base_path*"/metadata.json"
		open(path, "w") do f
			write(f, meta_data_f)
		end	
	end
	to_geojson(visualization_df,arcs_df,base_path)

	export_time = DateTime(now()) - t4

	println("         Program Executed Successfully       ")
	println()
	println("                Loading Time: ", reading_time )
	println("  Stops Model Executing Time: ", stop_time)
	println("Routing Model Executing Time: ", routing_time)
	println("        Data  Exporting Time: ", export_time)
end


company = "lyma_1"
project = "1234_1"
optimizer(company, project)
