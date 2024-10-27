#!/usr/bin/env python3

import os
import qrcode

img = qrcode.make(input("string: "))

qr_path = os.path.expanduser("~/code_qr.png")
img.save(qr_path, "PNG")

os.system("xdg-open " + qr_path)
exit()
