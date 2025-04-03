from django.contrib import messages
from django.core.serializers import json
from django.shortcuts import render, redirect, get_object_or_404
from django.views.decorators.csrf import csrf_exempt

from .models import *
from django.core.files.storage import FileSystemStorage
from django.http import HttpResponse, JsonResponse
import json
from datetime import datetime


def home(request):
    return render(request,"index.html")

def login(request):
    return render(request,"loginindex.html")

def confirm(request):
    return render(request,"sales_confirmation.html")

def inventory(request):
    return render(request,"inventory.html")
def add_stock(request,id,pn):
    request.session['pid']=id
    return render(request,'add_stock.html',{"pn":pn})

def stock_add(request):
    quantity=request.POST['quantity']
    try:
        ob=Stock.objects.get(product_id__id=request.session['pid'])
        ob.stocks+=int(quantity)
        ob.save()
    except:
        ob = Stock()
        ob.product_id=Product.objects.get(id=request.session['pid'])
        ob.stocks = int(quantity)
        ob.save()
    return HttpResponse('''
                               <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10">
                               <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
                               <script>
                                   document.addEventListener("DOMContentLoaded", function() {
                                       Swal.fire({
                                           icon: 'success',  
                                           title: 'Stock Added',
                                           confirmButtonText: 'OK',
                                           reverseButtons: true
                                       }).then((result) => {
                                           if (result.isConfirmed) {
                                               window.location = '/manager_view_thresh';
                                           }
                                       });
                                   });
                               </script>
                           ''')



def edit_emp_pro(request):
    obj = Employee.objects.get(loginid__id=request.session['lid'])
    return render(request,'employee/emp-edit.html',{'i':obj})


def manager_view_sales(request):
    noti = Sales.objects.filter(Status = 'pending')
    return render(request, 'view notification manager.html',{'data':noti})

def manager_view_thresh(request):
    products = Product.objects.all()
    res=[]
    for i in products:
        try:
            i.st = Stock.objects.get(product_id=i.id).stocks
            if i.st<i.threshold:
                res.append(i)

        except:
            i.st = 0
            res.append(i)
    return render(request, 'manager_view_thresh.html',
                  {'data': res})


def send_reply(request,id):
    data = feedback.objects.get(id = id)
    return render(request,"send_reply.html",{'data':data})

def send_reply_post(request,id):
    reply1 = request.POST['reply']

    feedback.objects.filter(id = id).update(reply = reply1)

    return redirect('/view_review')



def view_review(request):
    data = feedback.objects.all()
    return render(request,'view_review.html',{'data':data})

def manager_approve_sales(request,id):
    Sales.objects.filter(id = id).update(Status = 'completed')
    messages.error(request, "Approved")
    return redirect('/manager_view_sales')

def manager_reject_sales(request,id):
    Sales.objects.filter(id=id).update(Status='Rejected')
    messages.error(request, "Rejected")
    return redirect('/manager_view_sales')


def logincode(request):
    username = request.POST['username']
    pwd = request.POST['password']
    ob = Login.objects.filter(username=username, password=pwd)

    if ob.exists():
        ob1 = Login.objects.get(username=username, password=pwd)
        request.session['lid'] = ob1.id

        if ob1.type == 'manager':
            return redirect('/manager_home')

        else:
            messages.error(request, "Invalid credentials. Please try again.")
            return redirect('/login')
    else:
        messages.error(request, "Invalid username or password.")
        return redirect('/login')

def manager_home(request):
    sal = Sales.objects.filter(Status='pending')
    nc = sal.count()
    print(nc, "ssssssssssss")
    productcount=0
    s = Stock.objects.filter()
    for i in s:
        print(int (i.stocks) ,"kjjkjkj", int(i.product_id.threshold))
        if int (i.stocks) <= int(i.product_id.threshold):
            print("jkjj")
            productcount=productcount+1
    request.session['ps']=productcount
    print("==========================",productcount)
    return render(request, 'managerhome.html',{'nat':nc,'ps':productcount})


def view_department(request):
    return render(request, 'view_employee.html')



def sales_report(request,id):
    data = Sales.objects.filter(ORDER__employee_id = id)
    return render(request,'sales_report.html',{'data':data})



