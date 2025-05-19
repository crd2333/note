# VSCode 使用技巧
## 常用快捷键
- 光标操作 (重点记忆)
  - 光标换行：`ctrl+enter`
  - 光标跳跃单词：`ctrl+左右`
  - 复制光标：`ctrl+alt+上下`
  - 移动行：`alt+上下`
  - 移动视图：`ctrl+上下`
  - 选择整行：`ctrl+L`
  - 删除当前行：`ctrl+x`
  - 选中：`shift+上下左右`
  - 选中所有出现的当前单词：`ctrl+shift+L`
  - 缩进与取消缩进：
  - 缩进：`tab`或`ctrl+[`
  - 取消缩进：`shift+tab`或`ctrl+]`
- 工具栏
  - 左侧工具栏：`ctrl+b`
  - 从左侧工具栏中选择文件打开：`ctrl+0`
  - 从上方选项卡中切换文件：`ctrl+tab`
  - 最近打开的文件：`ctrl+p`
  - 打开设置：`ctrl+，`
  - 终端：`ctrl+～`
  - git：`ctrl+shift+g`
  - bash:`ctrl+shift+点`
- 常用操作
  - 代码格式化`shift+ctrl+i`
  - 撤销与恢复：`ctrl+z`和`ctrl+y`
  - 注释：`ctrl+/`单行或多行
  - 字体大小：`ctrl+加减`

## 资源管理器与源代码管理的忽略
- 在 `settings.json` 中添加如下内容
    ```json
        // VSCode 资源管理器中不显示的文件
        "files.exclude": {
            "**/__pycache__": true,
            "**/.gitkeep": true,
            "**/.obsidian": true,
            "**/*.code-workspace": true,
            "**/*.lnk": true,
            "**/*.url": true
        },
        // VSCode 源代码管理中不显示的文件夹
        "git.ignoredRepositories": [
            "D:\\Obsidian\\Study"
        ],
    ```
- git 管理的话，还有一种比较相反的做法，只追踪打开文件所在的仓库
    ```json
    "git.autoRepositoryDetection": "openEditors"
    ```

