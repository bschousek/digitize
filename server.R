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
    if (is.null(fname)) {return(list(src="plot.png"))}
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
      colchoice=input$colors
      used_colors<-levels(pointlist$cluster)[colchoice]
      data=pointlist[pointlist$cluster %in% used_colors,]
      data$cluster<-factor(data$cluster)
      save(data, file=file,compress='gzip')
  })
  
  

  #load image and convert to data frame with x,y points and colors
  getpointlist<-reactive({
    rgblist=c("r","g","b")
    fname=input$fname
    if (is.null(fname)) {
        imsource=read.bitmap('plot.png')
    } else {
        imsource=read.bitmap(fname$datapath)
    }
    
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
    palette=(sprintf("%06x",centers$rgb))
    pointlist$cluster=as.factor(unique_colors$cluster[match(pointlist$rgb,unique_colors$rgb)])
    pointlist$cluster<-factor(pointlist$cluster,levels=centers$Group.1,labels=centers$rgb)
    pointlist$display<-pointlist$cluster %in% palette[2:numcolors]
    cb_options=palette
    names(cb_options)<-palette
      
    updateCheckboxGroupInput(session=session,"colors",choices=cb_options,selected=sprintf("%s",cb_options[2:numcolors]),inline=T)
    #colchoice=as.numeric(input$colors)
    
    
return(pointlist)
})
#choose which colors to plot
displaycolors<-reactive({
    pointlist<-cutcolors()
    colchoice=input$colors
    #don't return a value if nothing clustered yet, or if the slider has changed and not yet
    # updated the checkbox group.
    if (is.null(colchoice) || !all(colchoice %in% levels(pointlist$cluster))){ return()}
        
    pointlist$display<-pointlist$cluster %in% colchoice
    return(pointlist)
})

#finally plot them
plotpoints<-reactive({
  pointlist<-displaycolors()
  if (is.null(pointlist))
    return (NULL)
  used_colors<-levels(pointlist$cluster[pointlist$display==T])
  palette=(sprintf("#%s",used_colors))
  
  p<-ggplot(pointlist[pointlist$display==T,],aes(x,y,color=cluster),size=.01)+geom_point()+
    facet_wrap( ~ cluster)+
    scale_color_manual(values=palette)+
    theme(legend.position="none")+
      ylab("")+xlab("")
  #,axis.text.x=element_blank(),axis.text.y=element_blank())
    
  return(p)
  
})

})