def sales_reportss(request):
    if request.method == "POST":
        print("🔹 POST request received!")  # Debugging step
        f_date = request.POST.get('fromDate')
        t_date = request.POST.get('toDate')

        print(f"Filtering from {f_date} to {t_date}")  # Check values

        if f_date and t_date:
            data = Sales.objects.filter(Date__range=[f_date, t_date])
        else:
            data = Sales.objects.all()

        return render(request, 'sales_report.html', {'data': data})

    return render(request, 'sales_report.html', {'data': []})



def manage_category(request):
    cat = Category.objects.all()
    return render(request, 'category.html',{'cat':cat})

def add_category(request):
    if request.method == 'POST':
        name = request.POST['name']
        cat = Category(name=name)
        cat.save()
        return redirect('/manage_category')
    return render(request,'add_category.html')

def edit_category(request, id):
    cat = get_object_or_404(Category, id=id)
    if request.method == 'POST':
        cat.name = request.POST.get('name', cat.name)
        cat.save()
        messages.success(request, "Category updated successfully!")
        return redirect('/manage_category')
    return render(request, 'edit_category.html', {'cat': cat})

def delete_category(request,id):
    c = Category.objects.get(id=id)
    c.delete()
    return redirect('/manage_category')



def manage_brand(request):
    brand = Brand.objects.all()
    return render(request, 'brand.html',{'brand':brand})

def add_brand(request):
    if request.method == 'POST':
        name=request.POST['name']
        bran = Brand(
            name=name
        )
        bran.save()
        return redirect('/manage_brand')
    return render(request,'add_brand.html')

def edit_brand(request,id):
    brand = Brand.objects.get(id=id)
    if request.method == 'POST':
        brand.name = request.POST['name']
        brand.save()
        return redirect('/manage_brand')
    return render(request, 'edit_brand.html', {'cat': brand})


def delete_brand(request,id):
    b = Brand.objects.get(id=id)
    b.delete()
    return redirect('/manage_brand')



def manage_department(request):
    dep = Department.objects.all()
    return render(request, 'dept.html',{'dep':dep})

def add_department(request):
    if request.method == 'POST':
        department_name = request.POST.get('department_name')
        department_code = request.POST.get('department_code')

        if department_name and department_code:  # Ensure values are not empty
            Department.objects.create(department_name=department_name, department_code=department_code)
            return HttpResponse('''
                            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10">
                            <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
                            <script>
                                document.addEventListener("DOMContentLoaded", function() {
                                    Swal.fire({
                                        icon: 'success',  
                                        title: 'Department Added',
                                        confirmButtonText: 'OK',
                                        reverseButtons: true
                                    }).then((result) => {
                                        if (result.isConfirmed) {
                                            window.location = '/manage_department';
                                        }
                                    });
                                });
                            </script>
                        ''')

    return render(request, 'add_department.html')

def employee_sales_report(request,id):
    data = Sales.objects.filter(ORDER__employee_id__LOGIN__id=id)
    return render(request,'employee_sales_report.html',{'data':data})



def esales_reportss(request):
    if request.method == "POST":
        print("🔹 POST request received!")  # Debugging step
        f_date = request.POST.get('fromDate')
        t_date = request.POST.get('toDate')

def edit_department(request,id):
    dep = Department.objects.get(id=id)
    if request.method == 'POST':
        dep.department_name = request.POST['department_name']
        dep.department_code = request.POST['department_code']
        dep.save()
        return redirect('/manage_department')
    return render(request,'edit_department.html',{'dep':dep})

def delete_department(request,id):
    d = Department.objects.get(id=id)
    d.delete()
    return redirect('/manage_department')

def manage_products(request):
    products = Product.objects.all()
    for i in products:
        try:
            i.st = Stock.objects.get(product_id=i.id).stocks
        except:
            i.st = 0
    department = Department.objects.all()
    category = Category.objects.all()
    brand = Brand.objects.all()
    return render(request,'view_products.html',{'products':products,'department':department,'category':category,'brand':brand})

def employee_sales_history(request):
    data = Sales.objects.all()
    return render(request,'sales.html',{'data':data})



def add_product(request):
    cat = Category.objects.all()
    brand = Brand.objects.all()
    department = Department.objects.all()

    if request.method == 'POST':
        product_name = request.POST['product_name']
        BRAND = request.POST['BRAND']
        CATEGORY = request.POST['CATEGORY']
        department_id = request.POST['department_id']

        price = request.POST['price']


        product = Product()
        product.product_name = product_name
        product.BRAND = Brand.objects.get(id=BRAND)
        product.CATEGORY = Category.objects.get(id=CATEGORY)
        product.department_id = Department.objects.get(id=department_id)
        product.price = price
        product.threshold=request.POST['thersh']
        product.save()

        stck = Stock()
        stck.stocks = request.POST['quantity']
        stck.product_id = product
        stck.save()



        return redirect('/manage_products')

    return render(request, 'add product.html', {'cat': cat, 'brand': brand, 'department': department})


