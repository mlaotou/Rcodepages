# 基因组数据可视化函数
# 作者: Claude
# 日期: 2025-06-22

# 加载所需包
library(tidyverse)
library(scales)
library(ggsignif)
library(ggExtra)
library(grid)

#' 绘制基因组数据可视化图形
#' 
#' @param data 数据框，包含 type, length, number_of_cds, completeness 列
#' @param main_width 主图宽度比例 (0-1)
#' @param resid_width 残差图宽度比例 (0-1)
#' @param resid_height 残差图高度比例 (0-1)
#' @param resid_x_pos 残差图x位置调整
#' @param resid_y_pos 残差图y位置调整
#' @param point_size 散点大小
#' @param point_alpha 散点透明度
#' @param legend_x 图例x位置
#' @param legend_y 图例y位置
#' @param base_font_size 基础字体大小
#' @param colors 颜色向量，长度为3，对应SAG, MAG, WGS
#' @param group_labels 分组标签前缀，默认为"MHQ"
#' @return 无返回值，直接绘制图形
plot_genome_visualization <- function(data = NULL,
                                      main_width = 0.7,
                                      resid_width = 0.3,
                                      resid_height = 0.2,
                                      resid_x_pos = 0.85,
                                      resid_y_pos = 0.5,
                                      point_size = 3,
                                      point_alpha = 0.6,
                                      legend_x = 0.05,
                                      legend_y = 0.95,
                                      base_font_size = 20,
                                      colors = c("#1F77B4", "#FF7F0E", "#3F3F3F"),
                                      group_labels = "MHQ") {
  
  # 如果没有提供数据，生成模拟数据
  if (is.null(data)) {
    set.seed(123)
    n <- 180
    data <- data.frame(
      type = rep(c("SAG", "MAG", "WGS"), each = n / 3),
      length = round(runif(n, min = 3e5, max = 3e7), 0),
      number_of_cds = round(runif(n, min = 400, max = 15000), 0),
      completeness = runif(n, min = 60, max = 100)
    )
  }
  
  # 数据预处理：根据completeness进行矫正
  df <- data
  df$number_of_cds <- df$number_of_cds / (df$completeness * 1e-2)
  df$length <- df$length / (df$completeness * 1e-2)
  
  # 计算样本数量并生成图例标签
  type_counts <- as.data.frame(table(df$type))
  names(type_counts) <- c("type", "count")
  type_counts <- type_counts[order(factor(type_counts$type, levels = c("SAG", "MAG", "WGS"))), ]
  new_legend <- paste(group_labels, type_counts$type, paste0("(N=", type_counts$count, ")"))
  
  # 创建主散点图
  p1 <- ggplot(df, aes(x = length, y = number_of_cds, 
                       color = factor(type, levels = c("SAG", "MAG", "WGS")))) +
    geom_point(size = point_size, alpha = point_alpha) +
    geom_smooth(method = "lm", color = "red", linetype = "dashed") +
    guides(color = guide_legend(override.aes = list(alpha = 1, size = 5))) +
    scale_color_manual(values = colors, labels = new_legend) +
    scale_x_log10(breaks = c(1e6, 1e7), 
                  labels = trans_format("log10", math_format(10^.x))) +
    scale_y_log10(breaks = c(1e3, 1e4), 
                  labels = trans_format("log10", math_format(10^.x))) +
    labs(x = "Genome total size [bp] (corrected)", 
         y = "Number of predicted CDS (corrected)") +
    annotation_logticks(outside = TRUE,
                        short = unit(1.5, "mm"), 
                        mid = unit(2, "mm"), 
                        long = unit(2.5, "mm")) +
    coord_cartesian(clip = "off") +
    theme_classic(base_size = base_font_size) +
    theme(
      panel.grid.major = element_line(linetype = "dashed"),
      axis.text = element_text(color = "black", size = base_font_size * 0.8),
      legend.title = element_blank(),
      legend.position = c(legend_x, legend_y),
      legend.background = element_rect(fill = 'white', colour = '#D6D6D6', linewidth = 1)
    )
  
  # 添加边缘密度图
  p2 <- ggMarginal(p1, 
                   type = "density",
                   groupColour = TRUE, 
                   groupFill = TRUE,
                   alpha = 0.3)
  
  # 计算残差
  fit <- lm(log(number_of_cds) ~ log(length), data = df)
  df$number_of_cds_fit <- exp(predict(fit))
  df$residuals_log <- log(df$number_of_cds) - log(df$number_of_cds_fit)
  
  # 组间比较设定
  my_comparisons <- list(c("WGS", "MAG"), c("MAG", "SAG"), c("WGS", "SAG"))
  
  # 创建残差箱线图
  p3 <- ggplot(df, aes(x = factor(type, levels = c("SAG", "MAG", "WGS")),
                       y = residuals_log, 
                       fill = factor(type, levels = c("SAG", "MAG", "WGS")))) +
    stat_boxplot(geom = "errorbar", width = 0.4, size = 1, color = "#3F3F3F") +
    geom_boxplot(outlier.fill = "#3F3F3F", outlier.shape = 23, 
                 outlier.size = 1, linewidth = 0.5) +
    geom_signif(comparisons = my_comparisons, test = "wilcox.test",
                map_signif_level = c("****" = 0.0001, "***" = 0.001, 
                                     "**" = 0.01, "*" = 0.05),
                textsize = 8, size = 1.1, color = "#3F3F3F", step_increase = 0.2) +
    scale_fill_manual(values = c(colors[1], colors[2], "#808080")) +
    labs(x = NULL, y = NULL, title = "Residuals (log)") +
    theme_bw() +
    theme(
      panel.grid = element_blank(),
      panel.border = element_rect(color = "#B3B3B3", linewidth = 1.5),
      plot.title = element_text(hjust = 0.5, size = base_font_size * 0.8),
      axis.ticks.y = element_blank(),
      axis.text.y = element_blank(),
      axis.text.x = element_text(color = "black", size = base_font_size * 0.8),
      legend.position = "none"
    ) +
    coord_flip()
  
  # 组合图形
  grid.newpage()
  
  # 定义主图的viewport
  vp_main <- viewport(x = 0, y = 0, width = main_width, height = 1, 
                      just = c("left", "bottom"))
  
  # 定义残差图的viewport
  vp_resid <- viewport(x = resid_x_pos, y = resid_y_pos, 
                       width = resid_width, height = resid_height, 
                       just = c("center", "center"))
  
  # 绘制图形
  print(p2, vp = vp_main)
  print(p3, vp = vp_resid)
  
  # 返回图形对象列表（可选）
  invisible(list(main_plot = p2, residual_plot = p3))
}

