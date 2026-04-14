#=========================================
# 绘制折线图的过程，及函数

rm(list=ls())  # 清除环境变量  
# 设置工作路径
library(rstudioapi);setwd(dirname(getActiveDocumentContext()$'path'));getwd()
library(tidyverse)
library(ggprism)
library(ggsci)
library(agricolae)  # 多重比较包
library(ggrepel)    # 避免文本重叠

select_row <- c("TNF-α","ETO","TPG")
# 读取数据
raw_data <- read_tsv("F1-b.txt") %>% 
  pivot_longer(-c(type,time)) %>% # 转为长数据
  select(-name) %>% 
  filter(type %in% select_row)

# 设置因子水平
raw_data$time <- factor(raw_data$time, levels = c("10min","1h","6h","24h","48h"))
raw_data$type <- factor(raw_data$type, levels = read_tsv("F1-b.txt") %>%
pivot_longer(-c(type,time)) %>%
select(type) %>%
distinct() %>%
filter(type != "w/o") %>%
pull())

# 计算均值和标准误
df_summary <- raw_data %>%
  group_by(type, time) %>% 
  summarise(value_mean = mean(value),
            sd = sd(value),
            se = sd(value)/sqrt(n()),
            .groups = "drop") %>% 
  arrange(time)

# 进行多重比较分析
perform_multiple_comparison <- function(data, time_point) {
  # 提取特定时间点的数据
  time_data <- data %>% filter(time == time_point)
  
  # 如果某个时间点只有一个处理组，跳过比较
  if(length(unique(time_data$type)) <= 1) {
    return(data.frame(type = unique(time_data$type), 
                      letter = "a", 
                      time = time_point))
  }
  
  # 执行单因素方差分析
  aov_result <- aov(value ~ type, data = time_data)
  
  # 进行Tukey多重比较
  tukey_result <- HSD.test(aov_result, "type", group = TRUE)
  
  # 提取字母标记
  letters_df <- tukey_result$groups %>%
    rownames_to_column("type") %>%
    select(type, letter = groups) %>%
    mutate(time = time_point,
           type = factor(type, levels = levels(data$type)))
  
  return(letters_df)
}

# 对每个时间点进行多重比较
x_levels <- c("10min","1h","6h","24h","48h")
comparison_results <- map_dfr(x_levels, ~perform_multiple_comparison(raw_data, .x))

# 合并显著性标记到汇总数据
df_plot <- df_summary %>%
  left_join(comparison_results, by = c("type", "time")) %>%
  mutate(
    time = factor(time, levels = c("10min","1h","6h","24h","48h")),
    # 计算字母标记的Y轴位置
    letter_y = value_mean+0.01
  ) 


# 绘制图形
p <- df_plot %>% 
  ggplot(aes(time, value_mean, fill = type, group = type, 
             ymin = value_mean - se, ymax = value_mean + se)) +
  geom_errorbar(width = 0.1) +
  geom_line(color = "black") +
  geom_point(key_glyph = "polygon", aes(color = type)) +
  geom_point(pch = 21, size = 5, show.legend = FALSE) +
  
  # 添加显著性字母标记
  geom_text_repel(aes(y = letter_y, label = letter), 
                  size = 3, color = "black",
                  nudge_y = 0.02,  # 向上偏移一点
                  segment.size = 0.2,  # 连接线粗细
                  segment.color = "grey50",  # 连接线颜色
                  max.overlaps = Inf,  # 允许处理所有重叠
                  force = 2) + # 排斥力度
  scale_fill_npg() +
  scale_color_npg() +
  scale_x_discrete(guide = "prism_bracket") +
  labs(x = NULL, y = NULL) +
  theme_prism(base_line_size = 0.5) +
  theme(
    plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), units = "cm"),
    axis.line = element_line(color = "black", size = 0.4),
    panel.grid.minor = element_blank(),
    panel.grid.major = element_line(size = 0.2, color = "#e5e5e5"),
    axis.text.y = element_text(color = "black", size = 10),
    axis.text.x = element_text(margin = margin(t = -5), color = "black", size = 10),
    legend.key = element_blank(),
    legend.title = element_blank(),
    legend.text = element_text(color = "black", size = 8),
    legend.spacing.x = unit(0.1, 'cm'),
    legend.spacing.y = unit(1, 'cm'),
    legend.key.width = unit(0.7, 'cm'),
    legend.key.height = unit(0.4, 'cm'),
    legend.background = element_blank(),
    legend.box.margin = margin(0, 0, 0, 0)
  )

