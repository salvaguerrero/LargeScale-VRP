from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404

from pages.models import Project 

import json, os

class MapArcs(APIView):
	def get(self, request, pk):

		company = Project.objects.get(project_id=self.kwargs['pk']).company_id
		path = "model_data/"+str(company)+"/"+pk+"/arcs_data.json"
		f = open(path)
		data = json.load(f)
		f.close()

		return Response(data)

class MapNodes(APIView):
	def get(self, request, pk):

		company = Project.objects.get(project_id=self.kwargs['pk']).company_id
		path = "model_data/"+str(company)+"/"+pk+"/nodes_data.geojson"
		f = open(path)
		data = json.load(f)
		f.close()

		return Response(data)

class Gnantt(APIView):
	def get(self, request, pk):


		company = Project.objects.get(project_id=self.kwargs['pk']).company_id
		path = "model_data/"+str(company)+"/"+pk+"/metadata.json"
		f = open(path)
		data = json.load(f)
		data = data["Routes"]
		f.close()

		return Response(data)

class Model(APIView):
	def get(self, request, pk):

		company = Project.objects.get(project_id=self.kwargs['pk']).company_id
		print("starting julia")
		print(os.system('julia "../base.jl"'))
		print("julia finished")

		data = {
			"result": 1
		}
		data = json.dumps(data, indent = 4) 

		return Response(data)