def view_employee(request):
    ob = Employee.objects.all()
    return render(request, 'view_employee.html',{'employees':ob})

def add_employeess(request):
    dep = Department.objects.all()
    return render(request, 'add_employee.html',{'dep':dep})

def add_employee_post(request):
    name=request.POST['name']
    Phone=request.POST['phone']
    employee_code=request.POST['employee_code']
    place=request.POST['place']
    pin=request.POST['pin']
    post=request.POST['post']
    email=request.POST['email']
    gender=request.POST['gender']
    photo=request.FILES['photo']
    department_id=request.POST['department_id']

    if Login.objects.filter(username = email).exists():
        return  HttpResponse("<script>alert('Email already exists');window.location='/add_employeess'</script>")

    log = Login()
    log.username = email
    log.password = Phone
    log.type = 'employee'
    log.save()


    fs=FileSystemStorage()
    fp=fs.save(photo.name,photo)

    ob=Employee()
    ob.name=name
    ob.LOGIN=log
    ob.Phone=Phone
    ob.employee_code=employee_code
    ob.place=place
    ob.pin=pin
    ob.post=post
    ob.gender=gender
    ob.email=email
    ob.photo=fp
    ob.department=Department.objects.get(id=department_id)
    ob.save()
    return redirect('/view_employee')



def flutter_login(request):
    print(request.POST)
    un = request.POST.get('username', '')
    pwd = request.POST.get('password', '')
    print(un, pwd)

    try:
        ob = Login.objects.get(username=un, password=pwd)  # Fetch user

        data = {"task": "valid", "lid": ob.id, "type": ob.type}
    except Login.DoesNotExist:
        data = {"task": "invalid"}

    r = json.dumps(data)
    print(r)
    return HttpResponse(r, content_type="application/json")

def employee_view_profile(request):
    lid = request.POST['lid']
    i = Employee.objects.get(LOGIN=lid)
    profile = {
        'id': str(i.id),
        'name': i.name,
        'Phone': str(i.Phone),
        'employee_code': str(i.employee_code),
        'photo': i.photo.url[1:],
        'place': str(i.place),
        'pin': str(i.pin),
        'post': str(i.post),
        'email': str(i.email),
        'gender': i.gender,
        'department_id': str(i.department.department_name),
    }
    return JsonResponse({'status': 'ok', 'profile': [profile]})

def employee_edit_profile(request):
    lid = request.POST['lid']
    i = Employee.objects.get(LOGIN=lid)
    i.name = request.POST['name']
    i.Phone = request.POST['Phone']
    i.place = request.POST['place']
    i.pin = request.POST['pin']
    i.post = request.POST['post']
    i.email = request.POST['email']
    i.gender = request.POST['gender']
    if 'photo' in request.FILES:
        photo = request.FILES['photo']
        fs = FileSystemStorage()
        fp = fs.save(photo.name, photo)
        i.photo = fp
    i.save()
    return JsonResponse({'status': 'ok'})

def delete_employee(request,id):
    em = Login.objects.get(id=id)
    em.delete()
    return HttpResponse('''
                                <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10">
                                <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
                                <script>
                                    document.addEventListener("DOMContentLoaded", function() {
                                        Swal.fire({
                                            icon: 'success',  
                                            title: 'Success',
                                            confirmButtonText: 'OK',
                                            reverseButtons: true
                                        }).then((result) => {
                                            if (result.isConfirmed) {
                                                window.location = '/view_employee';
                                            }
                                        });
                                    });
                                </script>
                            ''')


def edit_employee(request,id):
    em = Employee.objects.get(id=id)
    dep = Department.objects.all()
    if request.method == 'POST':
        em.name = request.POST['name']
        em.Phone = request.POST['Phone']
        em.employee_code = request.POST['employee_code']
        em.place = request.POST['place']
        em.pin = request.POST['pin']
        em.post = request.POST['post']
        em.email = request.POST['email']
        em.gender = request.POST['gender']
        dep = Department.objects.get(id=request.POST['department'])
        em.department = dep
        if 'photo' in request.FILES:
            photo = request.POST['photo']
            fs = FileSystemStorage()
            fp = fs.save(photo.name,photo)
            em.photo = fp
            em.save()
        em.save()
        return HttpResponse('''
                                        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10">
                                        <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
                                        <script>
                                            document.addEventListener("DOMContentLoaded", function() {
                                                Swal.fire({
                                                    icon: 'success',  
                                                    title: 'Updated',
                                                    confirmButtonText: 'OK',
                                                    reverseButtons: true
                                                }).then((result) => {
                                                    if (result.isConfirmed) {
                                                        window.location = '/view_employee';
                                                    }
                                                });
                                            });
                                        </script>
                                    ''')
    return render(request,'edit_employee.html',{'em':em,'dep':dep})