print(p)

# 可选：查看多重比较的详细结果
print("多重比较结果:")
comparison_results %>%
  arrange(time, type) %>%
  print()

# 可选：保存图片
# ggsave("multiple_comparison_plot.pdf", p, width = 8, height = 6)
# ggsave("multiple_comparison_plot.png", p, width = 8, height = 6, dpi = 300)
#=========================================
#=========================================
# 优化成函数
# 清除环境并加载所需包
rm(list=ls())
# 加载必要的包
library(tidyverse)
library(ggprism)
library(ggsci)
library(agricolae)  # 多重比较包
library(ggrepel)    # 避免文本重叠

#' 时间序列分组比较绘图函数
#' 
#' @param data 数据框，包含时间、分组和数值变量
#' @param time_var 时间变量名（字符串）
#' @param group_var 分组变量名（字符串）
#' @param value_var 数值变量名（字符串）
#' @param exclude_groups 要排除的分组（可选，字符向量）
#' @param time_levels 时间点的因子水平（可选，字符向量）
#' @param group_levels 分组的因子水平（可选，字符向量）
#' @param x_label X轴标签（默认为NULL）
#' @param y_label Y轴标签（默认为NULL）
#' @param show_comparison 是否显示多重比较结果（默认TRUE）
#' @return ggplot对象
line_multicomparison_plot <- function(data, 
                                        time_var, 
                                        group_var, 
                                        value_var,
                                        exclude_groups = NULL,
                                        time_levels = NULL,
                                        group_levels = NULL,
                                        x_label = NULL,
                                        y_label = NULL,
                                        show_comparison = TRUE) {
  
  # 数据预处理
  plot_data <- data %>%
    rename(Time = !!sym(time_var),
           Group = !!sym(group_var),
           Value = !!sym(value_var))
  
  # 排除指定分组
  if (!is.null(exclude_groups)) {
    plot_data <- plot_data %>%
      filter(!Group %in% exclude_groups)
  }
  
  # 设置因子水平
  if (!is.null(time_levels)) {
    plot_data$Time <- factor(plot_data$Time, levels = time_levels)
  } else {
    plot_data$Time <- factor(plot_data$Time)
  }
  
  if (!is.null(group_levels)) {
    plot_data$Group <- factor(plot_data$Group, levels = group_levels)
  } else {
    plot_data$Group <- factor(plot_data$Group)
  }
  
  # 计算均值和标准误
  df_summary <- plot_data %>%
    group_by(Group, Time) %>% 
    summarise(value_mean = mean(Value, na.rm = TRUE),
              sd = sd(Value, na.rm = TRUE),
              n = n(),
              se = sd/sqrt(n),
              .groups = "drop") %>%
    arrange(Time)
  
  # 多重比较函数
  perform_multiple_comparison <- function(data, time_point) {
    # 提取特定时间点的数据
    time_data <- data %>% filter(Time == time_point)
    
    # 如果某个时间点只有一个处理组或数据不足，跳过比较
    if(length(unique(time_data$Group)) <= 1 || nrow(time_data) < 3) {
      return(data.frame(Group = unique(time_data$Group), 
                        letter = "a", 
                        Time = time_point))
    }
    
    tryCatch({
      # 执行单因素方差分析
      aov_result <- aov(Value ~ Group, data = time_data)
      
      # 进行Tukey多重比较
      tukey_result <- HSD.test(aov_result, "Group", group = TRUE)
      
      # 提取字母标记
      letters_df <- tukey_result$groups %>%
        rownames_to_column("Group") %>%
        select(Group, letter = groups) %>%
        mutate(Time = time_point,
               Group = factor(Group, levels = levels(data$Group)))
      
      return(letters_df)
    }, error = function(e) {
      # 如果统计分析失败，返回默认标记
      return(data.frame(Group = unique(time_data$Group), 
                        letter = "a", 
                        Time = time_point))
    })
  }
  
  # 进行多重比较分析
  if (show_comparison) {
    time_levels_actual <- levels(plot_data$Time)
    comparison_results <- map_dfr(time_levels_actual, ~perform_multiple_comparison(plot_data, .x))
    
    # 合并显著性标记到汇总数据
    df_plot <- df_summary %>%
      left_join(comparison_results, by = c("Group", "Time")) %>%
      mutate(
        # 计算字母标记的Y轴位置
        letter_y = value_mean*1.1
      )
  } else {
    df_plot <- df_summary
  }
  # 设置因子水平
  if (!is.null(time_levels)) {
    df_plot$Time <- factor(df_plot$Time, levels = time_levels)
  } else {
    df_plot$Time <- factor(df_plot$Time)
  }
  
  if (!is.null(group_levels)) {
    df_plot$Group <- factor(df_plot$Group, levels = group_levels)
  } else {
    df_plot$Group <- factor(df_plot$Group)
  }
  # 绘制基础图形
  p <- df_plot %>% 
    ggplot(aes(Time, value_mean, fill = Group, group = Group, 
               ymin = value_mean - se, ymax = value_mean + se)) +
    geom_point(key_glyph = "polygon", aes(color = Group)) + #只定义图例显示
    geom_point(pch = 21, size = 3, show.legend = FALSE,colour = "black")+ # 图上的点，不显示图例
    scale_fill_manual(values = c("#01359C", "#7ECFFB", "#F5B0AB", "#AB9FA3", "#1C6DB6", "#D45C53", "#B4DeA2", "#BDBADB")) +
    scale_color_manual(values = c("#01359C", "#7ECFFB", "#F5B0AB", "#AB9FA3", "#1C6DB6", "#D45C53", "#B4DeA2", "#BDBADB")) +
    geom_errorbar(width = 0.1) +
    geom_line(color = "black") 

  
  # 添加显著性标记（如果启用）
  if (show_comparison && "letter" %in% names(df_plot)) {
    p <- p + geom_text_repel(aes(y = letter_y, label = letter), 
                             size = 3, color = "black",
                             nudge_x = 0.02,
                             segment.size = 0,
                             segment.color = "grey50",
                             max.overlaps = Inf,
                             force = 2)
  }
  
  # 应用主题和样式
  p <- p + 
    scale_x_discrete(guide = "prism_bracket") +
    labs(x = x_label, y = y_label) +
    theme_prism(base_line_size = 0.5) +
    theme(
      plot.margin = unit(c(0.1, 0.1, 0.1, 0.1), units = "cm"),
      axis.line = element_line(color = "black", size = 0.4),
      panel.grid.minor = element_blank(),
      panel.grid.major = element_line(size = 0.2, color = "#e5e5e5"),
      axis.text.y = element_text(color = "black", size = 10),
      axis.text.x = element_text(margin = margin(t = -5), color = "black", size = 10),
      legend.key = element_blank(),
      legend.title = element_blank(),
      legend.text = element_text(color = "black", size = 8),
      legend.spacing.x = unit(0.1, 'cm'),
      legend.spacing.y = unit(1, 'cm'),
      legend.key.width = unit(0.7, 'cm'),
      legend.key.height = unit(0.4, 'cm'),
      legend.background = element_blank(),
      legend.box.margin = margin(0, 0, 0, 0)
    )
  
  return(lst(p,df_plot))
}

