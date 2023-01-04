from django.shortcuts import render, redirect
from django.views.generic import TemplateView, View
import csv, json
from django.http import HttpResponse
from pages.models import Project,Upload,User,Company
from django.conf import settings
#User = settings.AUTH_USER_MODEL

from django.core.files import File
from django.contrib.auth.decorators import login_required
from django.contrib.auth.mixins import LoginRequiredMixin

from django.urls import reverse_lazy

from .forms import DocumentForm
from django.core.files.storage import FileSystemStorage


class Map(TemplateView):
    template_name = "pages/deck_map.html"
    def get_context_data(self, **kwargs):
        context = super(Map, self).get_context_data(**kwargs)
        context.update({'project_id': str( self.kwargs['pk'] )})
        return context

class Home(LoginRequiredMixin,TemplateView):

    template_name = "pages/home.html"
    login_url = 'user/log-in/'

    def get_context_data(self, **kwargs):

        projects = Project.objects.filter(users=self.request.user)
        data = {}
        for i in range(len(projects)):
            project = projects[i]
            status = "none"
            if project.status == "in_progres":
                status = '<span class="badge badge-info-lighten">In Progress</span>'
            if project.status == "complete":
                status = '<span class="badge badge-success-lighten">Complete</span>'
            data[i] = {
                        
                "creation_dat" : project.creation_dat,
                "changes_dat"  : project.changes_dat,
                "name"         : project.project_name,
                "project_id"   : project.project_id,
                "creator_name" : project.creator,
                "creator_img"  : "nada",
                "module"       : project.module,
                "status"       : status
            }
        context = super(Home, self).get_context_data(**kwargs)
        context.update({'data': data})
        return context

class Assets(View):
    def get(self, request):
        form = DocumentForm(self.request.POST, self.request.FILES)
        return( render(self.request,'pages/assets.html',{'form': form}) )

    def post(self, request):
        form = DocumentForm(self.request.POST, self.request.FILES)
        if form.is_valid():
            document = form.save(commit=False)
            document.user = request.user
            document.company = User.objects.get(username = self.request.user).company_id 
            document.save()
        else:
            print("error")
        return( render(self.request,'pages/assets.html',{'form': form}) )

# def Assets(request):
#     if request.method == 'POST':
#         form = DocumentForm(request.POST, request.FILES)
#         if form.is_valid():
#             form.save()
#             return redirect('home')
#     else:
#         form = DocumentForm()
#     return render(request, 'pages/assets.html', {
#         'form': form
#     })


class Operations(TemplateView):
    template_name = "pages/operations.html"

class Operations_Item(LoginRequiredMixin,TemplateView):
    template_name = "pages/operations-item.html"
    login_url = 'user/log-in/'


    def get_context_data(self, **kwargs): 

        pk = self.kwargs['pk']
        company = Project.objects.get(project_id=pk).company_id
        path = "model_data/"+str(company)+"/"+pk+"/metadata.json"
        print(path)
        f = open(path)
        
        data = json.load(f)
        RouteData = data["Routes"]
        NumVeh = data["NumVeh"]
        FixCost = data["fix_veh_cost"]
        VarCost = data["var_veh_cost"]
        TotCost = FixCost + VarCost
        
        f.close()
        context = locals()
        context['RouteData'] =  RouteData        
        context['FixCost']   =  FixCost   
        context['VarCost']   =  VarCost     
        context['TotCost']   =  TotCost           
        context['NumVeh']    =  NumVeh
        context['project_id']    =  str(pk)
        return context


class Operations_New(TemplateView):
    template_name = "pages/operations-new.html"            