@csrf_exempt
def get_employee_department_products(request):
    if request.method == 'POST':
        data = json.loads(request.body)
        login_id = data.get('login_id')

        try:
            employee = Employee.objects.get(LOGIN_id=login_id)
            department = employee.department
            products = Product.objects.filter(department_id=department)

            products_list = [{
                'id': p.id,
                'name': p.product_name,
                'price': p.price
            } for p in products]

            return JsonResponse({
                'status': 'success',
                'department': department.department_name,
                'products': products_list
            })
        except Employee.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Employee not found'})
    return JsonResponse({'status': 'error', 'message': 'Invalid method'})


@csrf_exempt
def add_sale(request):
    print(request.POST,"_++++++_---=o-0ipjionnuhy875687689889")
    if request.method == 'POST':
        login_id = request.POST['login_id']
        product_id = request.POST['product_id']
        customer_name = request.POST['customer_name']
        quantity = int(request.POST['quantity'])

        try:
            employee = Employee.objects.get(LOGIN_id=login_id)
            product = Product.objects.get(id=product_id)

            # Ensure stock entry exists
            stock = Stock.objects.filter(product_id=product).first()
            if not stock:
                return JsonResponse({'status': 'error', 'message': 'Stock entry not found for this product'})

            if stock.stocks < quantity:
                return JsonResponse({'status': 'error', 'message': 'Insufficient stock'})

            # Create Order
            total = product.price * quantity
            order_obj = Orders.objects.create(
                customer_name=customer_name,
                product_id=product,
                employee_id=employee,
                quantity=quantity,
                total=total,
                date=datetime.now().date()
            )

            # Create Sale
            Sales.objects.create(
                ORDER=order_obj,
                Date=datetime.now().date(),
                Time=datetime.now().time(),
                Status='pending'
            )

            # Update Stock
            stock.stocks -= quantity
            stock.save()

            return JsonResponse({'status': 'success', 'message': 'Sale added successfully'})
        except Employee.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Employee not found'})
        except Product.DoesNotExist:
            return JsonResponse({'status': 'error', 'message': 'Product not found'})
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)})


def employee_view_sales(request):
    lid = request.POST['lid']
    employee = Employee.objects.get(LOGIN=lid)

    # Fetch sales history for the employee
    sales = Sales.objects.filter(ORDER__employee_id=employee,Status='completed')

    # Fetch order history for the employee
    orders = Orders.objects.filter(employee_id=employee)

    sales_data = []
    for i in sales:
        sales_data.append({
            'id': i.id,
            'Date': i.Date,
            'ORDER': i.ORDER.customer_name,
            'product_name': i.ORDER.product_id.product_name,
            'pid': i.ORDER.product_id.id,
            'total': i.ORDER.total,
        })

    order_data = []
    for order in orders:
        order_data.append({
            'id': order.id,
            'customer_name': order.customer_name,
            'product_name': order.product_id.product_name,
            'pid': order.product_id.id,
            'total': order.total,
            'date': order.date.strftime('%Y-%m-%d'),
        })

    return JsonResponse({'status': 'ok', 'sales_data': sales_data, 'order_data': order_data})

from .sms_file import sendmessage

def sendsms(request):
    url = request.POST['url']
    name = request.POST['name']
    phno = request.POST['phno']
    sendmessage(phno,"hai "+name+" please share your review through "+url)

    # {"url": baseUrl + "smsrating?pid=" + pid, "name": customerName, "phno": phoneNumberController.text.toString()},

    return JsonResponse({'status': 'ok',})

def sms_rating(request):
    pid=request.GET['pid']
    request.session['pid']=pid
    pob=Sales.objects.get(id=pid)
    return render(request,'customer_rating.html',{"val":pob})

