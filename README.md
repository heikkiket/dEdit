# Dedit
A simple text editor in D

This is just a hobby/learning project about how text editors and terminal programs actually work.
Whole program is actually just a re-implementation of Kilo editor by snaptoken: https://viewsourcecode.org/snaptoken/kilo/, which in turn is just a commented version of Antirez's Kilo editor: http://antirez.com/news/108

Program has a mix of rude c-style code and some object-oriented thinking in saving the text buffer.
Parts talking with terminal use C standard functions, but otherwise D is used extensively. The coolest part of the code is D string/array operations that are used a lot. They make writing this kind of editor so much easier!

## Installation instructions

When you have cloned this repository to a directory in your machine, do a 
 `dub build`
command.
After that you can run the program with
 `./editor2 <filename>`

Some test files are provided, so do
 `/editor2 lipsum.txt`
 
Comments and pull requests welcome!
