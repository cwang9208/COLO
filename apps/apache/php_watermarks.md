# Image Processing and GD
## Introduction
PHP is not limited to creating just HTML output. It can also be used to create and manipulate image files in a variety of different image formats, including GIF, PNG, and JPEG. Even more conveniently, PHP can output image streams directly to a browser. You will need to compile PHP with the GD library of image functions for this to work.

## Installing/Configuring
### Installation
To enable GD-support configure PHP `--with-gd[=DIR]`, where DIR is the GD base install directory. To use the recommended bundled version of the GD library, use the configure option `--with-gd`. GD library requires libpng and libjpeg to compile (`apt-get install libpng12-dev libjpeg-dev`).

Image Format | Configure Switch
------------ | -------------
*jpeg* | To enable support for jpeg add `--with-jpeg-dir=DIR`.
*png* | To enable support for png add `--with-png-dir=DIR`.

## Examples

### Adding watermarks to images

```
<?php
// Load the stamp and the photo to apply the watermark to
$stamp = imagecreatefrompng('stamp.png');
$im = imagecreatefromjpeg('photo.jpeg');

// Set the margins for the stamp and get the height/width of the stamp image
$marge_right = 10;
$marge_bottom = 10;
$sx = imagesx($stamp);
$sy = imagesy($stamp);

// Copy the stamp image onto our photo using the margin offsets and the photo 
// width to calculate positioning of the stamp. 
imagecopy($im, $stamp, imagesx($im) - $sx - $marge_right, imagesy($im) - $sy - $marge_bottom, 0, 0, imagesx($stamp), imagesy($stamp));

// Output and free memory
header('Content-type: image/png');
imagepng($im);
imagedestroy($im);
?>
```
Use your browser to access the file with your web server's URL, ending with the */watermarks.php* file reference. When developing locally this URL will be something like *http://localhost/watermarks.php* or *http://127.0.0.1/watermarks.php* but this depends on the web server's configuration.

The above example will output something similar to:

![watermarks](watermarks.png)
