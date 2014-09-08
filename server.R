library(shiny)
if (!require(readbitmap)) {
  ## added to get this to run on the shiny server at work
  local({r <- getOption("repos")
         r["CRAN"] <- "http://cran.r-project.org" 
         options(repos=r)
  })
  install.packages("readbitmap")
  require(readbitmap)
}
library(plyr)
library(ggplot2)

shinyServer(function(input, output,session) {

  output$inplot<-renderImage({
    fname=input$fname
    if (is.null(fname)) {return(list(src="test",alt="Please select a file"))}
    list(src=fname$datapath,alt=fname)
  },deleteFile=FALSE)
  
  output$outplot<-renderPlot({
    a<-plotpoints()
    if (is.null(a))
      return(NULL)
    a
  })
  
  
  output$saveresults=downloadHandler(
    filename = function() { paste(input$fname, '.rda', sep='')}, 
    content = function(file) {
      pointlist=cutcolors()
      colchoice=as.numeric(input$colors)
      used_colors<-levels(pointlist$cluster)[colchoice]
      data=pointlist[pointlist$cluster %in% used_colors,]
      data$cluster<-factor(data$cluster)
      save(data, file=file,compress='gzip')
  })
  
  

  #load image and convert to data frame with x,y points and colors
  getpointlist<-reactive({
    rgblist=c("r","g","b")
    fname=input$fname
    if (is.null(fname)) {return(NULL)}
    
    imsource=read.bitmap(fname$datapath)
    imheight=dim(imsource)[1]
    imwidth=dim(imsource)[2]
    rgbt=dim(imsource)[3]
    
    #first split out the color vectors
    #convert the mXnX3 array into an m*nX3 array
    dim(imsource)<-c(imheight*imwidth,rgbt)
    #convert to a data frame and add names for the rgb values
    imsource<-as.data.frame(imsource)
    #check if the rgb vector has a transparency element as well
    if (rgbt==3) names(imsource)<-rgblist else
      names(imsource)<-c("r","g","b","t")
    
    #add x and y values, y changes most rapidly
    imsource$y=-seq(1:imheight)
    imsource$x=rep(seq(1:imwidth),each=imheight)
    #bring the rgb values up to 0-255 instead of 0-1
    imsource[,rgblist]=round(imsource[,rgblist]*255)
    
    #now create a column with the composite rgb value
    #there are slow ways to do this and faster ways to do this
    #imsource$rgb=apply(imsource[,c("r","g","b")],1,merge_rgb) #5 sec
    #imsource$rgb=apply(imsource[,c("r","g","b")],1,sprintf,fmt="#%02x") #1 second
    rgbdecimal=apply(imsource[,rgblist],1,crossprod,c(256*256,256,1)) #fastest
    imsource$rgb=rgbdecimal
    return(imsource)
  })
  
  #perform hierarchical cluster analysis on the imported data
  chunkcolors<-reactive({
    rgblist=c("r","g","b")
    pointlist=getpointlist()
    if (is.null(pointlist)) {return(NULL)}

    unique_colors=pointlist[match(unique(pointlist$rgb),pointlist$rgb),]
    color_cluster=hclust(dist(unique_colors[rgblist],method="manhattan"))
    return(color_cluster)
  })
  #slice the data at chosen number of clusters
  cutcolors<-reactive({
    rgblist=c("r","g","b")
    numcolors=input$clusters
    pointlist<-getpointlist()
    color_cluster<-chunkcolors()
    
    if (is.null(color_cluster)) {return(NULL)}
    if (is.null(pointlist)) {return(NULL)}
    unique_colors=pointlist[match(unique(pointlist$rgb),pointlist$rgb),]
    unique_colors$cluster=cutree(color_cluster,numcolors)
      
    centers=aggregate(unique_colors[,rgblist],by=list(unique_colors$cluster),FUN=mean)
    centers[,rgblist]=floor(centers[,rgblist]+.5)
    rgbdecimal=apply(centers[,rgblist],1,crossprod,c(256*256,256,1)) #fastest
    centers$rgb=rgbdecimal
    centers$rgb<-as.hexmode(centers$rgb)
    #used_colors=as.data.frame(unique_colors$rgb[match(seq(numcolors),unique_colors$cluster)])
    #  used_colors=as.data.frame(unique_colors[match(seq(numcolors),unique_colors$cluster),])
  #     color_kmean=kmeans(unique_colors,numcolors)
  #     unique_colors$cluster=color_kmean$cluster
  #      
  #     used_colors=as.data.frame(floor(color_kmean$centers+0.5))
  #     
      palette=(sprintf("%06x",centers$rgb))
      pointlist$cluster=as.factor(unique_colors$cluster[match(pointlist$rgb,unique_colors$rgb)])
      pointlist$cluster<-factor(pointlist$cluster,levels=centers$Group.1,labels=centers$rgb)
      #levels(pointlist$cluster)<-as.hexmode(as.numeric(levels(pointlist$cluster)))
  #pointlist$rgb<-as.factor(pointlist$rgb)#,levels=used_colors$cluster,labels=palette)
  
  #b=factor(pointlist$cluster,levels=used_colors$cluster,labels=used_colors$rgb)
  
  
      #listcolors=apply(colors,1,merge_rgb)
      cb_options=seq(1:numcolors)
      names(cb_options)<-palette
      
      updateCheckboxGroupInput(session=session,"colors",choices=cb_options,selected=sprintf("%d",cb_options[2:numcolors]),inline=T)
    #numcolors
    
return(pointlist)
})
plotpoints<-reactive({
  pointlist<-cutcolors()
  if (is.null(pointlist))
    return (NULL)
  colchoice=as.numeric(input$colors)
  used_colors<-levels(pointlist$cluster)[colchoice]
  palette=(sprintf("#%s",used_colors))
  p<-ggplot(pointlist[pointlist$cluster %in% used_colors,],aes(x,y,color=cluster),size=.01)+geom_point()+
    facet_wrap( ~ cluster)+
    scale_color_manual(values=palette)+
    theme(legend.position="none")
    
  return(p)
  
})

})