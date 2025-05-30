#metadata(
  (
    order: 1,
  )
)<frontmatter>

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "计算机视觉导论",
  lang: "zh",
)

#info()[
  - 部分参考 #link("https://lhxcs.github.io/note/AI/cv/icv/")[lhxcs 的计算机视觉笔记]
]

#let blur = math.text("blur")
#let lerp = math.text("lerp")

= Introduction
== What's Computer Vision
- Computer vision tasks
  - 3D reconstruction 3D 重建
    - 3D reconstruction 3D重建，localization 定位，SLAM 即时定位重建……
  - Image undestanding 图像理解
    - Image recognition 图像识别，object detection 物体识别，image segmentation 图像分割，action recognition 动作识别，deep learning 深度学习……
  - Image synthesis 图像合成
    - Colorization 着色，super-resolution 超采样，debluring 去模糊，HDR 合成，panorama stitching 全景拼接，free-viewpoint rendering 自由视角渲染，GANs 生成对抗网络……
- Can computers match human perception
  - 我们人类看到的是图像，而计算机看到的是像素值
  - computers can be better at *computing*; humans are better at *understanding*
  - 但具体为什么，还有待对人类智能的研究
  - 人类视觉常常被误导

== What's Computer Vision used for
- 计算机视觉的各种应用
  #grid(
    columns: (33%, 33%, 33%),
    [
      + Face ID
      + DeepFake
      + Augmented reality
      + Factory Automation
      + Vision Inspection
      + Optical Character Recognition(OCR)
    ],
    [
      7. Video Surveillance
      + Human Computer Interaction
      + Visual Effects (VFX)
      + Digital Human
      + Sports Broadcasting
      + 3D Street View
    ],
    [
      13. VR Tour
      + Visual Localization and Navigation
      + Autonomous Navigation and Driving
      + Robot Perception
      + Free Viewpoint Video
      + Medical Image Analysis......
    ]
  )

== Course Overview
- Basics (Lec.2 - Lec.4)
- Reconstruction (Lec.5 - Lec.8)
- Understanding (Lec.9 - Lec.11)
- Synthesis (Lec.12 - Lec.13)

== Review of Linear Algebra
- 向量的各种运算
- 矩阵的各种运算
  - 矩阵可以理解为几何变换，*每列*描述*基*变换后的坐标
  - 从几何角度理解矩阵可逆：变换前后的两个点一一对应
  - 仿射变换：线性变换 + 平移
  - 齐次坐标：多一维表示，把平移纳入单个矩阵乘法
  - 行列式 (marix determinant)：几何意义为 $n$ 维平行体张成的有向面积（体积）
  - 矩阵的特征分解
  - 矩阵的奇异值分解

= Image Formation
== 针孔相机模型
- 假如直接在物体面前放一个底片，由于像平面上的一个点接收到物体上各个方向的光线，因此无法成像
  - 使用小孔成像阻挡大部分光线，使得一一对应关系成立。这个孔就称作光圈 aperture
  #grid2(
    columns: (50%, 50%),
    column-gutter: 4pt,
    fig("/public/assets/Courses/CV/2025-01-07-22-07-10.png"),
    fig("/public/assets/Courses/CV/2025-01-07-22-45-34.png")
  )
- 问题
  + 当孔太小时，会产生光的衍射现象；
  + 并且孔太小也会导致通光量不足

== 透镜成像
- 使用透镜，保持一一对应关系的同时汇聚更多的光。其成像位置表达式如下：
  $ 1/i + 1/o = 1/f $
  - If $o -> infty$, then $f=i$
- *放大率 (magnification)*
  $ m=(h_i)/(h_o)=i/o $
  - 由于 $o$ 较大时，$i$ 近似等于 $f$，可以说焦距也决定了图像放大率（拍照调焦的原理）
- *Field of View (FOV)*
  - 取决于焦距与底片 (sensor) 的大小：跟 focal length 负相关，跟 sensor size 正相关
    #fig("/public/assets/Courses/CV/2025-01-08-09-06-46.png", width: 60%)
  - 从成像质量来看，底片越大越好（每个像素收到的光更多，信噪比更好）；从成本和便携性来看，底片越小越好
    - 现在的工业目标就是在缩小底片的同时维持好的信噪比
- *光圈 (Aperture) 与光圈数 (F-number)*
  #fig("/public/assets/Courses/CV/2025-01-08-09-12-00.png", width: 60%)
  - 光圈大小 $D$ 是指透镜的直径（注意与 sensor 区分）
  - 光圈大小可调，在固定焦距 $f$ 的情况下，把二者表示为比值会更方便，称为光圈数 (F-number)
    $ N=f/D $
  - 通过放大 / 缩小光圈来控制图像的亮度，*光圈数越大，光圈越小，进光量越少*
