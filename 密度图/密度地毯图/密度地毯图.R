rm(list=ls())  # 清除环境变量
# 设置工作路径
library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd()
# 绘图函数
plot_density_carpet <- function(data,
                                category_col,
                                value_col,
                                facet_col = "Null",
                                group_col) {
  # 📦 加载库
  library(tidyverse)
  library(ggridges)
  library(janitor)
  
  # 🧼 清洗并准备数据
  data <- data %>%
    clean_names() %>%
    rename(category = !!category_col,
           score = !!value_col,
           group = !!group_col) %>%
    filter(!is.na(category), !is.na(score), !is.na(group))
  
  # 🎨 绘图
  p <- ggplot(data, aes(x = score, y = category, fill = category)) +
    geom_density_ridges(color = "grey30", scale = 0.9) +
    geom_text(aes(label = "|", color = category), nudge_y = -0.2) +
    scale_fill_manual(
      values = c("#14133B", "#C59CC7"),
      name = category_col
    ) +
    scale_color_manual(
      values = c("#14133B", "#C59CC7"),
      name = category_col
    ) +
    coord_cartesian(clip = "off") +
    labs(
      title = "Density Distribution with Carpet Plot",
      subtitle = paste0("Note: Data must include 'category_col', 'value_col', and 'group_col' columns.\nThis chart visualizes score distributions across categories and groups."),
      caption = "Source: User-provided data · Graphic: R Visualization"
    ) +
    theme_minimal(base_family = "serif", base_size = 12) +
    theme(
      legend.position = "right",
      plot.background = element_rect(fill = "grey99", color = NA),
      axis.title = element_blank(),
      strip.text = element_text(size = 12),
      plot.title = element_text(face = "bold"),
      plot.margin = margin(15, 15, 15, 15)
    )
  # 添加分面图层（如果需要）
  if (facet_col != "Null") {
    p <- p + facet_wrap(vars(.data[[facet_col]]), ncol = 2)
  }
  
  # 显示图形
  print(p)
}
# 导入数据
detectors <- readr::read_csv('detectors.csv')
# 绘图
plot_density_carpet(detectors,category_col = "pred_class",
                                value_col = "pred_ai",
                                group_col = "native",
                                facet_col = "name")

