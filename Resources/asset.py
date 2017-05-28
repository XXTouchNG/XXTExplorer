#!/usr/bin/python

from PIL import Image
import os.path
import sys

def thumb(ori, px_1):
    img = Image.open(ori)
    for i in range(3, 0, -1):
        img.thumbnail((px_1 * i, px_1 * i), Image.ANTIALIAS)
        if i == 1:
            saveToPath = ori[:-4] + ".png"
        else:
            saveToPath =  ori[:-4] + "@" + str(i) + "x.png"
        img.save(saveToPath, "png")

if __name__ == '__main__':
    thumb(sys.argv[1], int(sys.argv[2]))
