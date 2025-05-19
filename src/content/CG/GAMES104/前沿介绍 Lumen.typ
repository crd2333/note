#metadata(
  (
    order: 10,
  )
)<frontmatter>

#import "/src/components/TypstTemplate/lib.typ": *

#show: project.with(
  title: "GAMES104 笔记",
  lang: "zh",
)

- #link("https://games104.boomingtech.com/sc/course-list/")[GAMES104] 可以参考这些笔记
  + #link("https://www.zhihu.com/column/c_1571694550028025856")[知乎专栏]
  + #link("https://www.zhihu.com/people/ban-tang-96-14/posts")[知乎专栏二号]
  + #link("https://blog.csdn.net/yx314636922?type=blog")[CSDN 博客]（这个写得比较详细）
- 这门课更多是告诉你有这么些东西，但对具体的定义、设计不会展开讲（广但是浅，这也是游戏引擎方向的特点之一）
- 感想：做游戏引擎真的像是模拟上帝，上帝是一个数学家，用无敌的算力模拟一切。或许我们的世界也是个引擎？（笑
- [ ] TODO: 有时间把课程中的 QA（课后、课前）也整理一下

#let QA(..args) = note(caption: [QA], ..args)
#counter(heading).update(20)

= 动态全局光照和 Lumen
先讲了一堆 GI 的内容，这部分可以转战 Games202（具体笔记补充在那边）。

Lumen 是 UE5 的一个动态全局光照系统，真的是非常伟大的工作。对搞引擎的人来讲，把一个如此复杂的系统整合在一起，并成为一整个游戏系统的核心 feature，其难度是非常大的。

- 三句话讲 Lumen
  + Ray Traces are slow! 虽然硬件在不断发展（近年来越发趋缓)，但 ray trace 的速度依然是个问题，尤其是在非 N 卡上，往往只能达到 $approx 1$ spp，而 GI 需要上百。Lumen 希望能达到任意硬件下的 fast ray tracing（当然如果硬件支持也可以去调用）
  + Sampling is hard! 虽然 temporal / spacial 的 filtering 技术不断发展，但效果依旧有限
  + Low-res filtered scene space probes lit full pixels: 不逐像素做间接光采样，使用紧贴表面的稀疏探针做采样，然后插值获得像素的间接光照，再结合屏幕空间光追补充一些高频细节
- 话虽如此，Lumen 的复杂度不是短短三句话能概括的，且很容易陷入具体算法而看不清整体结构，这里把 Lumen 分为四个阶段
  + Fast Ray Trace in Any Hardware
  + Radiance Injection and Caching
  + Build a lot of Probes with Different Kinds
  + Shading Full Pixels with Screen Space Probes

== Phase 1: Fast Ray Trace in Any Hardware
- Signed Distance Field (SDF)
  - SDF 基础就不赘述，这里表达一个思想：SDF 很有可能成为现代渲染引擎的基础数学表达
  - SDF 构成空间形体的对偶表达，有时候对偶的函数呈现的会更加清晰，而且展现出很多更好的数学属性；并且 SDF 是连续的表达，更进一步它是可微的（神经网络嗅着味就来了x）；另外，SDF 的导数就是法向
  - 反观传统的 mesh，它不仅点是离散的，三角形面之间也没有关系（irregular，需要手动用 index buffer 关联），很多时候还需要做 adjacency information 冗余信息才能进行各种几何处理
- Ray / Cone Tracing with SDF
  - 参考 GAMES202: SDF for ray marching $->$ safe distance; SDF for cone tracing $->$ safe angle
- Per Mesh SDF
  - 对每个 mesh 做局部的 SDF 来存储，多个 instance 可以复用，进而合成整个场景
    - 合成涉及到大量数学变换（如果 scale 变换是等比的会相对简单一些），这里不展开
  - 由于后面会对场景进行点采样，对于特别细的 mesh，若小于场景最小 voxel 之间的距离，需要进行 expand（可能导致 over occlusion，但起码比 light leaking 好）
  - Sparse Mesh SDF: 把 SDF 分成 bricks，绝对值大于某个阈值时就不存储，虽然 ray marching 的步子没法那么大了，但能节省存储
  - Mesh SDF LoD: SDF 是 uniform 的，很容易做 LoD，这里做三层 mip
  #grid(
    columns: (24%, 38%, 38%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-18-52-08.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-18-47-25.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-00-03.png")
  )
