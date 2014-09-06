library(shiny)
library(readbitmap)
library(plyr)
library(ggplot2)

# Define server logic required to plot various variables against mpg
shinyServer(function(input, output,session) {
  # image taken from http://rsb.info.nih.gov/ij/plugins/example-plot.html  
  output$inplot<-renderImage({
    fname=input$fname
    if (is.null(fname))
      list(src=NULL,alt="Please select a file")
    #fname="c:/temp/images.jpg"
    list(src=fname$datapath,alt=fname)
    },deleteFile=FALSE)
  

    
  getpointlist<-reactive({
    rgblist=c("r","g","b")
    fname=input$fname
    if (is.null(fname))
      return(NULL)
    imsource=read.bitmap(fname$datapath)
    imheight=dim(imsource)[1]
    imwidth=dim(imsource)[2]
    rgbt=dim(imsource)[3]
    
    
    #first split out the color vectors
    pointlist=imsource
    #convert the mXnX3 array into an m*nX3 array
    dim(pointlist)<-c(imheight*imwidth,rgbt)
    #convert to a data frame and add names for the rgb values
    pointlist<-as.data.frame(pointlist)
    #check if the rgb vector has a transparency element as well
    if (rgbt==3) names(pointlist)<-rgblist else
      names(pointlist)<-c("r","g","b","t")
    
    
    #add x and y values, y changes most rapidly
    pointlist$y=-seq(1:imheight)
    pointlist$x=rep(seq(1:imwidth),each=imheight)
    pointlist[,rgblist]=round(pointlist[,rgblist]*255)
    #now create a column with the composite rgb value
    #there are slow ways to do this and faster ways to do this
    
    #pointlist$rgb=apply(pointlist[,c("r","g","b")],1,merge_rgb) #5 sec
    #pointlist$rgb=apply(pointlist[,c("r","g","b")],1,sprintf,fmt="#%02x") #1 second
    rgbdecimal=apply(pointlist[,rgblist],1,crossprod,c(256*256,256,1)) #fastest
    pointlist$rgb=rgbdecimal
#     pointlist$rgb<-lapply(rgbdecimal,sprintf,fmt="%06x")
#     pointlist$rgb<-as.factor(pointlist$rgb)
    return(pointlist)
  })
chunkcolors<-reactive({
  rgblist=c("r","g","b")
  pointlist=getpointlist()
  if (is.null(pointlist))
    return(NULL)
#     color_prevalence=sort(table(pointlist$rgb),decreasing=T)
#     color_cutoff=10000000
#     if (length(color_prevalence)>color_cutoff) {
#       colors_to_use=names(color_prevalence[1:color_cutoff])
#       newpointlist<-pointlist[pointlist$rgb %in% colors_to_use,]
#       pointlist=newpointlist
#     }
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
    palette=(sprintf("%06x",used_colors$rgb))
    pointlist$cluster=as.factor(unique_colors$cluster[match(pointlist$rgb,unique_colors$rgb)])
    pointlist$cluster<-factor(pointlist$cluster,levels=used_colors$cluster,labels=used_colors$rgb)
    levels(pointlist$cluster)<-as.hexmode(as.numeric(levels(pointlist$cluster)))
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
  pointlist<-chunkcolors()
  if (is.null(pointlist))
    return (NULL)
  colchoice=as.numeric(input$colors)
  used_colors<-levels(pointlist$cluster)[colchoice]
  #names(used_colors)<-c("rgb")
  palette=(sprintf("#%s",used_colors))
#  usedco=(sprintf("%06x",used_colors))
#   downsample=20000
#   newpoint_index=sample(seq(nrow(pointlist)),downsample)
#   #newpointlist=pointlist[newpoint_index,]
#   newpointlist=pointlist
#   levels(pointlist$cluster)<-as.hexmode(as.numeric(levels(pointlist$cluster)))
  p<-ggplot(pointlist[pointlist$cluster %in% used_colors,],aes(x,y,color=cluster),size=.01)+geom_point()+
    facet_wrap( ~ cluster)+
    scale_color_manual(values=palette)+
    theme(legend.position="none")
    
  return(p)
  
})
  output$outplot<-renderPlot({
  a<-plotpoints()
  if (is.null(a))
    return(NULL)
  a
    })
output$noise=renderText({
  
  outputOptions(output,"inplot")
})
output$saveresults=downloadHandler(
  filename = function() { paste(input$fname, '.rda', sep='')}, 
  content = function(file) {
    pointlist=chunkcolors()
    colchoice=as.numeric(input$colors)
    used_colors<-levels(pointlist$cluster)[colchoice]
    #names(used_colors)<-c("rgb")
    
    data=pointlist[pointlist$cluster %in% used_colors,]
    save(data, file=file,compress='gzip')
    })
  


})