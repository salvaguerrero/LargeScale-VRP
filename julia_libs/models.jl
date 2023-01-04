
#----------------------------------------------------------------------------------------->
function veh_routing_stops(data,stops_df)
#Function Description: 
#		Module for solving a Vheicle Routing problem after running the stop module
#Inputs:
#		data(dict): proprietary Dict with the problem description and data
#		stops_df(dataframe): Location of the stops & students labeled as "D2D"     (Id=[], Lat=[], Lng=[], Color=[])
#Outputs:
#		arc_df(dataframe) = DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [], ColorF=[], ColorT=[]) 
	
#		nodes_df(dataframe): nodes information (Node_Name=[],Lat=[],Lng=[],Color=[])


	#Auxiliary variables ---------------------------------------------------->
	Nod_Num = size(stops_df)[1]
	Veh_Num = length(data["VehNam"])
	Sto_Num = size(stops_df[ (stops_df.Type .== "Stop") ,:])[1]
	Dep_Num = size(stops_df[ (stops_df.Type .== "Stop") ,:])[1]

	N_isDepo = Array{Bool}(undef, Nod_Num)
	for i in 1:Nod_Num
		if stops_df[i,"Type"] == "Depo"
			N_isDepo[i] = true
		else
			N_isDepo[i] = false
		end
	end

	if ! data["ExeTMa"][1] 

		DistMatrix = zeros(Float64, Nod_Num,Nod_Num)

		for i in 1:Nod_Num
			for j in 1:Nod_Num
				#Euclidean  Distance
				DistMatrix[i,j] = sqrt(  (stops_df[i,"Lat"] - stops_df[j,"Lat"])^2 + (stops_df[i,"Lng"] - stops_df[j,"Lng"])^2  )
			end
		end

	end

	bigM = zeros(Int,Nod_Num,Nod_Num)
	for i in 1:Nod_Num
		for j in 1:Nod_Num
			bigM[i,j] = 99999999#max( StopEarliestT + LoadingTime + TimeMatrix[i,j] + StopLatestT, 0 )
		end
	end

	#Optimization Model------------------------------------------------------->
	model = Model(Gurobi.Optimizer)

	@variable(model,veh[i in 1:Nod_Num, j in 1:Nod_Num, k in 1:Veh_Num] ,Bin) # bin: vehicle k: if node i preceeds node j
	#@variable(model, t[i in 1:Nod_Num, k in 1:Veh_Num] >= 0			,Int) # int: arrival time of vehicle k to node i
	@variable(model,aux[i in 1:Nod_Num, k in 1:Veh_Num] >= 0 			,Int) # int: acumulated service of the vehicle k at node i


	@objective(model,Min, sum(veh[i,j]*DistMatrix[i,j] for j in 1:Nod_Num, i in 1:Nod_Num, k in 1:Veh_Num) )
	
	#Vehicle Flow ---------------------------------------------------------->
	@constraint(model,       Flow[i in 1:Nod_Num, k in 1:Veh_Num], sum(veh[j,i] for j in 1:Nod_Num if i != j) - sum(veh[i,j] for j in 1:Nod_Num if i != j) == (data["VehDeF"][k] == i ? data["VehNum"][k] : 0) - (data["VehDe0"][k] == i ? data["VehNum"][k] : 0) )
	@constraint(model, NoSameNode[j in 1:Nod_Num, k in 1:Veh_Num], veh[j,j,k] == 0 ) 
	@constraint(model, OneVehDemNod[i in 1:Nod_Num; ! N_isDepo[i]], sum(veh[j,i,k] for j in 1:Nod_Num, k in 1:Veh_Num ) == 1 )				
	@constraint(model, SubtourEli[i in 1:Nod_Num, j in 1:Nod_Num, k in 1:Veh_Num; ! N_isDepo[i]], aux[i,k] - aux[j,k] + (Nod_Num-1)*veh[i,j,k] <= Nod_Num-2 )


	#@constraint(model, MaxVehLoad[i in 1:Nod_Num, k in 1:Veh_Num; ! N_isDepo[i]], a[i,k] <= data["VehCap"][k])


	#Time  ----------------------------------------------------------------->
	#@constraint(model, Timing[i in 1:Nod_Num, j in 1:Nod_Num, k in 1:Veh_Num; i != j], t[i,k] + 10 - t[j,k] <= ( 1 - veh[i,j,k] )*bigM[i,j] )


	#Solver configutation -------------------------------------------------->
	set_optimizer_attribute(model, "MIPGap", 0.1)

	#Solve ----------------------------------------------------------------->
	println("Running optimization process:")
	optimize!(model)
	println("    Execution status: ",termination_status(model))


	#Solution processing --------------------------------------------------->
	arc_df = DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [])
	nodes_df = DataFrame(Node_Name=[],Lat=[],Lng=[],Color=[]) 

	if termination_status(model) == MOI.OPTIMAL 

		println("Solution processing")

		for f in 1:Nod_Num
			for t in 1:Nod_Num
				for k in 1:Veh_Num
					if JuMP.value(veh[f,t,k]) == 1 
						FromLat = data["NodLat"][f]
						FromLng = data["NodLng"][f]
						ToLat = data["NodLat"][t]
						ToLng = data["NodLng"][t]
						push!(arc_df, [0,k,FromLat,FromLng,ToLat,ToLng])	
					end
				end
			end
		end
		#CSV.write("visualization/model_data/arcs.csv", arc_df)

		for n in 1:Nod_Num
			if N_isDepo[n]
				push!(nodes_df, [data["NodNam"][n], data["NodLat"][n], data["NodLng"][n], [52, 235, 73] ])	
			else
				push!(nodes_df, [data["NodNam"][n], data["NodLat"][n], data["NodLng"][n], [235, 52, 52] ])
			end

		end
		#CSV.write("visualization/model_data/nodes.csv", nodes_df)

		succes = true
	else
		succes = false
	end

	return  arc_df, nodes_df, succes

