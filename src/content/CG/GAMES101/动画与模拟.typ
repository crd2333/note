#metadata(
  (
    order: 4,
  )
)<frontmatter>

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机图形学",
  lang: "zh",
)

- 主要是 Games 101 的笔记，然后加入了部分 ZJU 课上的新东西

#quote()[
  - 首先上来贴几个别人的笔记
    + #link("https://www.bilibili.com/read/readlist/rl709699?spm_id_from=333.999.0.0")[B站笔记]
    + #link("https://iewug.github.io/book/GAMES101.html#01-overview")[博客笔记]
    + #link("https://www.zhihu.com/column/c_1249465121615204352")[知乎笔记]
    + #link("https://blog.csdn.net/Motarookie/article/details/121638314")[CSDN笔记]
  - #link("https://sites.cs.ucsb.edu/~lingqi/teaching/games101.html")[Games101 的主页]
]

#counter(heading).update(10)

= Animation 动画与模拟
#info()[
  + 基本概念、质点弹簧系统、运动学
  + 求解常微分方程，刚体与流体
]

== 基本概念
- 动画历史
- 关键帧动画 (Keyframe Animation)
  - 关键位置画出来，中间位置用线性插值或 splines 平滑过渡
- 物理模拟 (Physical Simulation)
  - 核心思想就是真的构建物理模型，分析受力，从而算出某时刻的加速度、速度、位置
  - 物理仿真和渲染是分开的两件事

== 质点弹簧系统
- 质点弹簧系统 (Mass Spring System)
  - $f_(a->b)=k_s (b-a)/norm(b-a)(norm(b-a)-l)$，存在的问题，震荡永远持续
  - 如果简单的引入阻尼 (damping)：$f=-k_d dot(b)$，问题在于它会减慢一切运动（而不只是弹簧内部的震荡运动）
  - 引入弹簧内部阻尼
    $ f_b=-k_d underbrace((b-a)/norm(b-a) dot (dot(b)-dot(a)), "相对速度在弹簧方向投影") dot underbrace((b-a)/norm(b-a), "重新表征方向") $
- 用弹簧结构模拟布料
  #grid(
    columns: 4,
    fig("/public/assets/CG/GAMES101/img-2024-08-06-13-54-14.png", width: 5em),
    fig("/public/assets/CG/GAMES101/img-2024-08-06-13-54-32.png", width: 6em),
    fig("/public/assets/CG/GAMES101/img-2024-08-06-13-54-45.png", width: 6em),
    fig("/public/assets/CG/GAMES101/img-2024-08-06-13-54-52.png", width: 6em),
  )
  + 不能模拟布料，因为它不具备布的特性（不能抵抗切力、不能抵抗对折力）
  + 改进了一点，虽然能抵抗图示对角线的切力，但是存在各向异性。另外依然不能抵抗折叠
  + 可以抵抗切力，有各向同性，不抗对折
  + 红色 skip connection 比较小，仅起辅助作用。现在可以比较好的模拟布料
- Aside: FEM (Finite Element Method) instead of Springs 也能很好地模拟这些问题

== 粒子系统 (Particle Systems)
- 建模一堆微小粒子，定义每个粒子受到的力（粒子之间的力、来自外部的力、碰撞等），在游戏和图形学中非常流行，很好理解、实现
- 实现算法，对动画的每一帧：
  + 创建新的粒子（如果需要）
  + 计算每个粒子的受力
  + 根据受力更新每个粒子的位置和速度
  + 结束某些粒子生命（如果需要）
  + 渲染
- 应用：粒子效果、流体模拟、兽群模拟

== 运动学
- 正向运动学 (Forward Kinematics)
  - 以骨骼动画为例，涉及拓扑结构 (Topology: what’s connected to what)、关节相互的几何联系 (Geometric relations from joints)、树状结构 (Tree structure: in absence of loops)
  - 关节类型
    + 滑车关节 (Pin)：允许平面内旋转
    + 球窝关节 (Ball)：允许一部分空间内旋转
    + 导轨关节 (Prismatic joint)：允许平移
  - 正向运动学就是——给定关节的角度与位移，求出尖端的位置
  - 控制方便、实现直接，但不适合美工创作动画
- 逆运动学 (Inverse Kinematics)
  - 通过控制尖端位置，反算出应该旋转多少
  - 有多解、无解的情况，是典型的最优化问题，用优化方法求解，比如梯度下降
