from django.urls import path
from .apiviews import MapArcs, MapNodes, Gnantt, Model

urlpatterns = [
	path("data/arcs/<pk>",  MapArcs.as_view()  , name="map_data_arc"),
	path("data/nodes/<pk>", MapNodes.as_view() , name="map_data_node"),
	path("data/gannt/<pk>",  Gnantt.as_view()   , name="gannt_data_node"),
	path("model/execute/<pk>",   Model.as_view(), name="opt_model")
]
