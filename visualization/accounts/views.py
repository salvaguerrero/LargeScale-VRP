from django.shortcuts import render, redirect
from django.views.generic import TemplateView,FormView

from django.contrib.auth import authenticate, login, logout
from .forms import CreateUserForm
# Create your views here.

def RegisterPage(request):
	form = CreateUserForm()
	if request.method == 'POST':
		form = CreateUserForm(request.POST)
		if form.is_valid():
			form.save()
			return redirect('log-in')
		
	context = {'form':form}
	return render(request,"registration/register.html", context )

def Log_in(request):
	
	if request.method == 'POST':
		user = request.POST.get('user')
		password = request.POST.get('password')

		user = authenticate(request, username=user, password=password)
		if user is not None:
			login(request, user)
			return redirect("home")

	context = {}
	return render(request,"registration/login.html",context )

def Log_out(request):
	logout(request)
	return redirect("log-in")