end

#----------------------------------------------------------------------------------------->
function stop_cre(data)
#Function Description: 
#		Module for creating stops grouping the set of clients in a clusters
#Inputs:
#		data(dict): proprietary Dict with the problem description and data
#Outputs:
#		visualization_df(dataframe): Stops & all students                                 							   (Id=[], Lat=[], Lng=[], Color=[])									 
#		        stops_df(dataframe): Location of the stops															   (Id=[], Lat=[], Lng=[], Color=[], Type=[], Demand=[])
#				

	# Auxiliary variables ---------------------------------------->
	Nod_Num = length(data["NodNam"])
	data_df = DataFrame(Id = [], Lat = [], Lng = [] ,ZipCode = [], Stop_Id = [], Color = [], Type = [], Demand = [])
	for i in 1:Nod_Num
		if data["NodTyp"][i] == "Corner"
			push!(data_df,[i, data["NodLat"][i], data["NodLng"][i], data["NodZip"][i], nothing, [252,3,248], data["NodTyp"][i], data["NodDem"][i]])
		end
	end
	stops_df = DataFrame(Id = [], Lat = [], Lng = [], Color=[], Type=[], Demand=[])

	Zip_Num = length(unique(data_df[!,"ZipCode"]))
	ZipCodes = unique(data_df[!,"ZipCode"])
	
	# Model ------------------------------------------------------>
	
	for i in 1:Zip_Num
		aux_df = data_df[data_df.ZipCode .== ZipCodes[i],:]				#filter students by ZipCode
		X = [aux_df[:,"Lat"] aux_df[:,"Lng"] ]'

		n_clusters = trunc(Int,size(aux_df)[1]/data["ExeSpS"][1])+1		#number of clusters per zipcode
		clusters = kmeans(X,n_clusters)

		#Demand agregation
		dem = zeros(size(clusters.centers)[2])
		for i in 1:size(clusters.assignments)[1]
			dem[ clusters.assignments[i] ] += data_df[ (data_df.Lat .== X[1,i]) .&& (data_df.Lng .== X[2,i]) ,:][1,"Demand"]	
		end

		#clusters.assignments
		for j in 1:size(clusters.centers)[2]
			Stop_Id = string(ZipCodes[i])*"_"*string(j)
			push!(stops_df, [Stop_Id,  clusters.centers[1,j],  clusters.centers[2,j], [252, 186, 3], "Stop",dem[j]])
		end

		for j in 1:size(aux_df)[1] #data_df.Node_Id .== aux_df[j,"Node_Id"]
			data_df[j,"Stop_Id"] = string(ZipCodes[i])*"_"*string( clusters.assignments[j]	)
		end
	end
	
	#Solution processing --------------------------------------------------->
		#Adding the students D2D to stops_df
	j = size(stops_df)[1]
	for i in 1:Nod_Num
		if data["NodTyp"][i] == "D2D"
			j += 1
			Stop_Id = string(data["NodZip"][i])*"_"*string(j)
			push!(stops_df, [Stop_Id,  data["NodLat"][i], data["NodLng"][i], [0,255,0], "D2D", data["NodDem"][i]])
		end
		if data["NodTyp"][i] == "Depo"
			j += 1
			Stop_Id = string(data["NodZip"][i])*"_"*string(j)
			push!(stops_df, [Stop_Id,  data["NodLat"][i], data["NodLng"][i], [0,255,0], "Depo",data["NodDem"][i]])
		end
	end 

	#for testing purposes: visualization_df:
	#students corner: green 
	#students D2D:    glue 
	#stops:			  red
	visualization_df = select(data_df, Not(["ZipCode", "Stop_Id"]) )
	append!(visualization_df, stops_df)
	rename!(visualization_df,:Id => :Node_Name)	

	return visualization_df, stops_df
