rm(list=ls())  # 清除环境变量
# 设置工作路径
# library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd() Rstudio特有功能

library(tidyverse)
library(ggsci)
library(ggh4x)

# 加载 .rda 文件
load("data.Rdata")

df$age <- factor(df$age,levels=c(df$age %>% as.data.frame() %>% distinct() %>% filter(.!="5 to 9") %>% 
                                   dplyr::rename(age=".") %>% 
                                   add_row(age="5 to 9",.before = 2) %>% pull()
))


df$year <- factor(df$year,levels=c("1990","2010"))


df %>% arrange(year) %>% filter(measure=="DALYs rate (per 100k)",sex=="Male") %>% 
  unite(.,col="location",location,measure,sep=" ",
        remove = T,na.rm = F) %>% 
  ggplot()+
  geom_line(aes(val,age),size=2.5,color="grey80")+
  geom_point(aes(val,age,color=year),size=4)+
  facet_wrap2(vars(location), nrow = 2, ncol = 3, trim_blank = FALSE)+
  xlab(NULL)+ylab(NULL)+
  scale_color_manual(values = c("#009688","#762a83"))+
  theme_bw()+
  theme(
    axis.title.y = element_blank(),
    axis.ticks.y = element_blank(),
    axis.ticks.x = element_line(color = "#4a4e4d"),
    axis.text=element_text(color="black",face="bold"),
    strip.text = element_text(color="black",face="bold"),
    panel.background = element_rect(fill = "white",color = "white"),
    plot.background = element_rect(fill = "white"),
    panel.spacing = unit(0,"lines"),
    plot.title = element_blank(),
    legend.text = element_text(color="black",face="bold"),
    legend.title = element_blank(),
    legend.key=element_blank(),  
    legend.spacing.x=unit(0.1,'cm'), 
    legend.key.width=unit(0.4,'cm'), 
    legend.key.height=unit(0.4,'cm'), 
    legend.background=element_blank(), 
    legend.position = c(0.07,1), legend.justification = c(1,1))