- 动画绑定(Rigging)
  - rigging 是一种对角色更高层次的控制，允许更快速且直观的调整姿势、表情等。皮影戏就有点这个味道，但是提线木偶对表情、动作的控制更贴切一些
  - 在角色身体、脸部等位置创造一系列控制点，美工通过调整控制点的位置，带动脸部其他从点移动，从而实现表情变化，动作变化等
  - Blend Shapes：直接在两个不同关键帧之间做插值，注意是对其表面的控制点做插值
- 动作捕捉 (Motion capture)
  - 在真人身上放置许多控制点，在不同时刻对人进行拍照，记录控制点的位置，同步到对应的虚拟人物上

== 动画技术（粘贴自我的 #link("http://crd2333.github.io/note/CV/Human")[人体三维重建笔记]）
- 在正式进入人体三维重建的领域之前，我们可以先看看工业界是如何表示人体并做动画的。*主要*是基于骨骼动画 (Skeletal Animation) 和蒙皮 (skinning) 来实现（可以看 #link("https://www.bilibili.com/video/BV1jr4y1t7WR?share_source=copy_web&vd_source=19e6fd31c6b081ac5b8486c112eafa1f")[08.游戏引擎的动画技术基础(上) | GAMES104-现代游戏引擎：从入门到实践]）
- 模型是由大量顶点 (Vertex) 组成的，或者每三个一组称为网格 (Mesh)，一般来自 blender 或 Maya 这种专门的建模软件。我们知道图形渲染管线是基于 mesh，密集 mesh 构成 geometry，再往 mesh 上面进行纹理映射，为模型添加 appearance
- 但如果想移动任何网格，显然直接移动那么多网格的顶点到指定位置是不实际的，需要添加骨骼 (Skeleton)，有时也叫骨架 (Armature)，就像现实世界一样人体由一根根骨头 (Bone) 组成骨骼
  - 如何产生骨架？可以用正向动力学 (Forward Kinematics)、反向动力学 (Inverse Kinematics)
  - 有了骨骼控制起来就方便多了，但我们还想让角色摆姿势更加方便，于是人们定义骨骼之间的父子节点关系、巧妙设计并组合一些约束（也跟人体很像不是吗），这叫做绑定 (Rigging)。并且添加一些控制器，这样很多需要多个骨骼协同工作的动作就可以通过一个控制器来实现
  - By the way，其实说是骨骼，实际上指的是关节，关节之间的 bone 一般是比较刚性的
  - 这一整套技术实际上不仅应用于人体，而是做 3D 动画的通用方法，应用于各种武器、衣着等（这里就不科学了，外骨骼 bushi）
- 我们希望骨骼和 mesh（或者说大量顶点）以某种方式结合起来，这就是蒙皮 (Skinning)。一根骨头可以控制很多顶点，同时我们希望一个顶点也可以被多根骨头控制（即混合蒙皮，blend skinning）
  - 那么蒙皮到底是怎么实现顶点的变换呢？具体而言：
    - 任何骨骼模型都会有：一个初始位姿 (rest pose) 下的 mesh 上所有顶点位置 $v_1, v_2, ..., v_n in RR^3$，每个骨骼 (joint) 的变换矩阵 $M_1, M_2, ..., M_k in RR^(3 times 4)$（一般是在局部坐标系下，需要乘上父节点的变换矩阵才能得到世界坐标系下的变换矩阵）
    - 在骨骼运动后，新顶点的位置由如下公式给出
      $ overline(v)_i = sum_(j=1)^k w_(i,j) T_j^m (T_j^r)^(-1) v_i $
      - 其中，任意新顶点 $overline(v)_i$ 表示为受到所有骨骼（业界一般会限制在 $4$ 个以下）的影响，通过权重 $w_(i,1), w_(i,2), ..., w_(i,k) in RR$ 来混合
      - $T_j^r$ 表示第 $j$ 个骨骼在 rest pose 下（因此它是个固定量，不用像 $T_j^m$ 一样每帧计算）从局部坐标系到世界坐标系的变换矩阵，$v_i$ 左乘它的逆也就是变换得到这个顶点相对骨骼 $j$ 的位置
      - $T_j^m$ 表示第 $j$ 个骨骼在 moved pose 下从局部坐标系到世界坐标系的变换矩阵，左乘它得到移动后世界坐标系下第 $j$ 块骨骼贡献的 $v_i$ 新位置
      - 考虑所有骨骼 $j$ 的影响，将它们加权组合就得到上式
  - 这时就需要分配这些骨头对该顶点的权重，这是通过各种蒙皮算法实现的。其中最著名的一个就是线性混合蒙皮，而线性混合蒙皮 (LBS) 是指权重是线性的，使用最广泛，但在关节处可能产生不真实的变形
  - 所谓蒙皮，在 Blender 这种建模软件上其实就是一个快捷键的事，一般来说 Blender 的自动权重已经比较准确了，但也可以手动分配，也就是所谓的刷权重 (Weight Painting)
