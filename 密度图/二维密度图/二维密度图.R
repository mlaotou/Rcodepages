# # library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd()
# # library(here);setwd(here());getwd()
# rm(list=ls())  # 清除环境变量  
# 设置工作路径
library(this.path);setwd(dirname(this.path()));getwd()

# 设置随机种子，确保结果可重复
set.seed(123)
# 生成500行示例数据
data <- data.frame(
  Completeness = runif(500, min = 0, max = 100), # 随机生成0到100之间的完整性值
  Contamination = runif(500, min = 0, max = 10)  # 随机生成0到10之间的污染度值
)
# 查看生成的数据
head(data)
### 数据说明
# - `Completeness`：表示MAG的完整性，范围为0到100，通常表示为百分比。
# - `Contamination`：表示MAG的污染度，范围为0到10，通常表示为百分比。
# 保存为txt文件
write.table(data, file = "example_data.txt", sep = "\t", row.names = FALSE)

# 加载所需的包
library(ggplot2)
library(ggExtra)
# 绘制主图：双变量密度图
# 主图包含散点和双变量密度
main_plot <- ggplot(data, aes(x = Completeness, y = Contamination)) +
  geom_point(alpha = 0, color = "blue") + # 添加散点图
  geom_density2d_filled(alpha = 1) + # 填充等高线密度
  labs(x = "Completeness (%)", y = "Contamination (%)") + # 添加坐标标签
  guides(fill = "none") + # 隐藏图例
  theme_bw() +
  theme(
    plot.margin = margin(0,0,0,0),
    axis.line = element_line(color = "black", size = 0.5), # 添加横纵坐标轴
    axis.ticks = element_line(color = "black"), # 添加坐标刻度
    axis.ticks.length = unit(0.2, "cm"), # 设置刻度长度
    axis.title = element_text(size = 14), # 坐标轴标题字体大小
    axis.text = element_text(size = 12),
        # 坐标轴刻度字体大小
    panel.grid.major = element_blank(), # 移除主网格线
    panel.grid.minor = element_blank() # 移除次网格线
  )+
  # 移除空白边距
    scale_x_continuous(expand = c(0,0))+
    scale_y_continuous(expand = c(0,0))
# 添加边缘密度,这里函数功能有限，无法实现精确对齐
combined_plot <- ggMarginal(
  main_plot,
  type = "density", # 边缘密度图类型
  fill = "lightblue", # 填充颜色
  alpha = 0.8
  # 透明度
)
# 显示图形
print(combined_plot)
# 保存为SVG文件,通过AI手动调整精确对齐
ggsave("CMP_CNT_density2d.svg", plot = combined_plot, width = 6, height = 6, units = "in")
ggsave("二位密度图.png", plot = combined_plot, width = 6, height = 6, units = "in")