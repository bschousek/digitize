helpfile
========================================================
author: 
date: 

First Slide
========================================================

     hr(),
     h2("Instructions"),
     HTML("This app aids in reproducing collected data from plots which have been saved as images.<br>
     1) Upload a file using the  'choose file' button. The image will show up in the left column. 
         The image can be uploaded from the local file system or from a URL.
         For an example, try the following file from the Python sympy documentation, found via a Google image search for 'plot':<br>"),
 
     h5("http://i.imgur.com/7P2zwmT.png (enter this URL into the filename field from the choose file dialog.)" ),
     HTML("
     2) The right column will show the results of breaking the input image into its constituent colors
         as identified by the hclust function for hierarchical cluster analysis.<br>
     3) The level at which the cluster map is cut can be adjusted using the slider. Adjust the slider until
          the displayed plots include isolated versions of the data of interest.<br>
     4) The colors displayed can be turned on and off with the checkboxes under 'Colors to Display'.
          By default the most common color in the image (assumed to be the background color) is not displayed.<br>
     5) Clicking the 'Download' button will save the data represented by the displayed plots as an R .rda file.
         Depending on the OS and browser used, this file will most likely end up in a 'Downloads' folder.
          ")

Slide With Code
========================================================


```r
summary(cars)
```

```
     speed           dist    
 Min.   : 4.0   Min.   :  2  
 1st Qu.:12.0   1st Qu.: 26  
 Median :15.0   Median : 36  
 Mean   :15.4   Mean   : 43  
 3rd Qu.:19.0   3rd Qu.: 56  
 Max.   :25.0   Max.   :120  
```

Slide With Plot
========================================================

![plot of chunk unnamed-chunk-2](helpfile-figure/unnamed-chunk-2.png) 