- *Lens Defocus & Blur Circle*
  - 当 $f$ 和 $i$ 固定时，理论上只有一个面（深度）在成像平面上是清楚的，所以我们需要对焦（略微调整底片位置或透镜位置）
  - 弥散圆 (Blur circle diameter)
    - 投影到像平面上的光斑，亦称 circle of confusion
    $ b=D / i' |i'-i| prop D prop 1/N $
  #fig("/public/assets/Courses/CV/2024-09-19-11-22-07.png", width: 60%)
- *景深 (Depth of Field)*
  - 我们可能会疑惑生活中的照片并非仅有一个深度才是清晰的。利用弥散圆与 defocus 的概念对此解释，因为图像并非连续而是由一个个方格（像素）构成，当弥散圆落在一个像素内时，它表现出来也是清晰的
  - 据此更进一步，对可清晰成像的范围做定量分析，就引入了景深的概念
    #fig("/public/assets/Courses/CV/2024-09-19-11-25-42.png", width: 60%)
    $
    "相似三角形关系分别计算" c = (f^2 (o-o_1))/(N o_1(o-f)) = (f^2 (o_2-o))/(N o_2(o-f))\
    "Depth of Field" o_2 - o_1 = (2o f^2 c N (o-f))/(f^4 - c^2 N^2 (o-f)^2)
    $
- 综合利用以上概念，可以得到背景虚化、人物清晰的照片
  + Large aperture，$D arrow.tr, N arrow.br$，增大进光量
  + Long focal length，把上式分子分母同除以 $f(o-f)$，可以得到 $f arrow.tr ~~ => ~~ "depth of filed" arrow.br$
  + Near foreground & Far Background (accurate focus)，使人物落入景深而背景不在景深内

== Geometric image formation
- *使用 Pin-hole camera model 描述投影*
  #fig("/public/assets/Courses/CV/2024-09-20-17-00-54.png", width: 50%)
  - 这里没说的一点是，一般图像平面的原点我们选在左上角或是左下角（较少），而不会选在中心。于是我们需要加上这个中心点的偏移量，即 $x = x' + w/2, y = y' + h/2$。这个加上的值即为所谓的*主点 (principal point)*
  - 该式*并非线性变换*，是透视投影的一种，如下所述
- 引入*齐次坐标*，将投影表示为线性变换
  $ mat(f,0,0,0;0,f,0,0;0,0,1,0) vec(x,y,z,1) = vec(f x,f y,z) #sym.tilde.equiv vec(f x/z, f y/z, 1) $
  #fig("/public/assets/Courses/CV/2024-09-19-11-41-05.png", width: 40%)
- *Projection can be tricky*
  #fig("/public/assets/Courses/CV/2025-01-08-09-49-35.png", width: 50%)
  - 在透视投影中，直线仍然是直的，但*长度和角度丢失*了。深度信息*部分*丢失，虽然近大远小，但同一个图像对应无穷多三维形状
  - *Vanishing points & Vanishing lines*
    #grid2(
      fig("/public/assets/Courses/CV/2025-01-08-09-54-58.png", width: 90%),
      fig("/public/assets/Courses/CV/2025-01-08-09-55-08.png", width: 60%)
    )
    - 平行线不再平行，它们的焦点就是*消失点*；相机中心 $c$ 与消失点 $v$ 连线与这些平行线平行
    - 平面上的任何一组平行线都定义了一个消失点，所有这些消失点的结合就是*消失线*（任意两个消失点的连线就是消失线）
    - 不同的成像平面*唯一*定义了不同的消失线，反映出平面的 orientation
- *投影失真 Perspective distortion*
  - Problem for architectural photography: converging verticals
    #fig("/public/assets/Courses/CV/2024-09-20-19-38-53.png", width: 80%)
    - Solution: 取景器(view camera)，镜头相对胶片可以移动
  - Problem for sphere project: The exterior columns appear bigger
    #fig("/public/assets/Courses/CV/2025-01-08-10-01-54.png", width: 40%)
  - 这种畸变*并非由透镜缺陷*引起！
- *径向失真 Radial distortion*
  #fig("/public/assets/Courses/CV/2024-09-20-19-40-21.png", width: 40%)
  - 分为桶形畸变 (barrel distortion) 和枕形畸变 (pin cushion distortion)
  - 由*现实镜头的非理想性引起*，对于穿过透镜边缘的光线更为明显
- *Orthographic Projection 正交投影*
  $ mat(1,0,0,0;0,1,0,0;0,0,0,1) vec(x,y,z,1) = vec(x,y,1) => vec(x, y) $
  - 深度信息完全丢失