- 所以整个动画设计的 Pipeline 大致如下 (from GAMES104)：
  + Mesh：网格一般分为四个 Stage: Blockout, Highpoly, Lowpoly, Texture。这里一般会制作固定姿势的 mesh (T-pose / A-pose)，把高精度的 mesh 转化为低精度，有时还会为肘关节添加额外的细节来优化
  + Skeleton binding：在工具的帮助下创建一个跟 mesh 匹配的 skeleton，绑定上跟 game play 相关的 joint
  + Skinning：在工具的帮助下通过权重绘制，将骨骼和 mesh 结合起来
  + Animation creation：将骨骼设置为所需姿势，做关键帧，之后插值出中间动画
  + Exporting：一般把 mesh, skeleton, skinning data, animation clip 等统一导出为 `.fbx` 文件。一些细节上的处理比如跳跃动画的 root 位移不会存下来而是用专门的位移曲线来记录
  #fig("/public/assets/CV/Human/2024-11-02-19-54-23.png", width: 50%)
- 这里额外拓展一下做动画的其它方法（从 GAMES104 看来的）。实际上业界做动画的几种方式里面，骨骼动画是最基础最广泛的一种，但绝不是唯一（主要是想讲一下 blend shape 方法，因为后面会提到）
  + 对于动作比较小又追求高精度的地方（典型的比如人体面部表情），骨骼动画就不那么适用了，这时候就需要 *Morph 动画*，每个关键帧都存储了 Mesh 所有顶点对应时刻的位置
    - 这样精度是上去了，但内存占用也变得不可接受，并且随着表面细节增多计算量也会变很大。
    - 另外，很自然地我们会想，能不能只存储从中性形状 Mesh 到目标形状 Mesh 的 offset，用插值来确定这个形变的强弱，并且用少量这种基础形状的组合 (blend) 来产生动画呢？这其实就是 *Blend Shape*（Morgh 动画的一种）
      - 特定地，在面部表情动画里，基础形状就是根据面部动作编码系统 (Facial Action Coding System, FACS) 定义的一系列 key poses，通过这些类似基函数的东西组合出各种面部表情
    - Blend Shape 往往与骨骼动画结合使用。比如面部表情动画中，嘴巴张开这种相对较大的动作还是用骨骼实现，而嘴角弧度等精细控制由 key poses 组合得到
  + 从驱动的角度来看，除了 *Skeleton Driven* 之外，还有 *Cage Driven* 的方法，即在 mesh 外围生成一个低精度的 mesh 包围盒，用这个低精度的变化来控制高精度的 mesh
  + 对于*面部表情动画*，还有一个很生草的办法是直接把一系列纹理映射到 head shape 上 (*UV Texture Facial Animation*)，对卡通动画比较适用（比如我最喜欢的游戏《塞尔达传说：旷野之息》，还有《动物森友会》也是这么做的）。以及还有一些最前沿的停留在科研阶段的方法（影视行业已经开始用了）如 *Muscle Model Animation*，直接基于物理去驱动面部的 $43$ 块肌肉来实现各种表情，也许是引擎的未来
- 个人认为，所谓骨骼、蒙皮这些概念，就是工业界探索得出的一条既能高精度表示（大量 vertices），又能高效控制（使用蒙皮约束大大减小解空间）的办法，基于图形渲染管线，兼顾美工设计需求（抽象掉了具体的很多细节），更专注于切实可用

== 求解常微分方程
- 单粒子模拟 (Single Particle Simulation)
  - 之前讲的多粒子系统只是宏观上的描述，现在我们对单个粒子进行具体方法描述，这样才能扩展到多粒子
  - 假设粒子的运动由*速度矢量场*决定，速度场是关于位置和时间的函数（定义质点在任何时刻在场中任何位置的速度）：$v(x, t)$，从而可以解常微分方程来得到粒子的位置
  - 怎么解？使用欧拉方法（a.k.a 前向欧拉或显示欧拉）
