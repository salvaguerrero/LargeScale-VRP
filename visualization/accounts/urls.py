from django.conf.urls import include, url
from django.urls import path
from . import views	
from .views import RegisterPage


urlpatterns = [
    
    #url("dashboard/", dashboard, name="dashboard"),
	path("sign-in/", views.RegisterPage,name="sign-in"),
	path("log-in/", views.Log_in,name="log-in"),
	path("log-out/", views.Log_out,name="log-out"),
]