== Photometric Image Formation
- 描述了 3D 世界物理性质与 2D 图像颜色之间的关系
- Image sensor
  - CMOS: Complementary Metal-Oxide-Semiconductor
- Shutter
  - 快门速度控制曝光时间
  - *The pixel value is equal to the integral of the light intensity within the exposure time*
  - global shutter v.s. rolling shutter
    - 前者所有像素同时曝光，后者逐行曝光
    - 后者会导致 rolling shutter effect，参考 #link("https://blog.csdn.net/abcwoabcwo/article/details/93099982")[这篇文章]
- Color spaces: RGB, HSV
  #grid2(
    fig("/public/assets/Courses/CV/2025-01-08-10-15-36.png", width: 90%),
    fig("/public/assets/Courses/CV/2025-01-08-10-15-59.png", width: 90%)
  )
  - 人眼对 RGB 敏感程度不同，单色中对红色最不敏感，蓝色最敏感，所以 RGB 颜色空间均匀性较差
  - 使用 HSV 颜色空间，更接近人们对彩色的感知
    + Hue（色调，色相）：表示色彩信息
    + Saturation（饱和度、色彩纯净度）：饱和度越高，颜色越深。饱和度 $0$ 代表纯白色
    + Value（明度）：颜色的敏感程度，明度为 $0$ 表示纯黑色
  - images in Python: $N times M times 3$ as a matrix
- Bayer filter
  - 对于彩色图像，需要采集多种基本的颜色，最简单的方法是用滤镜的方法
  - 如果要采集 RGB 三种颜色，则需要三种滤镜，价格昂贵
  - 而拜尔滤镜 (Bayre Filter) 在一块滤镜上 (sensing with a single chip) 设置不同颜色，由于人眼对绿色比较敏感，因此绿色较多
- Model the light reflected by an object: Shading
  - 后面的内容是直接 copy from GAMES101，Blinn Phong 光照模型和 BRDF 等
  - 参见 #link("https://crd2333.github.io/note/Courses/%E8%AE%A1%E7%AE%97%E6%9C%BA%E5%9B%BE%E5%BD%A2%E5%AD%A6/index/")[计算机图形学笔记]

= Image Processing
== Image processing basics
- 一些基本处理
  + Increase contrast: 使用 S curve 增大对比度
  + Invert: 颜色取反
  + Blur, Sharpen, Edge detection
- Convolution
  - 数学上的卷积与图像处理中的 Discrete 2D Convolution
- Padding
- 几种 filter
  - Guassian blur: 使用二维高斯函数
    $ f(i, j)= 1/(2 pi sigma^2) e^(- (i^2+j^2)/(2 sigma^2)) $
    - $sigma$ 越大越模糊
  - Sharpen
    - 卷积核做锐化
      $ mat(0,-1,0;-1,5,-1;0,-1,0) $
    - 锐化操作就是往图像里添加高频信息
      + Let $I$ be the original image
      + High frequencies in image $I=I-blur(I)$
      + Sharpened image $I'= I+(I-blur(I))$
  - Edge detection filter
    $ "vertical" mat(-1,0,1;-2,0,2;-1,0,1), ~~~~ "horizontal" mat(-1,-2,-1;0,0,0;1,2,1) $
  - Bilateral filter
    - 保持边缘的同时去除噪声

== Image Sampling
- 采样是把一个连续的函数离散化的过程，但在采样时有可能发生*失真（反走样/锯齿）*现象
- 主要原因是 —— 采样的速度跟不上信号变化的速度（高频信号采样不足）
  #fig("/public/assets/Courses/CV/2025-01-08-10-37-16.png", width: 60%)

=== Fourier Transform
- 傅里叶变换本质上是把函数与不同频率的三角函数做内积，得到它在不同频率下的分量
  - 即：用不同频率的正余弦函数加权表示原函数
  #fig("/public/assets/Courses/CV/2024-09-26-11-49-09.png", width: 60%)
- PPT 里展示了一些常见的信号的傅里叶变换
  #tbl(
    columns: 2,
    [spatial domain], [frequency domain],
    [$sin(2pi\/32)$],[frequency $1\/32$, $32$ pixels per cycle],
    [$sin(2pi\/16)$],[frequency $1\/16$, $16$ pixels per cycle],
  )

=== Signal & Frequency
- *Convolution Theorem*
  #fig("/public/assets/Courses/CV/2024-09-26-12-00-47.png", width: 60%)
  - Box filter = low-pass filter
    - Wider kernel = lower frequency（可以这么想，宽到整张图大小，相当于频率低到 $0$，不做任何滤波）