- Global SDF
  - 合成为整个场景的低精度 SDF 表达（两个难点，一是数学上如何变换，二是如何更新）
  - 因为是 uniform 表达，所以很容易做成 clipmap，如图所示，每个小格子图上看起来差不多大，但实际上越远代表越大的空间
  - 通过 global SDF 快速找到粗略交点，再根据周边的 per mesh SDF 精细化，能够不依赖于硬件 Ray Tracing 的情况下比传统 AABB, Ray interact with Triangle 求交快得多

== Phase 2: Radiance Injection and Caching
当我们从光的视角照亮整个世界，其实无论从相机角度能否看见，都有可能对最终的屏幕像素产生影响，都是 GI 的贡献者。因此 GI 一般需要做光照的注入（photon mapping 的思想，光子如何固化场景中），如通过 RSM, Probes, Volume 等。RSM 只能做一次 bouncing，而各种 Probes 采集、Volume 传播的方法则五花八门。Lumen 则是采取了一个比较耳目一新的做法 —— Mesh Cards。

- *Mesh Cards*
  - Pass 1: 以 AABB 的方式存储每个 instance 从 $6$ 个方向看去的快照
    - 根据相机距离做 LoD，分配 mesh card 的精度
  - Pass 2: 整合到整个场景的 *Surface Cache* 里，并且做纹理压缩
    - 总共大小固定为 $4096 times 4096$，再细分为 $128 times 128$ 的 pages，随着相机移动需要 swap in/out
  #grid(
    columns: (23%, 52%, 25%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-19-35-48.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-24-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-30-48.png")
  )
- *Voxelization*
  - 对场景建立 SDF 表达 (per-mesh, global)，再建立 mesh card 表达还不够，还要再做 voxelization (clipmap)。Voxelization 表达可以用作时序上 GI 注入的媒介，也可以为直接光照时远处的物体提供光照值（适配 Global SDF）
  - 构建 $4$ level clipmaps of $64 times 64 times 64$ voxels，存储 $6$ 个面的 radiance，存到 3D texture 中
  - Voxel Visibility Buffer
    - 不是直接存储 radiance，而是存储每个 Voxel 在每个方向上 SDF trace 到的信息，存在所谓 Voxel Visibility Buffer 中
    - 与我们熟知的 V-Buffer 不同，它存储的是 Hit Object ID 以及归一化的 Hit Distance，这样后续 Inject Lighting 时就能快速找到对应的 surface cache 进行采样
  - Short Ray Cast 构建
    - 对 clipmap 再划分为 $16 times 16 times 16$ 个 tile（每个包含 $$4 times 4 times 4$$ 个 voxel），一个 wavefront/warp 处理一个 tile，tile 内从每个 voxel 边上随机采样一条（或多条）ray，每一条 ray 创建一个 thread 对一个 Mesh SDF 求交，结果只取求交距离最短的 hit
    - 每个 tile 包含的物体不会太多，因此每根 ray 只会与极少量 mesh 求交，而且是通过 SDF 进行，运算效率非常高
  - Clipmap 的更新
    - 更新 radiance 以及 voxel visibility buffer
    - 跟 VXGI 一样，只需要更新少量“脏”的 voxel 即可（而且每帧只会更新一个 level），具体而言是用 Scrolling Visibility Buffer 方法
    #tbl(
      columns: 5,
      [Clipmap update frequency rules], [Clipmap0], [Clipmap1], [Clipmap2], [Clipmap3],
      [Start_Frame], [0], [1], [3], [7],
      [Update_interval], [2], [4], [8], [8],
    )
  - 这个 Voxel Lighiting 模块跟后面要讲的 Screen Probe 很容易混淆，可以简单区分为：前者是存储我被照的有多亮，且每个面只存一个亮度；而后者负责照亮其它物体，存储的是光场分布
  - 从更 high level 的角度思考，Lumen 又搞 mesh car 又搞 voxel lighting，看起来很复杂，但借此构建了 uniform, regular 的表达，使得无论是积分、卷积、采样都会变得更简单
  #q[注：不过悲惨的是，这个 Voxel Lighting 的模块似乎在 UE5.1 被砍了。。。]
  #grid(
    columns: (18%, 60%, 22%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-20-21-47-16.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-19-56-16.png"),
    fig("/public/assets/CG/GAMES104/2025-04-20-22-13-52.png"),
  )
