from django.db import models

class Login(models.Model):
    username = models.CharField(max_length=50)
    password = models.CharField(max_length=50)
    type = models.CharField(max_length=50)

class Department(models.Model):
    department_name=models.CharField(max_length=50)
    department_code=models.CharField(max_length=50)


class Employee(models.Model):
    LOGIN = models.ForeignKey(Login,on_delete=models.CASCADE)
    name = models.CharField(max_length=50)
    Phone = models.BigIntegerField()
    employee_code = models.CharField(max_length=50)
    photo = models.FileField()
    place = models.CharField(max_length=50)
    pin = models.IntegerField()
    post = models.CharField(max_length=50)
    email = models.CharField(max_length=50)
    gender = models.CharField(max_length=50)
    department=models.ForeignKey(Department,on_delete=models.CASCADE)

class Category(models.Model):
    name = models.CharField(max_length=50)

class Brand(models.Model):
    name = models.CharField(max_length=50)

class Product(models.Model):
    product_name=models.CharField(max_length=50)
    BRAND=models.ForeignKey(Brand,on_delete=models.CASCADE)
    CATEGORY=models.ForeignKey(Category,on_delete=models.CASCADE)
    department_id=models.ForeignKey(Department,on_delete=models.CASCADE)
    price=models.FloatField()
    threshold=models.FloatField()

class Stock(models.Model):
    product_id=models.ForeignKey(Product,on_delete=models.CASCADE)
    stocks=models.IntegerField()

class Orders(models.Model):
    customer_name=models.CharField(max_length=50)
    product_id=models.ForeignKey(Product,on_delete=models.CASCADE)
    employee_id=models.ForeignKey(Employee,on_delete=models.CASCADE)
    quantity=models.IntegerField()
    total=models.FloatField()
    date=models.DateField()

class Sales(models.Model):
    ORDER=models.ForeignKey(Orders,on_delete=models.CASCADE)
    Date=models.DateField()
    Time=models.TimeField()
    Status=models.CharField(max_length=50)

class SalesNoti(models.Model):
    sales_id=models.ForeignKey(Sales,on_delete=models.CASCADE)



class feedback(models.Model):
    order_id=models.ForeignKey(Orders,on_delete=models.CASCADE)
    feedback=models.CharField(max_length=50)
    rating=models.IntegerField()
    reply=models.CharField(max_length=200)