- Sampling
  - Sampling a signal = multiply the signal by a Dirac comb function（狄拉克函数）
  - Sampling = Repeating Frequency Contents
  - Aliasing = Mixed Frequency Contents
- anti-alisaing
  - Option I: 增大采样频率
    - How large is enough? *Nyquist-Shannon Theorem*
      - Consider a band-limited signal: has no frequencies above $f_0$
      - The signal can be perfectly reconstructed if sampled with a frequency larger than $2 f_0$，即至少两倍
  - Option II: 低通滤波
    - Filtering = convolution
    + Convolve the image with low-pass filters (e.g. Gaussian)
    + Sample it with a Nyquist rate（使用降采样后的两倍频率即可）
- 其实基本也都是图形学的内容

== Image magnification
- 图像放大时基本使用 Interpolation 或者 Super-Resolution (AI)
  - 插值函数的选择
    #grid(
      columns: 4,
      fig("/public/assets/Courses/CV/2025-01-08-10-48-56.png", width: 80%),
      fig("/public/assets/Courses/CV/2025-01-08-10-49-02.png", width: 80%),
      fig("/public/assets/Courses/CV/2025-01-08-10-49-06.png", width: 80%),
      fig("/public/assets/Courses/CV/2025-01-08-10-49-13.png", width: 80%)
    )
    - Nearest neighbor: 不连续，不光滑
    - Linear: 连续，不光滑
    - cubic: 连续，光滑
  - Interpolation
    - Nearest neighbor
    - Bilinear
      $ u0 = lerp(s, u_00, u_10) \ u1 = lerp(s,u_01,u_11) \ f(x,y) = lerp(t,u_0,u_1) $
    - Bicubic
      $ p(x,y) = sum_(i=0)^3 sum_(j=0)^3 a_ij x^i y^j $
- How to change aspect ratio
  - 最简单的方法就是在长宽方面进行不同的缩放，但会导致形变。要防止形变就只能裁剪
  - Challenge
    + Changing aspect ratio causes distortion
    + Cropping may remove important contents
  - Solution: Seam Carving for *Content-Aware* Image Resizing
    - Basic idea: remove unimportant pixels
    - 如何衡量像素点的重要性？A simple idea: edges are important, define edge energy
    $ E(I) = abs((diff I) / (diff x)) + abs((diff I) / (diff y)) $
    - Find connected path of pixels from top to bottom of which the edge energy is minimal
      - 可以认为就是寻找最短路算法（DP 算法），然后把这条路 (called a seam) 的像素扔掉
    #fig("/public/assets/Courses/CV/2024-10-10-10-17-49.png", width: 70%)
    #mitex(`\mathbf{M}(i,j)=E(i,j)+\min\big(\mathbf{M}(i-1,j-1),\mathbf{M}(i-1,j),\mathbf{M}(i-1,j+1)\big)`)
    - seam carving 方法也可以应用于 enlarge image，原理类似 (Find $k$ seams to insert, then interpolate pixels)

= Model Fitting and Optimization
== Optimization
- 优化的基本范式，与优化基本理论与方法没什么差别
- 一个有趣的 example: Image deblurring
  - 已知模糊图像 $Y$ 和卷积核 $F$，通过优化的方法得到去噪后的图像 $X$
  - 想法是找到清晰的图像 $X$，使得它做模糊处理后与已知的图像 $Y$ 差别尽可能小，于是得到目标函数
    $ min_X norm(Y - F*X)_2^2 $
  - 在 @NBID 会更详细介绍

=== Model Fitting
- 一个经典的例子：Minimize the *Linear Mean Square Error (Linear MSE)*
- 如果假设数据噪声服从*高斯分布*，那么可以与*极大似然估计*联系起来
  - Maximum Likelihood Estimation (MLE) = Maximize the likelihood to find the best $x$
  - (Linear) MSE = *MLE* with *Gaussian noise* assumption
  $
  b_i = a_i^T + n, ~~~~ n wave G(0, sigma^2) \
  P[(a_i, b_i)|x] = P[b_i - a_i^T x] #sym.prop exp(- (b_i - a_i^T x)^2 / (2 sigma^2)) \
  P[(a_1, b_1) (a_2, b_2) ... (a_n, b_n)|x] #sym.prop exp(- sum_i (b_i - a_i^T x)^2 / (2 sigma^2)) = exp(- norm(A x - b)_2^2 / (2 sigma^2)) \
  hat(x) = argmax_x P[(a_1, b_1) (a_2, b_2) ... (a_n, b_n)|x] = argmin_x norm(A x - b)_2^2
  $

== Numerical methods
- 一些问题有 analytical solution，但是大多数问题需要 numerical solution
- Recap: Taylor expansion
  - *first-order* approximation: *Jacobian* matrix
  - *second-order* approximation: *Hessian* matrix