end


#----------------------------------------------------------------------------------------->

function  BestInsertion(R,C,DistMatrix,node_df)
	#Which stop to add to the route and where to inserted
		T_best = Inf
		c_best = 1
		i_best = 1
		
		n = length(R)
		for c in C
			for i in 1:n
				
						
				if i == 1						#Insert in the first position
					T = DistMatrix[ node_df[node_df.Type .== "DepoO","Id"][1] , c][1] + data["NodTim"][c] +
						DistMatrix[ c , R[1] ][1] + data["NodTim"][ R[1] ] +
						(n > 2 ? sum( DistMatrix[ R[ii-1] , R[ii]][1] + data["NodTim"][ R[ii] ] for ii in 2:n) : 0) + 
						DistMatrix[ R[n] , node_df[node_df.Type .== "DepoF","Id"][1]   ][1] 
					
				elseif i == n					#Insert in the n position
					T = DistMatrix[ node_df[node_df.Type .== "DepoO","Id"][1] , R[1]][1] + data["NodTim"][ R[1] ] +
						(n> 2 ? sum( DistMatrix[ R[ii-1] , R[ii]][1] + data["NodTim"][ R[ii] ] for ii in 2:n if n > 2) : 0) + 
						DistMatrix[ R[n] , c][1] + data["NodTim"][c] + 
						DistMatrix[ c , node_df[node_df.Type .== "DepoF","Id"][1]   ][1]					

	
				else							#Insert in the i position


					T = DistMatrix[ node_df[node_df.Type .== "DepoO","Id"][1] , R[1]][1] + data["NodTim"][ R[1] ] +
					( n > 2 ? sum( DistMatrix[ R[ii-1] , R[ii]][1] + data["NodTim"][ R[ii] ] for ii in 2:i) : DistMatrix[ R[1] , R[2] ][1]) + 
					DistMatrix[ R[i] , c ][1] + data["NodTim"][ c ]  + 
					DistMatrix[ c , R[i+1] ][1] + data["NodTim"][ R[i+1] ] + 
					(n > 2 ? sum( DistMatrix[ R[ii-1] , R[ii]][1] + data["NodTim"][ R[ii] ] for ii in (i+1):n) : 0)
	
				end
	
				if T < T_best
					T_best = T
					c_best = c
					i_best = i
				end
	
			end
		end
		return T_best,c_best,i_best
		
end
	
	
function Insert(S,cc,i)
# insert cc in the position i of the ordered set S
# max(i) = length(S) + 1
	aux = OrderedSet()
	if i == 1
		
		push!(aux,cc)
		for j in 1:length(S)
			push!(aux,S[j])
		end
	elseif i == length(S) + 1
		aux = S
		push!(aux,cc)
	else
		for j in 1:(i-1)
			push!(aux,S[j])
		end
		push!(aux,cc)
		for j in (i):(length(S))
			push!(aux,S[j])
		end
	end
	return aux
		
end