## VSCode Snippets
- 芝士什么：可自定义的代码片段，常用于快速输入一些代码、模板等
- 可以参考：
  - [一个案例学会 VSCode Snippets，极大提高开发效率 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/457062272)
  - [VSCode Snippets：提升开发幸福感的小技巧 - 掘金 (juejin.cn)](https://juejin.cn/post/7076609496046370847)
  - 对 LaTeX 而言
    - [latex---vscode 编辑器配置及快捷键（snnipets）设置 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/350249305)


## VSCode 键绑定
- 通过左下角的 `设置-键盘快捷方式` 打开，方便而强大地自定义快捷键
- 进阶：通过编辑 `keybindings.json` 文件来自定义更复杂的功能，如带参数等
  - 例子：LaTeX 文本加粗，实现按下 `ctrl+b` 后，选中的文本被 `\textbf{}` 包裹
    ```json
        {
            "key": "ctrl+b", // LaTeX 文本加粗
            "command": "editor.action.insertSnippet",
            "args": {
            "snippet": "\\textbf{${TM_SELECTED_TEXT}}"
            },
            "when": "editorTextFocus && !editorReadonly && editorLangId =~ /^latex$/"
        },
    ```

## VSCode 如何调试
- [VScode tasks.json 和 launch.json 的设置 - 知乎 (zhihu.com)](https://zhuanlan.zhihu.com/p/92175757)
- ~~还是不会~~ 以现在 (23.11.28) 的视角看，似乎这些调试相关文章有不少都过时了，我现在只需要对 `C`, `Cpp` 分别搞一个 `tasks.json`，然后保证处在两个工作区就好了
- （25.2.18 更新），现在感觉 VSCode 还是作为小型文本编辑器比较好用，真上大型项目还是老老实实用 VS 或者 Rider 等专业 IDE 吧。。。

!!! warning
    - 编译的时候看的是**当前工作区一级文件夹**下的 `.vscode` 文件夹中的内容，而不是当前编译文件所在的文件夹下的 `.vscode`
    - 我因为工作区的组织架构用到了工作区内二级目录，所以这个问题困扰了我很久，仍未解决。
      - 目前的办法是另外新建了一个工作区，在这个工作区内把各个语言的编译配置文件都放在一级目录下

### VSCode python 文件的调试
- 对于单文件不带参数的 python 文件，添加断点然后直接调试就好了
- 对于带参数的或者从模块启动的，有两种方法：
  1. 一种方法是改变 `launch.json`，把参数或者模块的信息加入其中
  2. 使用代理文件。创建 `debugProxy.py` 托管你需要调试的命令
- 基本上还是用第一种方法的多一点，正常一点
- 当然，也有通过 pdb（可能类似 gdb？）不通过 VSCode 直接进行调试，我估计如果我那边不顺利的话也要这么搞了

# Visual Studio 使用技巧
该说不说，要不是看重 VS 的大型工程适配能力，真的不想用，太笨重且不习惯了。下面的一切都以 VS2022 为准。

## 编码问题
左上角菜单 `文件` -> `高级保存选项` 可以选择。VS 默认 GB2312，且不支持不带 BOM 的 UTF-8 编码，导致用 VS 打开后的文件到 VSCode 里乱码了（我算是知道收到别人代码那么多非 UTF8 的都是哪来的了）。推荐一个插件 `Force UTF-8 (No BOM) 2022`，下来之后不用设置直接起效（现在新建的文件都会默认保存为 UTF-8 编码，但是已有的则不会改变）。可以再装个 `FileEncoding` 插件用来显示文件编码格式。

或者通过 `.editorconfig` 文件进行配置：
```ini
[*] # a mask, means for all files, can be changed to (e.g.) [*.{h,cpp}]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true
indent_style = space
indent_size = 4
```

然后问题完全解决了吗？并没有，啥必 VS 未按 UTF-8 格式进行编译，非得按它那 UTF8 (with BOM) 或者 GBK 编译。对于这个问题，我们只能在编译命令行里加 `utf8` 参数，要么通过 cmake，要么通过每个项目的设置（真尼玛服了），详见 [VS 修改 c++ 项目编码为 utf-8 及报错](https://zhuanlan.zhihu.com/p/15522489066)。

为了改成 UTF-8 真是煞费苦心。。。其实 UTF-8 with BOM 也不是不行吧（

使用下来发现，即使用上了以上所有方法，加载文件的时候总是会跳出来用 GB2312 打开并发生错误，真是他妈的服了，不管怎么改都惦记着它那脑瘫 GB2312。啥必 VS！啥必 VS！啥必 VS！

## 窗口问题
VS 不支持 VSCode 这样展开合并的窗口，要么浮动，要么停靠（意味着不能合拢），要么就是自动隐藏（意味着展开后不能占位），真是烂完了，目前没找到办法优化。

不过这个固定按钮倒是可以起到一定的作用，启用可以停靠，取消可以自动隐藏，只是相比 VSCode 还是差了点。

## 一些实用的插件
`Resharper`, `Transparency Theme With Resharper`, `Open In Visual Studio Code`, `File Icons`, `ClaudiaIDE`, `Output Window filter`, `Switch Startup Project 2022`, `Tweaks 2022`, `Viasfora`。

`Viasfora` 插件能让括号颜色更好看（配对更清楚），但有个很坑的一点是长按 `ctrl` 会把当前指针所在 scope 高亮（当时定位了老半天）。`ctrl` 键有多实用不必多说，这个东西会导致时不时冒出一个颜色块来，很丑很烦。

## 文本编辑器
### 快捷键问题
VS 的快捷键设置真是笨重得像屎一样，搜索、设置都得搞半天。即使指定 VSCode 样式也跟 VSCode 的快捷键有很多不同，太脑残了。这个没什么办法，慢慢设置吧。

### 可见空格
`编辑` -> `高级` -> `查看空白`，可以设置空格、制表符、换行符等的显示方式。

如果空格颜色太淡怎么办？`工具` -> `选项` -> `环境` -> `字体和颜色`，找到 `可见空白` 设置颜色（个人使用灰色，也可以自定义）。

## 调试与构建
### 调试停止时自动关闭控制台
`工具` -> `选项` -> `调试` -> `调试停止时自动关闭控制台`。我在 VS 里找半天都没找到办法直接在 native 的 powershell 里起任务（像 VSCode 那样），只能新起一个 cmd 窗口，或者通过每个项目的 `配置属性` -> `链接器` -> `系统` -> `子系统` 以及 `配置属性` -> `链接器` -> `高级` -> `入口点` 配置直接启动窗口（但没法看到程序输出了）。因此只能退而求其次能否每次关闭程序时自动退出 cmd（但有时不太合适，因为还需要看退出时的输出信息……）。

<div style="font-size: 20px;">再见 VS，以后只会把你当做大型项目的编译器，不会拿你当编辑器了，拜拜了您嘞</div>