=== 梯度下降法 Gradient Descent
==== Steepest descent method
$ F(x_0+De x) approx F(x_0) + J_F De x $
- Advantage
  + Easy to implement
  + Perform well when far from the minimum
- Disadvantage
  + Converge slowly when near the minimum
  + Waste a lot of computation
- Why converge slowly?
  + Only use first-order derivative
  + Does not use curvature

==== Newton's method
$
F(x_0+De x) approx F(x_0) + J_F De x + 1/2 De x^T H_F De x \
"minimize" F(x_k+De x) => De x = - H_F^(-1) J_F^T
$
- 考虑了二阶导数的泰勒展开，寻找 $De x$ 使得展开式最小
- Advantage: fast convergence near the minimum
- Disadvantage: Hessian requires a lot of computation

==== Gauss-Newton method
$
hat(x) = argmax_x F(x) = argmin_x norm(R(x))_2^2 \
R(x)=vec(b_1-f_x (a_1), dots.v, b_n-f_x (a_n)) #[is called the *residual vector*] \
norm(R(x_k)+De x)_2^2 approx norm(R(x_k))_2^2 + 2 R(x_k)^T R(x_k) + 2 R(x_k)^T J_R De x + De x^T J_R^T J_R De x \
De x = -(J_R^T J_R)^(-1) J_R^T R(x_k)
$
- 不优化原始而是优化残差向量；使用 Jacobian 矩阵 $J_R^T J_R$ 近似 Hessian 矩阵 $H_F$，大大减小计算量
- Advantage: faster than Newton's method
- Disadvantage: $J_R^T J_R$ 不正定，未必可逆

==== Levenberg-Marquardt method
$ Delta x = -(J_R^T J_R + lambda I)^(-1) J_R^T R(x_k) $
- 添加正则项，使 $J_R^T J_R + lambda I$ 正定，保证高斯牛顿法成立
  + $la -> infty$: Gradient Descent
  + $la -> 0$: Gauss-Newton
- Advantage:
  + Start quickly（远离目标点时使用最速梯度下降）
  + Converge quickly（接近目标点时近似高斯牛顿法，保证收敛速度快）
  + Do not degenerate（矩阵永远正定）

=== Robust estimation
- Outliers: 使得最小二乘法受很大影响，它会过度放大偏离较大的误差
- Huber loss function
  $ L_"huber" (e) =cases( 1/2 e^2\, |e| =< delta, delta dot |e| - 1/2 delta^2\, |e| > delta) $
  - 在误差较小时，与 MSE 一样，但是在误差较大时，它的影响会减小（减小 outliers 的影响）
- RANSAC: Random Sample Concensus
  - The most powerful method to handle outliers
  - 主要思想
    + The distribution of *inliers is similar* while *outliers differ a lot*
    + Use data point pairs to vote
  - 步骤
    + 首先我们知道拟合一条直线只需要两个点，因此首先随机找两个点拟合一条直线
    + 然后检查有多少点符合该直线（点到直线的距离小于一定的阈值，就 `count++`）
    + 一直重复该过程，选择 count 最高的直线

=== Overfitting and Underfitting
- Regularization
  - L1-norm, L2-norm，L1 正则化使解变得稀疏

=== Graph cut
- 用优化的方法（区别于以后讲的基于学习的方法）解决图像分割问题
- Prior: Neighboring pixels tend to take the same label

= Computational Photography
- 计算摄影学的任务就是通过算法使得拍出来的图像质量更高
  - 从三维视觉内容又回到了二维图像处理，所以这节课虽然是 lec12，但我提到前面来了

== High dynamic range imaging(HDR)
=== HDR conception
- HDR, 即高动态范围成像
  - 回想我们生活中，在晚上拍照时，照片会出现要么一片黑，要么一片亮的情况。原因是晚上的场景对比度太大，而这种明暗的对比度就被称作动态范围
  - HDR 可以做到既捕捉亮处的细节，也捕捉到暗处的细节
- 对于相机，它每个像素的曝光(exposure)取决于如下三个因素：
  $ "Exposure" = "Gain" times "Irradiance" times "Time" $
  + 增益 (Gain): controlled by the ISO. 可以理解为光电信号转化的效率。ISO 是底片的感光度
    - ISO 越高越灵敏，但是也会导致噪声增加
    - 当然噪声跟传感器质量也有关，传感器越大，同一个像素对应的光子数就越多，噪声就越小
  + 辐射度 (Irradiance): 可以理解为打到底片上的光的数量（光强），取决于光圈 (aperture) 的大小
    - 光圈决定通光量，同时也决定景深 (Depth of Field)
  + 曝光时间 (Time)：由快门速度控制
    - shutter speed: 快门开闭是有时间的，且 sensor 上原本的颜色清空也需要时间
    - 快门速度越长，进光量越多，但是也会导致运动模糊
  - 一般会有自动调节曝光的功能 the averaged exposure should be at the middle of the sensor's measurement range
  #fig("/public/assets/Courses/CV/2024-12-06-19-10-06.png",width:60%)
