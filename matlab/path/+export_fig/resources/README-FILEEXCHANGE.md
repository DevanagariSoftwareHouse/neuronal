This function saves a figure or single axes to one or more vector and/or bitmap file formats, and/or outputs a rasterized version to the workspace, with the following features: 

- Figure/axes reproduced as it appears on screen 
- Cropped/padded borders (optional) 
- Embedded fonts (vector formats) 
- Improved line and grid line styles 
- Anti-aliased graphics (bitmap formats) 
- Render images at native resolution (optional for bitmap formats) 
- Transparent background supported (pdf, eps, png, tiff, gif) 
- Semi-transparent patch objects supported (png, tiff) 
- RGB, CMYK or grayscale output (CMYK only with pdf, eps, tiff) 
- Variable image compression, including lossless (pdf, eps, jpg) 
- Optional rounded line-caps (pdf, eps) 
- Optionally append to file (pdf, tiff, gif) 
- Vector formats: pdf, eps, emf, svg
- Bitmap formats: png, tiff, jpg, bmp, gif, clipboard, export to workspace 
- XKCD hand-drawn rendering style option

This function is especially suited to exporting figures for use in publications and presentations, because of the high quality and portability of media produced. 

Basic syntax: export\_fig(filename, [handle], options...)

- For a list of available options, run: `help export_fig` or: `doc export_fig` or read here: [https://github.com/altmany/export\_fig/blob/master/SYNTAX](https://github.com/altmany/export_fig/blob/master/SYNTAX)
- For usage examples, tips and detailed explanations, read [https://github.com/altmany/export\_fig/blob/master/README.md](https://github.com/altmany/export_fig/blob/master/README.md) 
- A technical description of the various components can be found at [https://undocumentedmatlab.com/articles/export\_fig](https://undocumentedmatlab.com/articles/export_fig) 

Notes:

- Background color and figure dimensions are reproduced (the latter approximately, and ignoring cropping & magnification) in the output file. For transparent background (and semi-transparent patch objects), use the -transparent option, and set the axes 'Color' property to 'none' where desired. Only some image formats support a transparent background, and only png/tiff support transparency of patch objects. 
- When exporting to vector format (pdf & eps), and to bitmap using the painters renderer, ghostscript ([http://ghostscript.com](http://ghostscript.com)) needs to be installed on your system 
- When exporting to eps, the pdftops program, a part of the Xpdf package, also needs to be installed. You can download this from [http://xpdfreader.com](http://xpdfreader.com) 
- This submission was originally created by Oliver Woodford. Yair Altman maintains this utility since Jan 2015.
- A single textual ad message is displayed once a week. I have no intention of removing the ad; if you don't want to see even a single ad once a week, don't use the program.

Report any problem or issue via GitHub: [https://github.com/altmany/export\_fig/issues](https://github.com/altmany/export_fig/issues) - not here