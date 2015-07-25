#!/usr/bin/python

import csv 
import sys
import smtplib 
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from validate_email import validate_email
import re
import getpass

fp = open('message.html', 'rb')
html = fp.read()
fp.close()
msg = MIMEMultipart('alternative')
msg['Subject'] = str(sys.argv[5])
msg['From'] = "Adimanav Studios"
#msg.attach(MIMEText(html, 'html'))

server = smtplib.SMTP(str(sys.argv[1]))
server.starttls()
senderMail = str(sys.argv[2])
password = str(sys.argv[3])
try:
	server.login(senderMail, password)
except smtplib.SMTPAuthenticationError:
	server.quit()
else:
	#email_data = csv.reader(open('email.csv', 'rb'))
	with open(str(sys.argv[4]), 'rb') as csvfile:
		email_data = csv.reader(csvfile)
		email_pattern= re.compile("^.+@.+\..+$")
		for row in email_data:
			if( email_pattern.search(row[1]) ):
				del msg
				msg = MIMEMultipart('alternative')
				msg['Subject'] = str(sys.argv[5])
				msg['From'] = "Adimanav Studios"
				msg['To'] = row[1]
				html2 = html.replace("MyPerspectiveCustomer", row[0])
				msg.attach(MIMEText(html2, 'html'))
				#print(row[1])
				if ( validate_email(row[1]) ):
					try:
						server.sendmail("Adimanav Studios", [row[1]], msg.as_string())
					except SMTPException:
						print "An error occured."
server.quit()