- Dynamic range
  - 即一个场景中最亮地方和最暗地方的比值。在夜晚拍照时，由于场景动态范围太大，暗处和亮处的细节不能兼得，就会造成上图的两种情况
  #tbl(
    columns:2,
    [$10:1$],[photographic print (higher for glossy paper)],
    [$256:1$],[8-bit RGB image],
    [$1000:1$],[LCD display（一些高端显示器，比如打游戏用的会更高）],
    [$4096:1$],[digital SLR 单反相机 (at 12 bits)],
    [$100000:1$],[real world]
  )
  - 真实世界具有很大的动态范围，但是相机的传感器只能覆盖很小的动态范围，这就是我们拍照不能兼顾明暗细节的原因
    - 事实上人眼的动态范围也很大，这就是为什么我们总感觉自己看到的和拍到的不一样
  - Challenge: sensor's measurement range(dynamic range) 跟 real world 不匹配！而 8bit RGB image 动态范围更低

=== HDR imaging
- 那怎么解决呢？一个很直观的想法就是我们拍多张图像，部分图像用较小的曝光时间，记录亮处的细节，另一部分图像用较长的曝光时间，记录暗处的细节，最后将所有图像合成得到最终的图像
  - Key Idea
    + *Exposure bracketing*: Capture multiple LDR images at different exposures
    + *Merging*: Combine them into a single HDR image
  - 数学描述
    - Suppose scene radiance for image pixel $(x, y)$ is $L(x, y)$
    - Expression for the image $I(x, y)$ as a function of $L(x, y)$
      $ I(x, y) = "clip"[t_i dot L(x, y) + "noise"] $
  - 对于图像合成，有以下几个步骤：
    - For each pixel:
      + Find "valid" pixels in each image
        - 既不要太亮也不要太暗，我们即认为它处于合理的区间 $0.05 "(noise)" < "pixel" < 0.95 "(clipping)"$
      + Weight valid pixel values appropriately ($"pixel value" \/ t_i$)
      + Form a new pixel value as the weighted average of valid pixel values
      #fig("/public/assets/Courses/CV/2024-12-06-19-30-44.png",width:80%)
- 这样我们拍出了一个较大动态范围的原始照片，但还是要把它映射到低动态范围的 image，该过程称为 *tone mapping*
  - 这势必要做 compression
    - 一种方法是采用 Linear compression，但色调会变得不自然
    - 另一种则是非线性的 Gamma compression
      - $gamma$ 小于 $1$ 时，图像整体变亮，增强暗部细节；$gamma$ 大于 $1$ 时，图像整体变暗，增强亮部细节
    #fig("/public/assets/Courses/CV/2024-12-06-19-22-38.png",width:30%)
  - 许多相机会自动帮我们做这件事，如果我们要自己调的话，需要存成 raw 格式

== Deblurring
- 任务是把模糊的图像变清楚
- 首先我们要知道图像模糊的原因：
  + 失焦模糊 (Defoucs blur): 目标在景深范围外 defoucs（在 lec2 介绍过），或者说对焦对到背景上去了，光斑取决于光圈形状
  + 运动模糊 (Motion blur): 成像的过程是对光强做积分的过程，倘若在这过程中相机或物体运动，成像结果就产生模糊。一般由曝光时间过长造成。在画面上形成运动的轨迹
- By the way, how to get a clear image?
  - Accurate focus
  - Fast shutter speed, Large aperture, High ISO（这也是为什么好的 SLR cameras and lenses 那么贵
  - hardware
    - tripod 三脚架，但不可移动
    - optical image stabilization and IMU，但很贵
  - 那么，我们就寻求 software 的方法，即 *deblurring*
- 去噪首先要用数学模型描述噪声
  - The blur pattern of *defocusing* depends on the *aperture shape*, The blur pattern of *shaking* depends on the *camera trajectory*
  - 回顾我们在 lec3 介绍的高斯模糊，采用了高斯核对图像进行卷积操作。因此我们可以用卷积来描述模糊的过程
    - $F(X,Y)$ 是清晰的图像，$H(U,V)$ 是卷积核，与 $F$ 卷积后得到模糊的图像 $G(X,Y)$
    #fig("/public/assets/Courses/CV/2024-12-06-19-49-58.png",width:50%)
  - 因此我们要解决的问题就是去卷积，根据是否知道卷积核分成两种情况
  #fig("/public/assets/Courses/CV/2024-12-06-19-51-45.png",width:50%)

