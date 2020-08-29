---
title: Notes on Debugging a C Library
categories: [blog]
tags: [c, gcc, linux, libgd, nginx, image_resize_filter]
---

Notes on an investigation into a problem resizing certain PNGs using the [NGINX image filter module](https://raw.githubusercontent.com/nginx/nginx/master/src/http/modules/ngx_http_image_filter_module.c).

Transparency was going AWOL upon resize, viz:

- insert PNG

- insert PNG cropped bad

Following are some notes on how to attempt to debug the underlying [libgd library](https://libgd.github.io) used in the conversion.

This was running on a Fedora host:

````
$ sudo dnf groupinstall "Development Tools"
$ sudo dnf install libpng-devel libjpeg-devel gdb
$ git clone https://github.com/libgd/libgd
$ cd libgd
$ ./configure CFLAGS="-g -O0"
$ make
$ sudo make install
$ echo '/usr/local/lib' | sudo tee /etc/ld.so.conf.d/usr-local.conf
$ sudo ldconfig
$ ldconfig -p | grep libgd.so
libgd.so.3 (libc6,x86-64) => /usr/local/lib/libgd.so.3
libgd.so.3 (libc6,x86-64) => /lib64/libgd.so.3
libgd.so (libc6,x86-64) => /usr/local/lib/libgd.so
````

Create a test file that roughly follows the code paths used by Nginx usage:

````
$ mkdir /tmp/png && cd /tmp/png
$ cp ... source.png
$ gcc -o example -lgd -lpng  -lm example.c && ./example
````

example.c

````
/* Bring in gd library functions */
#include "gd.h"

/* Bring in standard I/O so we can output the PNG to a file */
#include <stdio.h>

int main() {
  /* Declare the image */
  gdImagePtr src, dest;
  int red, green, blue, transparent;

  /* Declare output files */
  FILE *pngout;

  pngout = fopen("test.png", "wb");

  src = gdImageCreateFromFile("goldbar1.png");
  transparent = gdImageGetTransparent(src);
  red = gdImageRed(src, transparent);
  blue = gdImageBlue(src, transparent);
  green = gdImageGreen(src, transparent);

  printf("Transparent: %d, R:%d, G:%d, B:%d\n", transparent, red, green, blue);

  dest = gdImageCreate(256, 256);
  // dest = gdImageCreateTrueColor(256, 256);
  // gdImageSaveAlpha(dest, 1);
  // gdImagePaletteToTrueColor(src);

  // gdImageCopyResampled(dest, src, 0, 0, 0, 0, 256, 256, 512, 512);
  gdImageCopyResized(dest, src, 0, 0, 0, 0, 256, 256, 512, 512);

  // gdImageTrueColorToPalette(dest, 1, 256);

  gdImageColorTransparent(dest, gdImageColorExact(dest, red, green, blue));

  gdImagePng(dest, pngout);

  printf("Transparent out: %d\n", gdImageGetTransparent(dest));
  /* Close the files. */
  fclose(pngout);

  /* Destroy the image in memory. */
  gdImageDestroy(src);
  gdImageDestroy(dest);
}
````



GDB 
---

Useful commands:

- p (print - variable info)
- b (break - add a break point)
- s (step - next)
- n (next - step over)
- c (continue)
- u (until - run past the current line)
- f (function - run until function ends)

$ gdb example
$ break 1
$ run
Breakpoint 1, main () at example.c:15
15	  pngout = fopen("test.png", "wb");
$


Epitaph
=======

I raised an issue in the LibGD project <https://github.com/libgd/libgd/pull/639>, but as per the clarification from the project maintainers the focus should turn to the implementation of the Nginx Image Filter Module which calls "gdImageCopyResampled" instead of the suggested "gdImageScale" to retain transparency.

<https://github.com/nginx/nginx/blob/master/src/http/modules/ngx_http_image_filter_module.c>