#=========================================
# 原数据作图
# 使用函数绘图
result <- line_multicomparison_plot(
  data = raw_data,
  time_var = "time",
  group_var = "type", 
  value_var = "value",
  # exclude_groups = NULL,  # 可以排除某些组，比如 c("Control")
  time_levels = c("10min", "1h", "6h", "24h", "48h"),
  x_label = "Time Points",
  y_label = "Response Value",
  show_comparison = TRUE
)

# 显示图形
dev.new(width = 12, height = 8)
print(result$p)
#=========================================
# 另一数据
df <- read.csv("surveys.csv") 
result <- line_multicomparison_plot(
  data = df,
  time_var = "year",
  group_var = "treatment", 
  value_var = "plot",
  x_label = "Time Points",
  y_label = "Response Value",
  show_comparison = TRUE
)
print(result$p)
#=========================================
# 补充用geom_text添加标签，避免错误
line_multicomparison_plot <- function(data, 
                                      time_var, 
                                      group_var, 
                                      value_var,
                                      exclude_groups = NULL,
                                      time_levels = NULL,
                                      group_levels = NULL,
                                      x_label = NULL,
                                      y_label = NULL,
                                      show_comparison = TRUE) {
  require(tidyverse)
  require(ggprism)
  require(agricolae)
  
  # 1. 数据预处理与过滤
  plot_data <- data %>%
    rename(Time = !!sym(time_var),
           Group = !!sym(group_var),
           Value = !!sym(value_var)) %>%
    filter(!is.na(Value))
  
  if (!is.null(exclude_groups)) {
    plot_data <- plot_data %>% filter(!Group %in% exclude_groups)
  }
  
  # 统一设置因子水平
  if (!is.null(time_levels)) plot_data$Time <- factor(plot_data$Time, levels = time_levels)
  else plot_data$Time <- factor(plot_data$Time)
  
  if (!is.null(group_levels)) plot_data$Group <- factor(plot_data$Group, levels = group_levels)
  else plot_data$Group <- factor(plot_data$Group)
  
  # 2. 计算汇总统计量
  df_summary <- plot_data %>%
    group_by(Group, Time) %>% 
    summarise(value_mean = mean(Value, na.rm = TRUE),
              sd = sd(Value, na.rm = TRUE),
              n = n(),
              se = sd/sqrt(n),
              .groups = "drop")
  
  # 3. 统计比较逻辑优化
  if (show_comparison) {
    # 定义内部比较逻辑
    perform_comp <- function(sub_data) {
      if(length(unique(sub_data$Group)) <= 1) return(NULL)
      
      fit <- aov(Value ~ Group, data = sub_data)
      tukey <- HSD.test(fit, "Group", group = TRUE)
      
      # 这里的 Group 处理需要注意匹配
      res <- tukey$groups %>% 
        rownames_to_column("Group") %>%
        select(Group, letter = groups)
      return(res)
    }
    
    comparison_results <- plot_data %>%
      group_split(Time) %>%
      map_dfr(function(x) {
        res <- perform_comp(x)
        if(!is.null(res)) res$Time <- unique(x$Time)
        return(res)
      })
    
    # 合并数据
    df_plot <- df_summary %>%
      left_join(comparison_results, by = c("Group", "Time")) %>%
      mutate(
        # 优化字母标记位置：位于 SE 误差棒上方固定偏移
        letter_y = value_mean + se + (max(se, na.rm = TRUE) * 0.2)
      )
  } else {
    df_plot <- df_summary
  }
  
  # 4. 绘图
  # 预定义颜色，防止超出范围
  my_colors <- c("#01359C", "#7ECFFB", "#F5B0AB", "#AB9FA3", "#1C6DB6", "#D45C53", "#B4DeA2", "#BDBADB")
  
  p <- ggplot(df_plot, aes(x = Time, y = value_mean, group = Group, color = Group, fill = Group)) +
    # 误差棒
    geom_errorbar(aes(ymin = value_mean - se, ymax = value_mean + se), 
                  width = 0.1, color = "black") +
    # 折线
    geom_line(color = "black") +
    # 点（双层设计：黑边实心点）
    geom_point(shape = 21, size = 3, color = "black", stroke = 0.5) +
    # 显著性字母：改用 geom_text 保证对齐
    {if(show_comparison) geom_text(aes(y = letter_y, label = letter), 
                                   color = "black", size = 3.5, 
                                   vjust = 0, # 向上对齐
                                   show.legend = FALSE)} +
    scale_fill_manual(values = my_colors) +
    scale_color_manual(values = my_colors) +
    scale_x_discrete(guide = "prism_bracket") +
    labs(x = x_label, y = y_label) +
    theme_prism(base_line_size = 0.5) +
    theme(
      legend.title = element_blank(),
      panel.grid.major = element_line(size = 0.2, color = "#e5e5e5"),
      axis.text = element_text(color = "black")
    )
  
  return(list(plot = p, data = df_plot))
}
# 其他调用如上