=== Non-blind image deconvolution (NBID) <NBID>
- 任务定义：给定模糊的图像和卷积核，求解原图
- 解决方法
  - 类比乘法只需要一个除法便可以还原。很自然想到*时域上的卷积等于频域上的乘积*
  - 因此将图像做个傅里叶变换，在频域上做个除法再转化回去即可
    #fig("/public/assets/Courses/CV/2024-12-06-19-54-32.png",width: 60%)
  - 但是有一个问题，卷积核 $H(u,v)$ 一般是一个低通滤波器；去卷积的过程相当于乘上 $1/H(u,v)$，这就成了一个高通滤波器
    #fig("/public/assets/Courses/CV/2024-12-06-19-57-24.png",width: 50%)
    - 所以去卷积我们是在放大高频信息，但与此同时也会相应放大高频噪声。如果图像里完全没有噪声这是没问题的，但是这并不可能，现实中噪声是无处不在的
- *维纳滤波* (Wiener Fliter)
  - 解决这一问题的方法就是调整卷积核，即做 inverse fliter 的同时抑制高频噪声，即
    #fig("/public/assets/Courses/CV/2024-12-08-12-18-22.png",width: 60%)
  - 应用
    - 比如高速公路上车牌的去模糊，由于车的轨迹是大概知道的（沿着车道），因此卷积核也是大概知道的
    - 哈勃天文望远镜的镜头会有抖动，导致拍出来的图像是模糊的，但是我们知道镜头是什么样的，因此也可以用 NBID 去模糊
- 用*优化*的方法来解决
  - 优化变量：需要恢复的（清晰）图片。Blurred image generation process ($N$ is Gaussian noise):
    $ G = F times.circle H + N $
  - 目标函数与损失函数：清晰图像过卷积后与给定的模糊图像后的差别。用每个像素值差别的平方和(MSE)来衡量
    $ "MSE" = norm(G - F times.circle H)_2^2 = sumij [G_ij - (F times.circle H)_ij]^2 $
  - Problem: Deconvolution is *ill-posed* (Non-unique solution)
    #fig("/public/assets/Courses/CV/2024-12-08-12-35-31.png",width: 30%)
    - 如上图所示，两张图片都是我们优化问题的解，但是显然左边那张图更符合实际情况，注意到它的梯度图比较稀疏
  - 我们需要一些先验信息（解的约束条件）来解决 ill-posed 问题
    - 可以将要求梯度图稀疏作为先验条件，在优化函数上加一个 L1 正则项即可
      $ min_F norm(G - F times.circle H)_2^2 + norm(na F)_1 $

=== Blind image deconvolution(BID)
- 现在我们不知道卷积核是什么，这时候我们不能用逆向滤波求解，只能用优化的方式做，此时卷积核也成了优化的目标
- 我们希望卷积核也是稀疏并且非负的。所以目标函数为
  $ min_(F,H) norm(G - F times.circle H)_2^2 + la_1 norm(na F)_1 + la_2 norm(H)_1 ~ st H >= 0 $
- 这个算法其实是 SIGGRAPH 2006 的一篇文章: Removing Camera Shake from a Single Photograph

== Colorization
- 我们希望把黑白的图像转化成彩色图像，我们必须告诉算法我们想要什么样的颜色
=== Trandiational Colorization
- 传统方法主要有两类
  + Sample-based colorization: use sample image. 告诉算法大致用样本图像那样的颜色
  + Interactive colorization: paint brush interactively. 交互式地告诉算法我们想要的颜色
- Sample-based colorization
  #fig("/public/assets/Courses/CV/2024-12-08-12-48-13.png",width: 50%)
  - source image 就称为样本图像。我们想要把样本图像的颜色迁移到中间的 target image 上
  - 做法就是 “分割 + 匹配”
    - 对于每一个像素，在样本图像中找到最佳的匹配点（亮度和梯度）。然后根据匹配点填充像素值
    - 利用分割来匹配，草地的像素到草地去找，天空的像素到天空去找
