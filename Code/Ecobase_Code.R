#Ecobase - looking for similar models to use

#To get the list of available Ewe models

library(RCurl)
library(XML)
library(plyr)
library(dplyr)


#To obtain the list of available model
h=basicTextGatherer()
curlPerform(url = 'http://sirs.agrocampus-ouest.fr/EcoBase/php/webser/soap-client_3.php',writefunction=h$update)

data<-xmlTreeParse(h$value(),useInternalNodes=TRUE)
liste_mod<-ldply(xmlToList(data),data.frame)%>% filter(model.dissemination_allow =='true')

#liste_mod contains a list and decription of available models in EcoBase        

liste_mod 

#To get the INPUT values for model

library(RCurl)
library(XML)
library(plyr)

h=basicTextGatherer()
mymodel<-405 #look for model number on list created above or on website
curlPerform(url = paste('http://sirs.agrocampus-ouest.fr/EcoBase/php/webser/soap-client.php?no_model=',mymodel,sep=''),writefunction=h$update,verbose=TRUE)
data<-xmlTreeParse(h$value(),useInternalNodes=TRUE)
Australian_North_West_Coast_Model405_Input<-xpathSApply(data,'//group',function(x) xmlToList(x)) 
write.csv(Australian_North_West_Coast_Model405,"Data.csv")

#To get the OUTPUT values for model
library(RCurl)
library(XML)
library(plyr)

#To Obtain a model - output
h=basicTextGatherer()
mymodel<-405

curlPerform(url = paste('http://sirs.agrocampus-ouest.fr/EcoBase/php/webser/soap-client_output.php?no_model=',mymodel,sep=''),writefunction=h$update,verbose=TRUE)

data<-xmlTreeParse(h$value(),useInternalNodes=TRUE)

Australian_North_West_Coast_Model405_Output<-xpathSApply(data,'//group',function(x) xmlToList(x))
write.csv(Australian_North_West_Coast_Model405_Output,"Data.csv")
