# Generated by Django 4.2.16 on 2025-01-16 10:05

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ("companies", "0002_companymodel_tagline_maincompanymodel_tagline"),
    ]

    operations = [
        migrations.AddField(
            model_name="storeaddressmodel",
            name="store_name",
            field=models.CharField(default="", max_length=255),
        ),
    ]
