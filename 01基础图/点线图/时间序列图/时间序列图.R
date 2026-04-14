rm(list=ls())  # 清除环境变量  
# 设置工作路径
library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd()


#安装包
# install.packages("ggplot2")
# install.packages("ggprism")
#加载包
library(ggplot2)
library(ggprism)
#加载数据
df <- read.table(file="data.txt",sep="\t",header=T,check.names=FALSE)
####绘图
#Jan
p1<-ggplot(df)+
  geom_line(aes(date, Jan),size=0.8,color="red")+
  theme_prism(palette = "candy_soft",#主题设置
              base_fontface = "plain", 
              base_family = "serif", 
              base_size = 16,  
              base_line_size = 0.8, 
              axis_text_angle = 45)+
  scale_x_continuous(breaks=seq(1,31, 3))+#设置X轴标签范围及间隔
  labs(title = "Jan", # 定义主标题
       x = "Date", # 定义x轴文本
       y = "Value")# 定义y轴文本
p1
#Feb
p2<-ggplot(df)+
  geom_line(aes(date, Feb),size=0.8,color="green")+
  theme_prism(palette = "candy_soft",#主题设置
              base_fontface = "plain", 
              base_family = "serif", 
              base_size = 16,  
              base_line_size = 0.8, 
              axis_text_angle = 45)+
  scale_x_continuous(breaks=seq(1,31, 3))+#设置X轴标签范围及间隔
  labs(title = "Feb", # 定义主标题
       x = "Date", # 定义x轴文本
       y = "Value")# 定义y轴文本
p2
#Mar
p3<-ggplot(df)+
  geom_line(aes(date, Mar),size=0.8,color="blue")+
  theme_prism(palette = "candy_soft",#主题设置
              base_fontface = "plain", 
              base_family = "serif", 
              base_size = 16,  
              base_line_size = 0.8, 
              axis_text_angle = 45)+
  scale_x_continuous(breaks=seq(1,31, 3))+#设置X轴标签范围及间隔
  labs(title = "Mar", # 定义主标题
       x = "Date", # 定义x轴文本
       y = "Value")# 定义y轴文本
p3
#Apr
p4<-ggplot(df)+
  geom_line(aes(date, Apr),size=0.8,color="yellow")+
  theme_prism(palette = "candy_soft",#主题设置
              base_fontface = "plain", 
              base_family = "serif", 
              base_size = 16,  
              base_line_size = 0.8, 
              axis_text_angle = 45)+
  scale_x_continuous(breaks=seq(1,31, 3))+#设置X轴标签范围及间隔
  labs(title = "Apr", # 定义主标题
       x = "Date", # 定义x轴文本
       y = "Value")# 定义y轴文本
p4

#拼图
library(cowplot)
plot_grid(p1,p2,p3,p4,ncol=2)