#' 快速调整对齐参数的辅助函数
#' 
#' @param data 数据框
#' @param preset 预设配置："default", "compact", "wide"
#' @return 调用绘图函数
plot_genome_quick <- function(data = NULL, preset = "default") {
  
  presets <- list(
    default = list(
      main_width = 0.7, resid_width = 0.25, resid_height = 0.2,
      resid_x_pos = 0.85, resid_y_pos = 0.5
    ),
    compact = list(
      main_width = 0.75, resid_width = 0.2, resid_height = 0.15,
      resid_x_pos = 0.9, resid_y_pos = 0.45
    ),
    wide = list(
      main_width = 0.65, resid_width = 0.3, resid_height = 0.25,
      resid_x_pos = 0.82, resid_y_pos = 0.55
    )
  )
  
  params <- presets[[preset]]
  
  do.call(plot_genome_visualization, c(list(data = data), params))
}

# 使用示例：
# 1. 使用默认模拟数据
 plot_genome_visualization()

# 2. 使用自定义参数
plot_genome_visualization(data = df,
  main_width = 0.65,
  resid_width = 0.3,
  resid_x_pos = 0.25,
  resid_y_pos = 0.25,
  colors = c("#E74C3C", "#3498DB", "#2ECC71")
)

# 3. 使用预设配置
# plot_genome_quick(preset = "wide")

# 4. 使用自己的数据
# my_data <- read.csv("your_data.csv")
# plot_genome_visualization(data = my_data)