- *“Freeze” lighting on Surface Cache*
  - 光源打出光在场景中如何 multi-bounce？最终如何将 radiance 留在 surface cache 中？又如何考虑每个 pixel 是否在阴影中？
  - #strike[把大象装进冰箱] 把光照固化分为三步
    + 计算 Surface Cache 的直接光照
    + 假设已经有了 final lighting，把 final lighting 转化到 voxelization 中
    + 这样可以把上一帧 Voxelization 表达的全局光照视作这一帧的间接光照，和第一步的直接光照加在一起
      - 这种每次只算一次 bouncing，但随着时间积累变成多次 bouncing 的做法，跟 DDGI 如出一辙
  + Direct Lighting
    - 从每个光源用 SDF Ray Tracing 快速得到 shadow map，以此计算直接光照并相加
    - Tile-Based Rendering: 把 $128 times 128$ 的 page 再细分为 $8 times 8$ 个 tile，每个 tile 选取前 $8$ 个影响它的光源（控制复杂度）
    - 对于比较近的物体，用 Per-Mesh SDF Ray Tracing 方法即可找到 Surface Cache 进行更新；对于较远物体，得用 global SDF 不然太慢，但 global SDF 没法给出 per mesh information，只有 hit position, normal，但可以从 voxel lighting 中获取一个亮度
  + Inject Lighting into Clipmap
    - 每个 voxel 根据 hit information 知道从 Surface Cache 的哪个位置采样上一帧的 final lighting，得到一个 radiance
  + Indirect Lighting
    - 从 voxel 表达传递光照信息到 surface cache 中，首先将 surface cache 划分为 $8 times 8$ tile，放置 $2 times 2$ probes，每个 probe 在半球上采样 $16$ 条 ray
      - $16$ 正好就是每个 probe 覆盖的 $4 times 4$ texels，另外还需要对 probe placement, ray directions 做 Jitter
    - 对 probe radiance altas 做 spacial filtering，插值采用转化为 SH 的方式
  - 随后将光照组合即可，同时也顺带解决了 emissive 物体的问题
  #fig("/public/assets/CG/GAMES104/2025-04-20-22-57-13.png")
  - Surface Cache 的光照更新也会有一个 budget，$1024 times 1024$ for direct lighting, $512 times 512$ for indirect lighting，且根据优先级选择 priority
    - Priority = LastUsed - LastUpdated，通过 bucket sort 维护 priority queue
- 还有很多复杂的细节没有展开讲，比如
  + terrain 显然没法用 mesh card 表达
  + 场景中有半透明的 participate media 怎么办？
  + clipmap 具体怎么存、移动时怎么更新

== Phase 3: Build a lot of Probes with Different Kinds
虽然我们有了 Surface Cache / Voxel Lighting 的 radiance 表达，但它们还无法直接应用于屏幕像素的 shading。作为对 Render Equation 的求解，我们需要得到每个像素在半球面各个方向的 radiance，一般来说会用 probe 来做。

probe 的放置是个讲究活，最自然的想法就是在空间中均匀洒 probe，从 surface cache, voxel lighting 中采样光照。但一般来说这样的表达没法跟场景的精细几何相匹配（哪怕做了近大远小的 clipmap 也是一样），会“看上去很平”，这是预先生成的 distribution 共有的问题。而 Lumen 则很大胆，直接*在 screen space 中做 probe*。

