library(shiny)
library(readbitmap)
library(plyr)
library(ggplot2)

# Define server logic required to plot various variables against mpg
shinyServer(function(input, output,session) {
  # image taken from http://rsb.info.nih.gov/ij/plugins/example-plot.html  
  output$inplot<-renderImage({
    fname=input$fname
    #fname="c:/temp/images.jpg"
    a=list(src=fname,alt=fname)
#    return(a)
    },deleteFile=FALSE)
  
#   output$outplot<-renderPlot({
#     #input$loadFile
#     plot(rnorm(10),rnorm(10))
#   })
  output$noise=renderText({
    
    rgblist=c("r","g","b")
    fname=input$fname
    imsource=read.bitmap(fname)
    imheight=dim(imsource)[1]
    imwidth=dim(imsource)[2]
    rgbt=dim(imsource)[3]
    
    
    #first split out the color vectors
    pointlist=imsource
    #convert the mXnX3 array into an m*nX3 array
    dim(pointlist)<-c(imheight*imwidth,rgbt)
    #convert to a data frame and add names for the rgb values
    pointlist<-as.data.frame(pointlist)
    if (rgbt==3) names(pointlist)<-rgblist else
      names(pointlist)<-c("r","g","b","t")
    
    
    #add x and y values, y changes most rapidly
    pointlist$y=-seq(1:imheight)
    pointlist$x=rep(seq(1:imwidth),each=imheight)
    pointlist[,c("r","g","b")]=round(pointlist[,rgblist]*255)
    #pointlist$rgb=apply(pointlist[,c("r","g","b")],1,merge_rgb) #5 sec
    #pointlist$rgb=apply(pointlist[,c("r","g","b")],1,sprintf,fmt="#%02x") #1 second
    pointlist$rgb=apply(pointlist[,rgblist],1,crossprod,c(256*256,256,1)) #fastest
    color_prevalence=sort(table(pointlist$rgb),decreasing=T)
    color_cutoff=10000000
    if (length(color_prevalence)>color_cutoff) {
      colors_to_use=names(color_prevalence[1:color_cutoff])
      newpointlist<-pointlist[pointlist$rgb %in% colors_to_use,]
      pointlist=newpointlist
    }
    numcolors=input$clusters
    unique_colors=unique(pointlist[,rgblist])
    unique_colors$rgb=apply(unique_colors[,rgblist],1,crossprod,c(256*256,256,1))

    color_cluster=hclust(dist(unique_colors[rgblist],method="manhattan"))
    unique_colors$cluster=cutree(color_cluster,numcolors)
    
    #used_colors=as.data.frame(unique_colors$rgb[match(seq(numcolors),unique_colors$cluster)])
    used_colors=as.data.frame(unique_colors[match(seq(numcolors),unique_colors$cluster),])
#     color_kmean=kmeans(unique_colors,numcolors)
#     unique_colors$cluster=color_kmean$cluster
#      
#     used_colors=as.data.frame(floor(color_kmean$centers+0.5))
#     
    palette=(sprintf("#%06x",used_colors$rgb))
    pointlist$cluster=as.factor(unique_colors$cluster[(match(pointlist$rgb,unique_colors$rgb))])

    #listcolors=apply(colors,1,merge_rgb)
    print(used_colors)  
    print(class(used_colors))
    names=sprintf("%06x",used_colors$rgb)
    #cb_options=list()
    #cb_options[names]=seq(1:numcolors)
    cb_options=seq(1:numcolors)
    names(cb_options)<-names
    
    #cb_options[["a"]]="a"
    #cb_options[["b"]]="b"
    
    updateCheckboxGroupInput(session=session,"colors",choices=cb_options,selected=sprintf("%d",cb_options[2:numcolors]),inline=T)
    #numcolors
    
print("asdf")

  output$outplot<-renderPlot({
      colchoice=as.numeric(input$colors)
      palette=(sprintf("#%06x",used_colors$rgb[colchoice]))
      downsample=20000
      newpoint_index=sample(seq(nrow(pointlist)),downsample)
      #newpointlist=pointlist[newpoint_index,]
      newpointlist=pointlist
      p<-ggplot(newpointlist[newpointlist$cluster %in% colchoice,],aes(x,y,color=cluster),size=.01)+geom_point()+
        facet_wrap( ~ cluster)+
        scale_color_manual(values=palette)
      return(p)
    })
  })
  
  


})