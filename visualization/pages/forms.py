from django import forms
from .models import Upload

class DocumentForm(forms.ModelForm):
    class Meta:
        model = Upload
        fields = ('upload_file', )