- *Screen Probe* 可以分为 $5$ 步流程
  + 确定 screen probe 在屏幕空间的位置
  + 每个 probe 以生成位置为中心向外发射射线去获得颜色
  + 获取到颜色后先在 probe 与 probe 之间做时序滤波和空间滤波，再通过球面谐波函数压缩成 SH 存储
  + 根据最终得到的 probe 信息去插值出每个 pixel 的颜色
  + 再整个屏幕空间做时序滤波
  - 这里 Phase 3 我们仅会涉及前两步
- *Screen Probe Placement*
  - Uniform Placement
    - 屏幕空间最粗暴的做法自然是为每个 pixel 做一个 probe 收集光照，但过于粗暴而无法接受
    - 鉴于 indirect light 的低频性，Lumen 默认每 $16 times 16$ 个 pixel 一个 Screen Probe，贴着物体表面放置
  - Adaptive Placement
    - 对于高频细节（几何差异较大的表面）使用 Hierarchical Refinement 来自适应地放置更高分辨率的 Uniform Probes
    - 先放置覆盖 $16 times 16$ 像素的 probe，如果存在插值失败的像素则自适应地放 $8 times 8$ 像素 probe，还失败再放 $4 times 4$ 像素 probe
      - 插值失败与否通过 plane distance weight 判断，每个 pixel 及其法向定义一个平面，采样点到平面的距离决定权重，低于阈值则需要细分
      - 这种先粗后细、自适应划分的思路非常值得学习，回忆 RSM 降采样并在几何变化剧烈区域重采样的做法，已经暗含这个思想
      - 如下图所示，暗红色为原始分辨率 probe，黄色为细分的 probe（$8 times 8$ / $4 times 4$，发生在几何变化较大的地方）
    - 新生成 probe 的 depth, normal 等信息写在和 uniform probe 同一张 texture 上（利用方形纹理的边角料区域）
  - Jitter
    - 基于时序超分思想，每一帧生成的 probe 都会有不同的 placement, direction 的抖动
    - 在同等分辨率（间距）的 probe 下近似得到更小间距 probe 的效果，结果更平滑
    #grid(
      columns: (30%, 65%),
      column-gutter: 2em,
      fig("/public/assets/CG/GAMES104/2025-04-21-21-53-10.png"),
      [
        #fig("/public/assets/CG/GAMES104/2025-04-21-22-15-33.png")
      ]
    )
    #fig("/public/assets/CG/GAMES104/2025-04-21-22-15-13.png", width: 80%)
- *Screen Probe Ray Tracing*
  - 每个 probe 的光照信息存储在 $8 times 8$ 的空间内，记录 radiance 和 hit distance，其方向在 world space directions 中均匀采样，通过 Octahedron mapping 存储（同 DDGI）
  - 每个 probe 只发射 $64$ 根射线 (fixed budget)，但为了加速收敛速度需要做*重要性采样*
  - 换句话说，分布方向均匀但采样方向不均匀，初学时极易混淆。怎么理解呢？后面会为每个 pixel 算出 pdf，以 $4$ 个为一组，如果每组最大的 pdf 小于某个阈值，就能减少发射次数。但完全不发射也是不对的，所以用 mipmap 方式四合一，在降一级的 mipmap 上发射一根光线，多出来的 $3$ 次机会让给其它 pixel with large pdf 用以细化，在升一级的 mipmap 上发射 $4$ 根光线（但仍存成一格）
  #grid(
    columns: (54%, 46%),
    fig("/public/assets/CG/GAMES104/2025-04-21-00-02-20.png"),
    [
      #fig("/public/assets/CG/GAMES104/2025-04-21-23-21-01.png")
      #fig("/public/assets/CG/GAMES104/2025-04-22-10-58-11.png")
    ]
  )
