# pages/urls.py
from django.urls import path
from django.conf import settings
from django.conf.urls.static import static
from .views import Map,Operations,Operations_Item,Operations_New,Home,Assets


urlpatterns = [
    path("map/<str:pk>", Map.as_view(), name="map"),
    path("", Home.as_view(), name="home"),
    path("assets/",  Assets.as_view(),name="assets"),
    path("operations/", Operations.as_view(),name="ope"),
    path("operations-item/<str:pk>", Operations_Item.as_view(),name="ope-itm"),
    path("operations-new/", Operations_New.as_view(),name="new-ope")

]
