#!/usr/bin/python
import sys
from validate_email import validate_email
if (validate_email('examp-^*(&le@example.com')) :
	sys.exit(1);
else:
	sys.exit(2);