- *Importance Sampling*
  #grid(
    columns: (70%, 30%),
    column-gutter: 4pt,
    [
      - 重要性采样的目的是使得分母的 $P_k$ 分布尽可能跟分子的分布相似，Lumen 采用了将分子拆开来分别做重要性采样而后卷积的 hack。虽然把方程强行拆开，但仍能大幅加快收敛速度
      $ lim_(N -> infty) 1/N sum_(k=1)^N frac(ybox(fill: #true, L_i (I)) rbox(fill: #true, f_s (I->v) cos(th_I)), P_k) $
    ],
    fig("/public/assets/CG/GAMES104/2025-04-21-23-37-43.png")
  )
  - *BRDF 重要性采样*
    - BRDF 和 normal 共同决定了光照信息在哪些方向收集更有效，Lumen 计算间接光的过程不考虑材质信息，BRDF 默认为常数 $1$，问题归结于 normal 的分布
    - 最直接的想法是找到 screen probe 所在材质的 normal，沿着该方向做 cosine lobe，但这其实并不合理，因为一个 probe 包含 $16 times 16$ 个 pixel，可能覆盖从远到近几何变化剧烈的多个物体，法向变化非常高频
    - 为此我们在采样中再套一层采样，如右上图所示，每个 probe 在 $32 times 32$ 区域内采样 $64$ 次附近 pixel，通过深度、法向判断是否共面 (plane distance)，若有效则把 normal 转化为 SH，最后求均值
  - *Lighting 重要性采样*
    #grid(
      columns: (90%, 10%),
      column-gutter: 2em,
      [
        - 这部分要解决的就是光源位置问题，比如室内场景最头疼的问题就是窗户在哪（光照从户外以窗户为次级光源传入）
        - Lumen 采样时序上信息继承的做法，通过上一帧的光照信息得知哪里相对亮
        - 具体而言
          + 根据相机变化和当前帧 probe 的深度、位置以及 jitter 偏移重建出上一帧 probe 的深度、位置
          + Spatial Filtering: 与附近的 neighbor probes 计算权重与插值
            - $3 times 3$ kernel 覆盖 $48 times 48$ pixels
            - Lumen 忽略了 normal 而只考虑 depth weight
          + Gather Radiance from neighbors: 找到 probe 对应的颜色乘以权重再累加得到最后的 radiance
            - 需要考虑两种 error
              + Angle error: 角度偏差过大不可接受，否则会导致 local shadowing
              + Hit distance error: hit 距离差距过大不可接受，否则会导致 lighting leaking
            - #bluet[蓝]：neighbor ray，#greent[绿]：自身打出去的 ray，跟 neighbor ray 相近可接受，#redt[红]：自身打出去的 ray，不可接受
          + 如果 neighbor probes 被遮挡则考虑 world space probes（后面细讲）
        #grid(
          columns: (50%, 50%),
          column-gutter: 4pt,
          fig("/public/assets/CG/GAMES104/2025-04-21-23-29-03.png", width: 90%),
          fig("/public/assets/CG/GAMES104/2025-04-21-23-29-14.png", width: 90%)
        )
      ],
      fig("/public/assets/CG/GAMES104/2025-04-22-12-04-56.png")
    )
- *World Space Probes and Ray Connecting*
  - 虽然已经有 Screen Space Probes (SSP)，为什么还要有 World Space Probes (WSP) 呢？
    + 对于需要采样较远的 case， ray tracing 的效率下降
    + 距离增长后小而亮的特征带来的 noise 也会增大
    + 这种 distant lighting 变化比较缓慢，提供了 cache 的机会（尤其是对静态场景，与之对比，SSP 每帧都要变化）
  - 为此在 world space 以 clipmap 的方式放置 probes，存储各个方向的 radiance（比 screen space 更密，确保各个方向都能 handle），这样 SSP 的采样不用跑很远，就能借 WSP 的光
  - 哪些 WSP 需要更新？
    + 首先，像 VXGI 那样，每帧随相机移动时只有边缘部分需要更新
    + 其次，对于所有 WSPs，只有场景变化、光源变化时才有更新需求
    + 最后，如果一片空间内没有物体、不在 screen space 下的 WSP 没有必要采样（包裹了 SSP 的 WSP 会被标记为 marked，只有 markded 的 WSP 才有采样需求）
  #fig("/public/assets/CG/GAMES104/2025-04-21-23-51-40.png", width: 90%)
  - Ray Connecting
    - 每个 SSP 被 WSP 的 voxel 包裹，只会采样对角线距离的两倍之内 (interpolation footprint + skipped distance) 的光照，一旦出了这个距离就选择借 WSP 的光
    - 同样 WSP 也只会采样对角线距离之外 (beyond interpolation footprint) 的光照，避免重复采样
    - 显然，这个 footprint 的大小跟 WSP 所处的 clipmap level 有关，也就是 SSP 借光行为的阈值距离是自适应而非写死的
  - Artifact
    - 借光时跳过遮挡物，进而导致 light leaking
    - 解决方法是 “对光线施加偏转”，SSP ray 与 footprint 的交点与要从它身上借光的 WSP 连线得到一个新的角度，使用这个偏转了一定角度的光照 (hack)
  #fig("/public/assets/CG/GAMES104/2025-04-22-10-12-40.png", width: 90%)
