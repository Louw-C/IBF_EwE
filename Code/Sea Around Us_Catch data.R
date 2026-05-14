#Initial exploration of Sea Around Us catch reconstruction data - 1950-2019

#Load the sea around us catch reconstruction data
SAU_Catch<-read.csv(file.choose(),header=T,sep=",")
names(SAU_Catch)

#Plot total annual catch in tonnes across the different years

SUA_Total<-ggplot(SAU_Catch, aes(factor(year), tonnes))+
  geom_col()+
  labs(y = "Total tonnes per annum")+
  theme(legend.title = element_blank(),legend.text = element_text(size=11, face="italic"),panel.background = element_blank(),panel.grid.major=element_line(0.5, colour="Gray80"),
        axis.text.x = element_text(size=11, angle=90, vjust=0.3),axis.title.x=element_blank(),
        axis.text.y= element_text(size=11), axis.title.y= element_text(size=11))
SUA_Total