- Interactive colorization
  #fig("/public/assets/Courses/CV/2024-12-08-12-50-49.png",width: 50%)
  - 该方法是让用户在每个区域给定颜色，算法将该区域的颜色补全（扩散）
  - 依然可以用*分割的方法*去做，然后还要考虑颜色的平滑性
    - 但分割其实不是一件容易的事，即使是当下最先进的分割算法，也没法给出很高精度的分割结果
  - 我们使用*优化的方法*求解
    - 老套路，找一个约束：对两个 adjacent pixels，如果 brightness 类似，那么颜色也应该类似
      - 通过这种方式，同时考虑了分割和平滑两件事
    - 然后最小化下列目标函数
      $ J(U) = sum_r (U(r) - sum_(s in N(r)) w_(r s) U(s)) $
      - $U(r), U(s)$ 是像素 $r, s$ 的颜色
      - $N(r)$ 是像素 $r$ 的邻居
      - $w_(r s)$ 是权重，表示 $r, s$ 之间的相似性。一般用梯度衡量，即灰度值的差异，公式为 $e$ 的负什么什么东西
    - Constraint: User-specified colors of brushed pixels keep unchanged
- 图像的 colorization 可以自然扩展到视频
  - 不只局限于把视频理解成一系列图像，一般也会把视频帧前后信息的相关度考虑进去

=== Modern Colorization (Deep Learning)
- 下面来看 modern approaches
- FCN (CNN-based methods)
  - 简单粗暴地使用全卷积神经网络，优化
    $ L(Th) = norm(F(X;Th)- Y)^2 $
  - 训练数据哪来？很丰富，因为把 RGB 转成 gray 很容易，而 2D 图像数据有茫茫多
  - 这个 loss 的问题
    + 没法解决 multiple solutions 的问题（根本没有建模这种情况，导致只会解出网络见过的解）
    + 没法衡量图像的真实性
- Generative Adversarial Network(GAN)
  - 对于生成式问题，采用传统神经网络的固定损失函数是不合理的。因为对于一个灰度图进行上色，解不是唯一的
  - GAN 并不自己定义损失函数，而又借助了一个神经网络来判断第一个网络生成的图片的质量
    #fig("/public/assets/Courses/CV/2024-12-08-13-22-50.png",width: 50%)
    - Discriminator $D$ 可以被看作是用来训练 $G$ 的损失函数，这被称为 *adversarial loss*
    - 它是 learnable 的而不是 hand-designed 的，并且训练好的 $D$ 可以被应用到很多 image synthesis tasks 上
  - 两个神经网络分别为生成器 $G$ 和判别器 $D$
  - $D$ 的 loss, tries to identify the fakes
    $ argmax_D E_(x,y) [log D(G(x)) + log (1 - D(y))] $
    #fig("/public/assets/Courses/CV/2024-12-08-13-21-35.png",width: 40%)
  - $G$ 的 loss, tries to synthesize fake images that fool $D$
    $ argmin_G E_(x,y) [log D(G(x)) + log (1 - D(y))] $
    - 同样的损失函数，但 $G$ 的目标是最小化 fake 的概率
  - 同时训练的方法: $G$ tries to synthesize fake images that *fool* the *best* $D$
    $ argmin_G max_D E_(x,y) [log D(G(x)) + log (1 - D(y))] $
  - 训练 GAN 最大的困难就是难以收敛，核心在于调整二者的平衡
  - 另外在 colorization 这一块，GAN 还有一个困难是没有用户输入
    - Real-Time User-Guided Image Colorization with Learned Deep Priors，这篇文章就是用 mask 的方式加一个用户输入

== More Image Synthesis Tasks
- 以上任务其实都属于图像合成(Image Synthesis)的子类，下面我们介绍更多任务
- *Super-Resolution*
  - 最简单的肯定就是插值，但用神经网络去补一些东西效果会更好
  - Photo-Realistic Single Image Super-Resolution Using a Generative Adversarial Network. CVPR 2017
    - 也是用 GAN 来做
    #fig("/public/assets/Courses/CV/2024-12-08-13-31-08.png",width: 50%)
- *Image to Image Translation*
  #fig("/public/assets/Courses/CV/2024-12-08-13-33-14.png",width: 50%)
  - 这里分出去子类就更多了
    + Labels to street scene
    + Sketch to photo
    + Aerial photo to map
    + Style transfer
    + text-to-image
    + image dehazing 图像去雾
    + ...
- *Pose and garment transfer*
  - 跟人相关，姿态和服装的迁移
  - 传统方法
    + Use *parametric mesh*(SMPL) to represent body pose and shape
    + Use high-dimensional *UV texture map* to encode appearance
    + Transfer the pose and appearance, then render the image
    + And complement the (incomplete) texture map with CNN .etc
- *Head Re-enactment*
  - 也是跟人相关，人脸的迁移
  - 基本逻辑跟人体是差不多的，但是精度和复杂度更高(pose, expression, identify, lighting...)
  - 基于此会有 voice deepfake 等应用
- *AI generated contents (AIGC)*
  - 以前的很多工作其实也算 AIGC，但真正让这个概念火起来的是 Difussion Models
    - PS: Difussion Models 的重要程度真的远超我之前的理解