function greedy_routing(data)
#Function description:
#		Create all the routes that each vehicles should follow. Based on a greedy heuristic.
#Inputs: 
#		data(dict): proprietary Dict with the problem description and data
#Oututs:
#		arcs_df(dataframe): arcs information (Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [])		
#		metadata: dict()

	# Variables ----------------------------------------------------------------->
	Nod_Num = length(data["NodNam"])
	Veh_Num = length(data["VehNam"])

	node_df = DataFrame(Id = [], Type = [], Demand = [])
	for i in 1:Nod_Num
		push!(node_df,[i, data["NodTyp"][i], data["NodDem"][i]])
	end

	DistMatrix = zeros(Float64, Nod_Num,Nod_Num)
	for i in 1:Nod_Num
		for j in 1:Nod_Num
			#Euclidean  Distance
			DistMatrix[i,j] = sqrt(  (data["NodLat"][i] - data["NodLat"][j])^2 + (data["NodLng"][i] - data["NodLng"][j])^2  )
		end
	end



	# Routes[1] = [1,2,3]
	# MetaRoute[1] = Dict()

	Routes    = Dict() 	    			    #Routes
	MetaRoute = Dict()						#Routes metadata

	r = 1
	N = 10								    #Number of simulations
	for a in 1:N
		global C = node_df[node_df.Type .!= "DepoO" .&& node_df.Type .!= "DepoF","Id"] #Stops

		while length(C) != 0
			#Only on type of vehicle
			Tmax = Inf
			c = rand(C)
			Routes[r] = OrderedSet([c])  
			C = setdiff(C,c)
			n_sto = length(Routes[r])
			
			while length(C) != 0

				T_best,c_best,i_best = BestInsertion(Routes[r],C,DistMatrix,node_df)					#Best stop and the best position 

				if (T_best <= Tmax) && (n_sto  <=  data["VehCap"][1][1]  )
					Routes[r]  = Insert(Routes[r],c_best,i_best)										#Insert in the element c_best in the position i_best of the route R[r]
					n_sto      = length(Routes[r])
					C = setdiff(C,c_best)														
				else
					Routes[r] = Insert(Routes[r], node_df[node_df.Type .== "DepoO","Id"][1], 1)   		#Insert DepoO as the origin of the route   
					push!(Routes[r],  node_df[node_df.Type .== "DepoF","Id"][1] )				     	#Insert DepoF as the end of the route
					MetaRoute[r] = T_best
					r = r + 1
					break
				end
				if length(C) == 0
					Routes[r] = Insert(Routes[r], node_df[node_df.Type .== "DepoO","Id"][1], 1)   		#Insert DepoO as the origin of the route   
					push!(Routes[r],  node_df[node_df.Type .== "DepoF","Id"][1] )					    #Insert DepoF as the end of the route
					MetaRoute[r] = T_best
					r = r + 1
				end
			end			
		end	
	end
	

	#Dates.DateTime("2014-05-29 12:00:00", "yyyy-mm-dd HH:MM:SS")
	#periods = fecha.instant.periods.value/1000	#period in minutes as Float64

	periods = 90#data["ExePer"][1] #minutes per day
	Time   = 1:Int(periods)

	Rou_Num = length(Routes)
	Wor_Num = 10
	model = Model(Gurobi.Optimizer)

	@variable(model, x[r in 1:Rou_Num, t in Time] ,Bin) 	   #  bin: is the route r starteted at the end of time t
	@variable(model, y[r in 1:Rou_Num, t in Time] ,Bin) 	   #  bin: is the route r active    at the end of time t
	@variable(model, z[r in 1:Rou_Num, t in Time] ,Bin) 	   #  bin: is the route r ended     at the end of time t

	# @variable(model,wx[w in 1:Wor_Num, t in Time] ,Bin) 	   #  bin: Do the worker w start shift at time t
	# @variable(model,wy[w in 1:Wor_Num, t in Time] ,Bin) 	   #  bin: Is the worker w working at time t
	# @variable(model,wz[w in 1:Wor_Num, t in Time] ,Bin) 	   #  bin: Do the worker w end his shift at time t

	@variable(model, N[ l in 1:Nod_Num,  t in Time] >= 0,Int ) #  Number of vehicles at node and begginig of time t
	@variable(model, q     						    >= 0,Int ) #  Max number of vehicles used

	
	# @variable(model, Nw[ l in 1:Nod_Num,  t in Time] >= 0,Int ) #  Number of workers at node and time
	# @variable(model, qw     						 >= 0,Int ) #  Max number of workers used

	@variable(model,fix_veh_cost )    								   #  Auxiliary variables for data output
	@variable(model,var_veh_cost )									   #                  "
	# @variable(model,fix_wor_cost )									   #                  "
	# @variable(model,var_wor_cost )									   #                  "

	@objective(model,Min, fix_veh_cost + var_veh_cost )
	
	@constraint(model,    active_a[r in 1:Rou_Num, t in 1:(periods-1)], y[r,t+1] == x[r,t] - z[r,t] + y[r,t] )
	@constraint(model,    active_b[r in 1:Rou_Num, t in [periods]    ], y[r,t]   == x[r,t] - z[r,t] 		 )

	@constraint(model,routeTime1[r in 1:Rou_Num], sum(y[r,t] for t in Time) == sum(x[r,t] for t in Time)*round(MetaRoute[r]) )
	@constraint(model,routeTime2[r in 1:Rou_Num], sum(x[r,t] for t in Time) <= 1 )												# a route can only start onece
	@constraint(model,routeTime3[r in 1:Rou_Num], sum(z[r,t] for t in Time) <= 1 )												# a route can only ends onece

	# @constraint(model,    active2[w in 1:Wor_Num, t in 2:periods], wy[w,t] == wx[w,t] - wz[w,t] + wy[w,t-1] )
	# @constraint(model,workerTime1[w in 1:Wor_Num], sum(wy[w,t] for t in Time) == data["EmpMHo"][1] ) 
	# @constraint(model,workerTime2[w in 1:Wor_Num], sum(wx[w,t] for t in Time) <= 1 )
	# @constraint(model,workerTime3[w in 1:Wor_Num], sum(wz[w,t] for t in Time) <= 1 )   #data["EmpNum"][1]
	
	@constraint(model, Flowa[c in 1:Nod_Num, t in 1:(periods-1)], N[c,t] + sum( z[r,t] for r in 1:Rou_Num if c == last(Routes[r]) ) - sum( x[r,t] for r in 1:Rou_Num if c == first(Routes[r]) ) == N[c,t+1])
	#@constraint(model, Flowb[c in 1:Nod_Num, t in [periods]],     N[c,t] + sum( z[r,t] for r in 1:Rou_Num if c == last(Routes[r]) ) - sum( x[r,t] for r in 1:Rou_Num if c == first(Routes[r]) ) == N[c,1])
	
	@constraint(model, NumVeh1a[c in node_df[node_df.Type .== "DepoO","Id"]], N[c,1] == q)
	@constraint(model, NumVeh1b[c in node_df[node_df.Type .!= "DepoO","Id"]], N[c,1] == 0)
	#@constraint(model, NumVeh2[c in node_df[node_df.Type .== "DepoO","Id"]], q <= data["VehNum"][1])

	@constraint(model, Cover[c in node_df[node_df.Type .!= "DepoO" .&& node_df.Type .!= "DepoF","Id"] ], sum( x[r,t] for t in Time, r in 1:Rou_Num if c in Routes[r]  ) >= 1 )

	@constraint(model,F_V_C, fix_veh_cost == data["VehCpx"][1]*q )	
	@constraint(model,V_V_C, var_veh_cost == data["VehOpx"][1]*sum( y[r,t] for r in 1:Rou_Num, t in Time ) )	


	println("Running optimization process:")
	optimize!(model)
	println("    Execution status: ",termination_status(model))


	#Solution processing
	arc_df =  DataFrame(Time = [],Vehicle = [],FromLat = [],FromLng = [],ToLat = [],ToLng = [], ColorF=[], ColorT=[]) 
	nodes_df = DataFrame(Node_Name=[],Lat=[],Lng=[],Color=[]) 
	rgb = 10
	ii = 1
	meta_data = Dict()
	meta_data["Routes"]   = Dict()
	meta_data["NumVeh"]   = JuMP.value(q)
	meta_data["Vehicles"] = Dict()
	meta_data["fix_veh_cost"] = JuMP.value(fix_veh_cost)
	meta_data["var_veh_cost"] = JuMP.value(var_veh_cost)
	for r in 1:Rou_Num
		for t in Time
			if JuMP.value(x[r,t]) == 1 		#route is selected
				route_str = string(Routes[r])
				route_str =  replace(route_str,"OrderedSet{Any}(Any["=>"")
				route_str =  replace(route_str,"])"=>"")
				route_str =  replace(route_str,","=>"      ")
				aux = Dict(
					"routes" => route_str,
					"r_time" => round(MetaRoute[r],digits=0),
					"start_time"   => data["ExeSta"][1] + Dates.Minute(t),
					"end_time"	   => data["ExeSta"][1] + Dates.Minute(t) + Dates.Minute(round(MetaRoute[r],digits=0))
					# "var_veh_cost" => JuMP.value(var_veh_cost),
					# "var_wor_cost" => 0,#JuMP.value(var_wor_cost),
					# "fix_veh_cost" => JuMP.value(fix_veh_cost),
					# "fix_wor_cost" => 0#JuMP.value(fix_wor_cost),
 				)
				meta_data["Routes"][ii] = aux
				ii += 1
				
				
				
				for i in 1:(length(Routes[r])-1)
					FromLat = data["NodLat"][ Routes[r][i] ]
					FromLng = data["NodLng"][ Routes[r][i] ]
					ToLat   = data["NodLat"][ Routes[r][i+1] ]
					ToLng   = data["NodLng"][ Routes[r][i+1] ]
					color = [rgb,rgb,rgb]
					push!(arc_df, [0,0,FromLat,FromLng,ToLat,ToLng,color,color])	
				end
				rgb = rgb + 10
				if rgb > 255
					rgb = 0
				end
			end
		end
	end

	return arc_df,meta_data
end
