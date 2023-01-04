from django.db import models
from django.contrib.auth.models import AbstractUser
from django.conf import settings
User = settings.AUTH_USER_MODEL

from datetime import datetime

# Create your models here.


class Company(models.Model):
	name 	   = models.CharField(max_length=200)
	company_id = models.CharField(max_length=200)
	location   = models.CharField(max_length=200,default='')

	admin_user = models.ForeignKey(User, null=True, on_delete = models.CASCADE)
	
	def __str__(self): # __unicode__ in python 2.*
 		return self.company_id

class Project(models.Model):
	
	project_name  = models.CharField(max_length=200)
	project_id    = models.CharField(max_length=200)

	company_id    = models.ForeignKey(Company, on_delete=models.CASCADE)
	users         = models.ManyToManyField(User)
	creator       = models.ForeignKey(User, on_delete=models.CASCADE,related_name="creator",null=True)
	

	module        = models.CharField(max_length=10,default='')
	status		  = models.CharField(max_length=10,default='')
	creation_dat  = models.DateField(default=datetime.now)
	changes_dat   = models.DateField(default=datetime.now)
	

	def __str__(self): # __unicode__ in python 2.*
		return self.project_id	

	@staticmethod
	def get_all_projects(creator_id):
		try:			
			return Project.objects.filter(creator_id=creator_id)
		except:
			return False

class User(AbstractUser):

	company_id       = models.ForeignKey(Company, on_delete=models.CASCADE,default='',null=True,blank=True)
	is_master        = models.BooleanField(default=False)


def content_file_name(instance, filename):
	print(instance.company)
	print(instance.user)
	print('/'.join([str(instance.company), filename]))
	#company = User.objects.get(project_id=pk).company_id
	return '/'.join([str(instance.company), filename])

class Upload(models.Model):
	upload_file = models.FileField(upload_to=content_file_name)
	upload_date = models.DateTimeField(auto_now_add = True) 
	user        = models.ForeignKey(settings.AUTH_USER_MODEL,related_name='upload',on_delete=models.DO_NOTHING,null=True)
	company     = models.ForeignKey(Company,related_name='upload',on_delete=models.CASCADE,null=True)


