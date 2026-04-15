# Rcodepages 开发指南

本文档记录 Rcodepages 项目的完整开发流程和经验。

## 项目概述

这是一个基于 GitHub Pages 的 R 可视化成果展示网站，自动从文件夹结构生成索引，支持：
- 自动分类标签（根据子文件夹数量）
- 全文搜索
- 文件下载（点击卡片下载整个文件夹）
- 分类筛选

## 文件夹结构规则

### 层级结构

```
一级文件夹/           # 作为分类标签（当有子文件夹时）
  二级文件夹/         # 存放具体内容
    xxx.html        # 渲染好的 HTML
    xxx.Rmd        # R Markdown 源码
    xxx.R          # R 脚本（可选）
    xxx.png        # 缩略图（可选，命名需与 HTML 同名）
    data.csv       # 数据文件
```

### 分类规则

| 一级文件夹子文件夹数量 | 行为 | 示例 |
|---------------------|------|------|
| 0 或 1 个 | 作为普通文件夹，不生成分类按钮 | 时间序列图 |
| 2 个及以上 | 作为分类标签，生成对应按钮 | 散点图 (散点拟合 + 分组折线图) |

### 缩略图命名规则

- `{HTML文件名}.png`（推荐）
- `{HTML文件名}_plot.png`

例如：`linear_fitting_soil_carbon.html` 对应 `linear_fitting_soil_carbon.png`

## 开发流程

### 完整流程

```
1. 创建 R 脚本 → 2. 运行 convert_r_to_rmd.py → 3. RStudio 渲染 → 4. git push
```

#### 步骤 1: 创建 R 脚本

在对应的二级文件夹下创建 `.R` 文件。

#### 步骤 2: 转换为 Rmd（可选）

```bash
python .github/scripts/convert_r_to_rmd.py
```

此脚本会：
- 遍历所有 `.R` 文件
- 自动跳过已有 `.Rmd` 的文件
- 使用 `templates.Rmd` 作为模板
- 移除 setwd、rstudioapi 等不兼容代码

#### 步骤 3: RStudio 渲染

手动打开每个 `.Rmd` 文件，点击 "Knit" 按钮渲染为 `.html`。
如需保存图片，脚本会自动添加 ggsave 命令。

#### 步骤 4: 提交推送

```bash
git add .
git commit -m "add: 新增xxx"
git push
```

GitHub Actions 自动：
1. 生成 `chapters.json`（索引）
2. 生成 `file_list.json`（文件列表）
3. 部署到 GitHub Pages

### 快速验证（本地）

```bash
# 生成索引
python .github/scripts/generate_searchable_index.py
python .github/scripts/generate_file_list.py
```

## 脚本说明

### generate_searchable_index.py

生成 `chapters.json`，包含：
- 所有 HTML 文件的索引
- 自动检测分类（有 2+ 子文件夹的一级目录）
- 提取文本用于搜索
- 缩略图路径

### generate_file_list.py

生成 `file_list.json`，包含：
- 每个文件夹的文件列表
- 文件大小
- 供下载功能使用

### convert_r_to_rmd.py

将 `.R` 脚本转换为 `.Rmd`：
- 使用模板
- 移除不兼容代码（setwd、rstudioapi）
- 自动保存为同名 Rmd

### convert_r_to_rmd.py 模板配置

模板文件：`templates.Rmd`

标题修改（第 69 行）：
```python
# 显示文件夹名 + 文件名
rmd_content = template.replace("{title}", folder_name + " - " + title)

# 仅显示文件名
rmd_content = template.replace("{title}", title)
```

## 界面自定义

### index.html 参数修改

| 修改项 | 位置 | 代码 |
|-------|------|------|
| Logo | 第 8 行 | `src="logo.svg"` |
| 标题 | 第 668 行 | `FigureYa: Interactive Results Browser` |
| 分类按钮图标 | JS getCategoryIcon 函数 | 自定义符号 |

### 修改后提交

```bash
git add index.html
git commit -m "update: 界面修改"
git push
```

## 工作流配置

### deploy-pages.yml

��置：`.github/workflows/deploy-pages.yml`

关键配置：
- Python 版本：`python-version: '3.x'`
- beautifulsoup4 依赖：自动安装
- 上传版本：v4

### 常见问题

#### 1. 分类按钮不显示

检查 `chapters.json` 是否有 `category` 字段。

#### 2. 点击卡片无文件列表

确保 `folder` 字段路径与 `file_list.json` 的 key 一致。

#### 3. 缩略图不显示

检查图片命名是否与 HTML 文件名一致。

#### 4. Workflow 失败

常见原因：
- Python 版本未指定
- beautifulsoup4 未安装
- upload-pages-artifact 版本过旧

修复方法参考上方脚本说明。

## Git 操作

### 常用命令

```bash
# 提交所有修改
git add .
git commit -m "描述"
git push

# 查看状态
git status

# 查看差异
git diff

# 强制推送（谨慎使用）
git push --force

# 拉取远程更新
git pull origin main
```

### 分支操作

```bash
# 创建新分支
git checkout -b feature/xxx

# 切换分支
git checkout main

# 删除分支
git branch -d feature/xxx
```

## 最佳实践

### 1. 命名规范

- 文件名使用英文
- 避免特殊字符
- 缩略图与 HTML 同名

### 2. 文件组织

- 一个二级文件夹一个可视化
- 包含完整数据、脚本、源码、HTML
- 避免在一个文件夹放多个可视化

### 3. 测试流程

```bash
# 1. 本地运行生成脚本
python .github/scripts/generate_searchable_index.py
python .github/scripts/generate_file_list.py

# 2. 检查生成的文件
cat chapters.json
cat file_list.json

# 3. 确认无误后提交
git add .
git commit -m "描述"
git push
```

### 4. 调试清单

- [ ] HTML 文件是否在正确的文件夹？
- [ ] 缩略图命名是否正确？
- [ ] chapters.json 是否包含正确路径？
- [ ] file_list.json 是否匹配？
- [ ] 分类按钮是否显示？

## 常见错误解决

### Error 1: categories 不显示

原因：子文件夹数量 < 2
解决：确保有 2+ 个子文件夹，或修改脚本判断逻辑

### Error 2: 下载功能不工作

原因：folder 路径不匹配
解决：检查 chapters.json 的 folder 与 file_list.json 的 key 是否一致

### Error 3: 缩略图不显示

原因：图片命名与 HTML 不一致
解决：重命名或修改脚本的图片查找逻辑

### Error 4: Workflow 失败

```bash
# 检查 Python 版本
python --version

# 手动安装依赖
pip install beautifulsoup4

# 重新运行
python .github/scripts/generate_searchable_index.py
```

## 经验总结

### 1. 本地渲染 vs 在线渲染

- 本地渲染：稳定，速度快
- 在线渲染：需要 R 环境配置复杂

建议选择本地渲染。

### 2. 文件夹结构的演变

最初设计：嵌套结构自动检测分类
最终方案：1+ 个子文件夹就作为分类

### 3. 索引自动生成

workflow 自动完成：
- 扫描文件夹
- 生成 chapters.json
- 生成 file_list.json

无需手动维护索引。

### 4. 文件下载实现

使用 JSZip 从 GitHub RAW URL 下载：
- 优点：无需服务器
- 缺点：大文件可能慢

### 5. 开发节奏

```
本地修改 → git commit → git push → GitHub Actions → 自动部署
```

无需手动操作，自动完成。

## 联系支持

- GitHub 仓库：https://github.com/mlaotou/Rcodepages
- 问题反馈：在 GitHub Issues 中提出

---

Last updated: 2026-04-15
Author: milaotou