- 欧拉方法
  - 简单迭代方法，用上一时刻的信息推导这一时刻的信息 $x^(t+Delta t)=x^t + Delta t dot(x)^t$
  - 误差与不稳定性：用更小的 $Delta t$ 可以减小误差，但无法解决不稳定性（比如不管采用多小的步长，圆形速度场中的粒子最终都会飞出去，本质上是误差的阶数不够导致不断累计）
    - 定义稳定性：局部截断误差 (local truncation error) —— 每一步的误差，全局累积误差 (total accumulated error) —— 总的累积误差。但真正重要的是步长 $h$ 跟误差的关系（阶数）
  - 对抗误差和不稳定性的方法
    - 中点法 (or Modified Euler)：质点在时刻 $t$ 位置 $a$ 经过 $De t$ 来到位置 $b$，取 $a b$ 中点 $c$ 的速度矢量回到 $a$ 重新计算到达位置 $d$
      - 每一步都进行了两次欧拉方法，公式推导后可以看作是加入了二次项
    - 自适应步长 (Adaptive Step Size)：先用步长 $T$ 做一次欧拉计算 $X_T$，再用步长 $T/2$ 做两次欧拉得到 $X_T/2$，比较两次位置误差 $"error" = norm(X_T - X_T/2)$，如果 error > threshold，就减少步长，重复上面步骤
    - 隐式欧拉方法 (Implicit Euler Method)：用下一个时刻的速度和加速度来计算下一个时刻的位置和速度，但事实上并不知道下一时刻的速度和加速度，因此需要解方程组。
      - 局部误差为 $O(h)$，全局误差为 $O(h^2)$
    - 龙格库塔方法 (Runge-Kutta Families)：求解一阶微分方程的一系列方法，特别擅长处理非线性问题，其中最常用的是一种能达到 $4$ 阶的方法，也叫做 RK4
      - 初始化
        $ (di y)/(di t)=f(t,y), ~~ y(t_0)=y_0 $
      - 求解方法（下一时刻等于当前位置加上步长乘以六个速度的平均）
        $ t_(n+1)=t_n+h, ~~ y_(n+1)=y_n+1/6 h(k_1+2k_2+2k_3+k_4) $
      - 其中 $k_1 \~ k_4$ 如下，具体推导为什么是四阶就略过（可以参考《数值分析》）
        $ k_1=f(t_n, y_n), ~~ k_2=f(t_n+h/2, y_n+h/2 k_1), ~~ k_3=f(t_n+h/2, y_n+h/2 k_2), ~~ k_4=f(t_n+h, y_n+h k_3) $
- 非物理的方法
  - 基于位置的方法 (Position-Based)、Verlet 积分等方法
  - Idea：使用受限制的位置来更新速度，可以想象成一根劲度系数无限大的弹簧
  - 优点是快速而且简单；缺点是不基于物理，不能保证能量守恒

== 刚体与流体
- 刚体：不会发生形变，且内部所有粒子以相同方式运动
  - 刚体的模拟中会考虑更多的属性
  $ di/(di t) vec(X, th, dot(X), omega) = vec(dot(X), omega, F/M, Gamma/I) $
  - 有了这些属性就可以用欧拉方法或更稳定的方法求解
- 流体，使用基于位置的方法 (Position-Based Method)
  - 前面已经说过流体可以用粒子系统模拟，然后我们用基于位置的方法求解
  - 主要思想：水是由一个个刚体小球组成的；水不能被压缩，即任意时刻密度相同；任何一个时刻，某个位置的密度发生变化，就必须通过移动小球的位置进行密度修正；需要知道任何一个位置的密度梯度（小球位置的变化对其周围密度的影响），用机器学习的梯度下降优化；这样简单的模拟最后会一直运动停不下来，我们可以人为的加入一些能量损失
- 模拟大量物体运动的两种思路：
  - 拉格朗日法（质点法）：以每个粒子为单位进行模拟
  - 欧拉法（网格法）：以网格为单位进行分割模拟（跟前面解常微分方程不是一回事）
  - 混合法 (Mterial Point Method, MPM)：粒子将属性传递给网格，模拟的过程在网格里做，然后把结果插值回粒子

#end_of_note()