- How to do ray tracing
  - 以上说了那么多，实际上还没有涉及 ray tracing 到底怎么做，包括 screen space, world space（这里 GAMES104 没有详细讨论）
  - Screen Space Ray Tracing
    - 主要使用 SSGI 的方法 (SSR)，还涉及 temporal 信息的利用
  - World Space Ray Tracing
    - Lumen 作为一个算法体系，混合了多种 trace 方法
      - 左图表示每个区域所使用的 trace 方法，右图是各种 trace 方法的优先级（优先使用限制大但准确的方法）
      #grid(
        columns: (57%, 43%),
        column-gutter: 4pt,
        fig("/public/assets/CG/GAMES104/2025-04-22-22-37-34.png"),
        fig("/public/assets/CG/GAMES104/2025-04-22-22-37-22.png")
      )

== Phase 4: Shading Full Pixels with Screen Space Probes
以上我们做了那么多工作 (mesh card, voxel lighting, world space probes)，一切的根本目的都是为了产生表达足够有效的、紧贴表面的 screen space probes。

- 回忆之前说 Screen Probe 可以分为 $5$ 步流程
  + 确定 screen probe 在屏幕空间的位置
  + 每个 probe 以生成位置为中心向外发射射线去获得颜色
  + 获取到颜色后先在 probe 与 probe 之间做时序滤波和空间滤波，再通过球面谐波函数压缩成 SH 存储
  + 根据最终得到的 probe 信息去插值出每个 pixel 的颜色
  + 再整个屏幕空间做时序滤波
  - 前两步已经完成，现在只剩最后三步！当然到了这里实际上已经比较简单了，课程在此几乎一笔带过
- *Convert to SH*
  - 虽然我们做了 Important Sampling，但实际上 Indirect Lighting 还是很不稳定
  - 把这些光投影到 SH 上面去，SH 本身便起到低通滤波的作用，用它来做 shading 看上去就柔和许多

== Overall, Performance and Result
- 不同 Tracing Methods 的对比 (Cost v.s. Accuracy)
  - HZB: Hi-Z Buffer, HW: Hardware Ray Tracing
  #fig("/public/assets/CG/GAMES104/2025-04-22-22-35-55.png", width: 50%)

Lumen 受限于硬件做了很多妥协，未来十年随着硬件发展，real-time GI 会变得更加成熟也可能更加简洁。但不管如何，Lumen 作为如此复杂的算法体系，算是把 GI 做到实时、泛用的真正开山鼻祖，奠定了未来十年游戏引擎渲染的标杆与基础，是这一系列伟大征程的开端。

#QA([在硬件光追飞速发展的今天，Lumen 仍然开发了距离场和软件光追，那么对于当下的引擎开发来说，是否距离场和软件光追也是必须的？], [一方面，随着硬件发展触及摩尔定律的瓶颈，未来几年的硬件性能可能让 SSP 能翻一个数量级，但对 GI 来说其实没有本质改变，所以 Lumen 所使用的 SDF 和软件光追算法是非常有意义的；另一方面，Lumen 自己也在利用硬件光追的发展，在硬件支持的情况下能否利用其简化部分计算。总之对这个问题老师持 Open-minded 态度。])