def submit_review(request):
    re=request.POST['reviewText']
    rating=request.POST['rating']
    pob = Sales.objects.get(id=request.session['pid'])

    ob=feedback()
    ob.order_id=pob.ORDER
    ob.feedback=re
    ob.rating=rating
    ob.reply='pending'
    ob.save()
    return HttpResponse('''
                                            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/sweetalert2@10">
                                            <script src="https://cdn.jsdelivr.net/npm/sweetalert2@10"></script>
                                            <script>
                                                document.addEventListener("DOMContentLoaded", function() {
                                                    Swal.fire({
                                                        icon: 'success',  
                                                        title: 'Review Submitted',
                                                        confirmButtonText: 'OK',
                                                        reverseButtons: true
                                                    }).then((result) => {
                                                        if (result.isConfirmed) {
                                                            window.location = '/';
                                                        }
                                                    });
                                                });
                                            </script>
                                        ''')



def employee_view_noti(request):
    lid = request.POST['lid']
    employee = Employee.objects.get(LOGIN=lid)

    # Fetch sales history for the employee
    sales = Sales.objects.filter(ORDER__employee_id=employee).exclude(Status='pending')

    # Fetch order history for the employee
    orders = Orders.objects.filter(employee_id=employee)

    sales_data = []
    for i in sales:
        sales_data.append({
            'id': i.id,
            'Date': i.Date,
            'ORDER': i.ORDER.customer_name,
            'product_name': i.ORDER.product_id.product_name,
            'total': i.ORDER.total,
            'status': i.Status,
        })

    order_data = []
    for order in orders:
        order_data.append({
            'id': order.id,
            'customer_name': order.customer_name,
            'product_name': order.product_id.product_name,
            'total': order.total,
            'date': order.date.strftime('%Y-%m-%d'),
        })

    return JsonResponse({'status': 'ok', 'sales_data': sales_data, 'order_data': order_data})


def change_password(request):
    # Parse JSON data from Flutter
    data = json.loads(request.body)
    print(data,"opop")
    employee_id = data.get('employee_id')  # Assuming Flutter sends employee_id
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    print(Login.objects.filter(id = employee_id),"opop")
    Login.objects.filter(id = employee_id).update(password = new_password)
    return JsonResponse({'message': 'Password changed successfully'}, status=200)


def view_sales_notifications(request):
    if request.method == 'POST':
        try:
            # Parse the request body (optional login_id for manager verification)
            data = json.loads(request.body)
            login_id = data.get('login_id')  # Optional: Manager's login ID
            # Fetch all sales with Status='Pending'
            pending_sales = Sales.objects.filter(
                Status='Pending'
            ).select_related('ORDER', 'ORDER__employee_id', 'ORDER__product_id')

            s = Stock.objects.filter(stocks__lt = 2).count()
            print(s,"etyty")

            # Construct the response data
            notifications = [
                {
                    'sale_id': sale.id,
                    'order_id': sale.ORDER.id,
                    'customer_name': sale.ORDER.customer_name,
                    'product_name': sale.ORDER.product_id.product_name,
                    'quantity': sale.ORDER.quantity,
                    'total': sale.ORDER.total,
                    'date': sale.Date.strftime('%Y-%m-%d'),  # From Sales model
                    'time': sale.Time.strftime('%H:%M:%S'),  # From Sales model
                    'employee_name': sale.ORDER.employee_id.name,
                    'status': sale.Status,
                }
                for sale in pending_sales
            ]

            print(len(notifications))

            return JsonResponse({
                'status': 'success',
                'notifications': notifications,
                'count': len(notifications)+int(s)

            }, status=200)

        except json.JSONDecodeError:
            return JsonResponse({'status': 'error', 'message': 'Invalid JSON data'}, status=400)
        except Exception as e:
            return JsonResponse({'status': 'error', 'message': str(e)}, status=500)
    else:
        return JsonResponse({'status': 'error', 'message': 'Method not allowed'}, status=405)

def updatelocation(request):
    print(request.POST)
    lid=request.POST['lid']
    ob=SalesNoti.objects.filter(sales_id__ORDER__employee_id__LOGIN__id=lid)
    res=[]
    for i in ob:
        res.append(i.sales_id.id)
    ob=Sales.objects.filter(ORDER__employee_id__LOGIN__id=lid).exclude(id__in=res).exclude(Status='pending')
    if len(ob)>0:
        for i in ob:
            a=SalesNoti()
            a.sales_id=i
            a.save()

            return JsonResponse({'task': 'True',"s":ob[0].Status})
    return JsonResponse({'task': 'false'})