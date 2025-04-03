
from twilio.rest import Client
def sendmessage(ph,msg):
	# Your Account Sid and Auth Token from twilio.com / console
	account_sid = ''
	auth_token = ''

	client = Client(account_sid, auth_token)

	''' Change the value of 'from' with the number 
	received from Twilio and the value of 'to' 
	with the number in which you want to send message.'''
	message = client.messages.create(
								from_='+17653024792',
								body =msg,
								to ='+91'+ph
							)

	print(message.sid)



