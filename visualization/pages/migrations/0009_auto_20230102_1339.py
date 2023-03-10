# Generated by Django 3.2.5 on 2023-01-02 12:39

from django.conf import settings
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('pages', '0008_auto_20230102_1330'),
    ]

    operations = [
        migrations.RenameField(
            model_name='company',
            old_name='normal_user',
            new_name='admin_user',
        ),
        migrations.RemoveField(
            model_name='project',
            name='creator_id',
        ),
        migrations.RemoveField(
            model_name='user',
            name='projects',
        ),
        migrations.AddField(
            model_name='project',
            name='users',
            field=models.ManyToManyField(to=settings.AUTH_USER_MODEL),
        ),
    ]
