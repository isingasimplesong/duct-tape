#!/usr/bin/env python3
import sys

import qrcode


def generate_qr_code(data, output_file="qrcode.png"):
    # Créer un objet QRCode
    qr = qrcode.QRCode(
        version=1,  # Taille du QR code
        error_correction=qrcode.constants.ERROR_CORRECT_L,  # Niveau de correction d'erreurs
        box_size=10,  # Taille de chaque boîte dans le QR code
        border=4,  # Taille de la bordure
    )
    qr.add_data(data)
    qr.make(fit=True)
    img = qr.make_image(fill="black", back_color="white")
    img.save(output_file)


def main():
    if len(sys.argv) != 3 or sys.argv[1] != "--string":
        print("Usage: qr_make.py --string <my_string>")
        sys.exit(1)

    string = sys.argv[2]
    generate_qr_code(string)
    print("QR Code généré et sauvegardé sous 'qrcode.png'")


if __name__ == "__main__":
    main()
