#metadata(
  (
    order: 11,
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
#counter(heading).update(21)

= GPU 驱动的几何管线 Nanite
先讲了一堆 GPU-Driven Rendering Pipeline 的内容，这部分放到之前渲染 part 中的渲染管线处。这里着重记《刺客信条大革命》和 Nanite 的做法。

== GPU Driven Pipeline in Assassins Creed
《刺客信条大革命》着眼于城市环境，有着大量的 architecture, seamless interiors, crowds... 这样繁多且精细的几何，在传统 Pipeline 里只能全部 load 起来，一个个 instance 地绘制（只能做一些基本、低效的 culling），很显然会有巨量 overdraw，问题的核心就在于如何高效地实现各种 culling。

- *Mesh Cluster Rendering*
  - 《刺客信条大革命》是最早的 cluster-based rendering 实践，其思想非常简单，把完整的 instance 划分为多个 cluster，从而允许用它们各自的 bounding 做更细粒度的 culling (usually by compute shader)。其最大的好处在于，避免了仅仅看到一个角就要把整个精细的 instance 都 load, draw 的 case
  - 这需要
    + 固定的 cluster 拓扑结构 (e.g. $64$ triangles in Assassin Creed / $128$ triangles in Nanite)
    + split & rearrange meshes 来满足固定的拓扑结构（可能需要插入一些 degenerate triangle）
    + 在 vertex shader 中手动 fetch vertices
- *GPU-Driven Pipeline*
  - Overview
    - CPU 端做一些简单的 culling，GPU 端做通过更复杂的 culling 筛选出可见的 instance 的可见的 cluster 的可见的 triangles
    - 最后全部 packing 成一个超大的 index buffer，从而可以通过 single-/multi- indirect draw 来达到 draw scene 的效果
    - 这种做各类细化 culling 后把结果打到一个大 buffer 中，随后发出 indirect draw call 的做法，初看之下会很费，但逐渐变成下一代 rendering pipeline 的标准解法之一
  #grid(
    columns: (55%, 44%),
    column-gutter: 4pt,
    [
      + Works on CPU side
        - 执行 coarse view-dependent frustum culling / quad tree culling
          - 具体做法可以参考 #link("https://www.pinwheelstud.io/post/frustum-culling-in-unity-csharp")[Unity frustum culling - How to do it in multi-threaded C\# with Jobs System], #link("https://www.pinwheelstud.io/post/how-to-do-cell-based-culling-using-quadtree-in-unity-c-part-1")[How to do cell based culling using quadtree in Unity C\# - Part 1]
        - 合并 drawcalls for non-instanced data (e.g. material, renderstate, ... persistent for static instances)，然后更新 per instance data (e.g. transform, LOD factor, ...)
          - 这里可以看到，Assassin Creed 的 LoD 还是基于传统方法，这跟后面的 Nanite 有本质不同
    ],
    fig("/public/assets/CG/GAMES104/2025-04-23-23-43-54.png"),
  )
  #grid(
    columns: (31%, 30.7%, 38.3%),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-05-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-03.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-26.png")
  )
  #grid(
    columns: (31.5%, 34.25%, 34.25%),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-06-42.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-07-02.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-22-07-24.png")
  )
  2. GPU Initial State
    - instance stream 包含了 GPU-buffer 中 per instance 的数据，比如 transform / instance bounds 等
  + GPU Instance Culling
    - GPU 做 instance 的 frustum culling / occlusion culling，后者单开一 part 细讲
  + Cluster Chunk Expansion
    - 把所有的 instances 细分为 clusters，但又 $64$ 个为一组合成 chunks。原因是每个 instance 展开的 cluster 数量方差太大 $(1 \~ 1000)$，直接展开会造成 wavefront / warp 计算资源不均，而这样组合之后能一次性发出一批工作
    - 这跟后面 Nanite 把 cluster 合成 group 的思路有异曲同工之妙
  + GPU Cluster Culling
    - 使用 instance 的 transform 和每个 cluster 的 bounding box 做 frustum / occlusion culling
    - backface culling by codec triangle visibility in cube
      - 每个 cluster 有 $64$ 个 triangle，用 $6 times 64$ 个 bit 来表达每个 triangle 在 $6$ 个方向上的可见性（预烘焙 cluster 的朝向 mask）
    - 通过 culling 的 cluster 会导出 index compact job，其中包含 triangle mask 和 r/w offsets，这些 offset 根据关联的 instance primitive 使用 atomic 操作生成
  + Index Buffer Compaction
    - 预先准备一个大的 Index buffer $(8MB)$，并行地把 visible triangles index 复制到其中（依赖 compute shader 并行但原子的 append 操作）
    - 一次场景渲染可能没法完全存进一个 buffer，所以 Index Buffer Compaction (ExcuteIndirect) 和 Multi-Draw (DrawIndexInstancedIndirect) 是交替进行的
    - 小细节：每个 wavefront 处理一个 cluster，每个线程处理一个三角形，它们之间相互独立。根据之前传递的 triangle mask 和 i/o offsets，每个线程计算输出正确的写入位置，锁死绘制顺序 (deterministic)，防止因为 Z-Buffer 的精度问题导致 Z-Fighting
  + Multi-Draw
    - 最后每个 batch 一个 multi-draw，渲染数据
- *Occlusion Culling for Camera*
  - 主相机的遮挡剔除，其思想是在 Pre-Z Pass 尽可能以低的成本生成 Hi-Z Buffer
  - 《刺客信条大革命》的 GPU-Driven Rendering Pipelines 论文里的做法
    + 一方面，利用美术标记启发式算法找到那些又大离相机又近的 $300$ 个 occluder，downsample 到 $512 times 256$ 的分辨率上。但会有一些选择错误 (large moving objects) 或未通过 alpha-test 的 occluder 需要被 reject，产生 holes
    + 另一方面，借用时序信息，把上一帧的 (Hi-)Z Buffer reproject 到当前帧。但是当相机移动速度过快，也会产生 holes
    - 两种方法结合起来，互相补洞，达到比较好的效果，当然极端情况也会出问题
  - 后来又有另外一个被育碧收购的团队提出了 Two-Phase Occlusion Culling 的改进
    + $first$ phase: 使用上一帧的 Hi-Z 对当前帧的 objects & clusters 做 cull，得到保守但已经筛掉很多的估计
    + $second$ phase: 用生成新的 Hi-Z 再去测一遍 $first$ phase 中当前帧没有通过的 objects & clusters，一些新的物体又可见了
    - 第一阶段的结果可能会产生很多 holes，在第二阶段一定会被填上（因此能确保结果是正确的，大不了少剔除一些）
  #grid(
    columns: (35%, 65%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-25-12-17-04.png", width: 80%),
    fig("/public/assets/CG/GAMES104/2025-04-25-12-18-59.png", width: 80%)
  )
- *Occlusion Culling for Shadow*
  - 游戏中 shadow map 的渲染往往能占到近五分之一的时间开销
    + 它只和几何复杂度有关，意味着材质上的简化对其没有任何效果
    + shadow map 的精度需要跟主视角下几何精度一致（往往通过 cascaded 达成），否则会出现各种 artifacts
    + cascaded shadow map 的覆盖范围可能是方圆几平方公里的整个场景，如果不做任何优化非常要命
  - 为此 shadow map 也需要做 culling，其基本思想跟 camera culling 一致，同样可以针对光源的移动、场景的移动复用时序信息剔除。但针对 shadow，如果利用上 camera 的深度信息可以避免更多 case
    - 毕竟本身 shadow map 就是在跟相机深度做比较，这也是很自然的思路。例如右上图中#redt[红色方块]，在光源视角下深度最浅，无论如何都不会被剔除，但因其在 camera 下不可见，也能被剔除
  - 基本思想是，对每个 cascade，产生 $64 times 64$ pixels 的 camera depth reprojection 信息，与上一帧的 shadow depth reprojection 信息相结合，再产生 Hi-Z Buffer 做 GPU Culling
  - Camera Depth Reprojection
    - 对相机深度如何重投影回光空间做个解释：将相机的深度图均分为等大的 tile ($16 times 16$ pixels)，每个 tile 选择最近的深度作为 $z$ 值，结合 tile 四角顶点的 $x, y$ 坐标得到相机空间下的四个顶点。每四个顶点跟在相机近平面的映射点相连，得到一个个 #yellowt[yellow cube / frustum]
    - 在 light view 下渲染这些锥体，记录其最远距离（图中的#greent[绿色块]），任何比它们还远的物体都被剔除
  - 这两部分的 culling (camera / shadow) 可以参考 #link("https://zhuanlan.zhihu.com/p/416731287")[Hierarchical Z-Buffer Occlusion Culling 到底该怎么做？]
- *Visibility Buffer*
  - 这部分的基础介绍放在之前的渲染管线 part

== Virtual Geometry - Nanite
Nanite 是 UE 跟 Lumen 并列的另一个重要技术，主要用于处理复杂的几何体。它的核心思想如标题所言就是 Virtual Geometry，把几何体的细节信息存储在一个虚拟的几何表示中，允许我们在渲染时动态地加载和卸载这些细节信息，从而实现高效的渲染。

我们的梦想是把 Geometry 做成跟 Virtual Texture 一样，在没有额外开销的情况下 (Poly count, Draw calls, Memory...) 使用任意精度的几何，达到 filmic quality 的效果。但现实是，Geometry 不仅仅是 virtual texture 那样的 memory management 问题，它的 detail 直接影响 rendering cost；另外，mesh 的表达是 irregular 且不连续的，不能像 texture 那样做 filtering。

=== Geometry Representation
- Choice of Geometry Representation
  - *Voxel*
    - Spatially uniform 的表达，但想要达到高精度对存储要求非常高（即使用 octree 优化），而且一旦上了 octree 就会使得 filtering 变得复杂（丢了原本的优势）
    - 并且对 artist 工作管线的颠覆也限制了它的使用
  - *Subdivision Surface*
    - 硬件上猛推的技术，如 geometry shader, mesh shader 等，能够有效地产生精细的几何
    - 但在定义上，它只是 amplification，而不能化简；而且有时候会产生过多的 triangles
  - *Maps-based Method*
    - 诸如 displacement map 等的方法能够在 coarse mesh 上增加很多几何，尤其对于已经均匀采样过的 organic surfaces 表现良好，但难以表达 hard surface。另外，从一个已有的精细几何生成 displacement map 也还是需要一定运算的
    - 但这一块还是有一定 debate 的，NVIDIA 还是在猛推 Micro-Mesh 的做法，基于 GPU 自动（用 displacement map 等技术）把几何加密，还可以做 ray tracing。目前这仍然是一个还未决出胜负的领域
  - *Point Clouds*
    - 基于 splatting 的点云绘制方法可能还有大量 overdraw，如何 aplly uv texture 也是一个大问题。以及点云需要 hole filling
    - By the way，感觉这些也是现在 3DGS 方法的硬伤之一，以前我还对这方向挺有信心的来着（
  - 最终 Nanite 选择了 triangle 这一最成熟的表达方式

几何的划分可以无限增加，但我们希望最终绘制的三角形数量不要无限爆炸，而这是合理的，因为屏幕像素数有限。换句话说，我们希望用屏幕精度决定 geometry caching 的精度，这也是 Nanite 最核心的思想。

- *Nanite Triangle Cluster*
  - 与 Assassin's Creed 类似，Nanite 把 mesh 划分为 cluster，大小是 $128$ triangles
  - 不同点在于，Nanite 可以在每个 instance 内自适应地进行 view-dependent LoD 切换（而不是每个 instance 固定 LoD level），在相同的 view 下几乎只用 $1\/30$ 的开销就能达到每个 pixel 都有一个 triangle 的精度
  #grid(
    columns: (29%, 71%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-09-07.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-11-52.png")
  )
- *Naïve Solution - Cluster LoD Hierarchy*
  - 用一个树状结构建立 cluster hierarchy，每个 parent 是其 children 的简化版本。还可以跟 streaming 相结合，一开始只加载 core geometry，需要时加载更精细的 cluster (just like virtual texture)
  - 每次简化能算出 perceptual difference 或者叫 error，根据 error 选择 view dependent cut
  - 但是简化无法保证 water-tight，会形成 cracks。这类问题最基本的方案是 lock boundaries，但会导致锁住的边永远过于精细，不仅面片简化的效果不好 (number beyond $128$ within a cluster)，而且这种 frequency change 会导致 artifacts
  #grid(
    columns: (25%, 19%, 20%, 28%),
    column-gutter: 6pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-15-35.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-26.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-09.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-16-42.png")
  )
- *Nanite Solution - Cluster Group*
  - 将 cluster 组合成 group，例如 $16$ 个 cluster 为一组，以 group 为单位进行 LoD 切换（强制 group 内的所有 cluster 采用同个 LoD）。这样的好处在于粒度更粗，只会锁 group 的边，而 inner clusters 可以自由简化（换句话说，锁住的边占比减小了）
  - 而更大的好处在于，经过简化后的 group 可以打散之后重新 group，这样*新生成的 group 的 boundry 跟原来的 boundry 可以是错开的*，从而将锁边导致的局部过密影响分散开来（想想看，这是不是跟采样时加 jitter 的思路很像？）
  - 从图中也可以看到：
    + group 内简化一次后，又重新 split 为 $128$ (simplified) triangles，得到全新的 cluster 划分。而*这些 cluster 所对应的子节点并不由其父节点独享*，形成 DAG 结构 (not tree)
    + 当新 cluster 重新组合为 group 时，能够越过原来的 boundary，形成新的 boundary
    - 这样形成了乱中有序的结构，低层级到更高层级的连接可能是 multiple-to-multiple 的关系，但又只会跟简化后有关联的 cluster 进行连接 (localized)
  #grid(
    columns: (40%, 49%, 11.5%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-10-35-52.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-38-53.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-10-36-52.png")
  )
  - 以 Bunny 为例，这样的 DAG 划分与维护能够避免局部过密，形成非常自然的简化
    #grid(
      columns: (50%, 50%),
      column-gutter: 2em,
      fig("/public/assets/CG/GAMES104/2025-04-26-11-21-04.png"),
      fig("/public/assets/CG/GAMES104/2025-04-26-11-20-14.png")
    )

=== Runtime LoD Selection
通过以上的 cluster group 划分，最终会形成只有一个根节点的 tree-like DAG 结构，现在问题转化为如何在运行时选择 LoD。

每个 node 和其所对应的更细的 LoD level 代表 two submeshes with same boundary。选择的依据是 screen-space error，计算简化前后投影到屏幕上的 distance and angle distortion，DAG 中的每个 node 都会有一个 error 值。

- *LOD Selection in Parallel*
  - group 的划分已经比 cluster 更快，但在这样精细的结构下依然复杂。一个 group 内的所有 cluster 选取相同 LoD，如何实现这一点？直接 traverse 或依赖 communication 都会很慢，因此我们的想法是把整个 DAG 拍平成 array，对每个 cluster 孤立地、并行地处理 (*Isolated LoD Selection* for each cluster group)
    - 实际上是以 cluster group 为执行单位，但会对每个 cluster 分别做处理
  - error 的设计需要满足 deterministic (same input $=>$ same output)，否则仅仅只是因为并行提交的顺序不同就会导致 LoD 选择不一致，产生 Z-Fighting 等问题
    - 最基本的要求便是 error 必须是单调的 (monotonic): $"parent view error" >= "child view error"$
    - 需要仔细实现使得 runtime correction 也是单调的
    - 源自于 child level 中相同 cluster 的两个 cluster，即使分属于不同 group ，也要保证它们的 error 相同（如下图橘色和紫色节点）
  - 具体而言，每个节点只需要额外记录 $"parent view error"$，然后用这两个准则决定绘制 / 剔除
    ```
    Render: ParentError > threshold && ClusterError <= threshold
    Cull: ParentError <= threshold || ClusterError > threshold
    ```
    - 换句话说，我只决定自己需要需要绘制。若我被剔除，是否需要绘制子节点的决策与我无关（但因为 error 的设计最终一定会有子节点补上）
  #grid(
    columns: (45%, 54%),
    column-gutter: 8pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-15-16-00.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-15-21-06.png")
  )
- *BVH Acceleration*
  - 虽然拍平成 array 能有效提升并行度，但毕竟 cluster groups 还是太多，为此构建 BVH 结构进行加速（通过另外构建的 BVH 结构避免 array 中大量的无效遍历）。这一点在原作者的 presentation 中一笔带过，但实际上有将近 $20$ 倍的加速
  - 每个节点存储子节点 $"ParentError"$ 的最大值，internal node 存储 $4$ 个 children nodes（尽可能构建张度为 $4$ 的平衡树），leaf node 存储 cluster group 的 list
  #q[评论区：严格来说，BVH 中叶节点挂的也并不是 ClusterGroup，而是 Group 分成的Part，这里讲成 ClusterGroup 也更容易理解，Part 这种算是实现上的细节。切分的目的是为了 Page Streaming，如果有 ClusterGroup 跨页了就会切]
  - Hierarchical Culling & Persistent Threads
    - 原作者大谈特谈的 part，但感觉相比 BVH 构建本身只能算是实现上的 trick
    - 如果用传统 BVH 的遍历方法，每次 dispatch 把当前 level 扫一遍产生新的子节点，丢到下一次 dispatch 中去。但是 level 之间形成 Wait for idle 关系，且 level 较深的 dispatch 变为 empty，总之就是非常慢
    - 于是采用类似 job system 的方式，把 working threads 固定下来，用 multi-producer multi-consumer (MPMC) 的结构，任何时候产生的子节点直接 append 到 job-queue 的后方，而 threads 不断从前方 pop 任务执行（实际上是一个非常简单的数据结构，但依赖于 GPU compute shader 的发展，实现 shared pool, atomic lock）

=== Nanite Rasterization
Nanite 自定义了一套 rasterization 方法，来应对当几何精细到近乎等同于像素情况下新的挑战。

- *Nanite V-Buffer Layout*
  - Nanite 的 Visibility Buffer 为一张 `R32G32_UINT` 的贴图，人为把 depth 写在最高位（需要 `InterlockedMax` 操作确保原子性），手动实现 (software) Z-Test
  - 个人理解这里 Z-Test 的意思是说，并非单开一个 pass 做 Pre-Z pass，而是把它融入到了软光栅化器中
  #csvtbl(```
  32, 25, 7
  Depth, Visible cluster index, Triangle index
  ```)
- *Weakness of Hardware Rasterization —— Quad Overdraw*
  - Quad Overdraw 的问题来自 GPU 硬件的处理：GPU 以 $2 times 2$ 的最小粒度进行像素处理（以便能够通过 uv 计算出 mipmap 等级，i.e. `ddx`, `ddy`），即使只有其中一个像素需要着色，也要将整个 $2 times 2$ block 调度为活跃线程并执行片元着色
  - 在最坏情形下，$4$ 个像素分属于 $4$ 个三角形，Forward 为每个像素运行材质采样和光照计算 $4$ 次；Deferred 为每个像素运行材质采样 $4$ 次、光照计算 $1$ 次；而 Visibility 的材质采样和光照计算为每个像素均只运行 $1$ 次，因为可以在重计算 barycentrics (screen space) 时算出 mip-level。对于 Nanite，这种 “最坏” 情况非常普遍
  - V-Buffer 原论文并没有这一点，众多讲解 V-Buffer 的文章也没有提到，应该是后来才被发现的妙用？可以参考这篇博客 #link("http://filmicworlds.com/blog/visibility-buffer-rendering-with-material-graphs/")[Visibility Buffer Rendering with Material Graphs] 或者它的译文 #link("https://www.piccoloengine.com/topic/310642")[Nanite核心基础- Visibility Buffer Rendering（翻译）]
- *Weakness of Hardware Rasterization —— Scanline*
  - 回忆硬件光栅化，会采用 scanline 算法，逐行扫描将三角形细化为一个个像素（以及各个属性的插值），实际中还会把屏幕划分为 $4 times 4$ 的 tile 进行加速 (separate to $4 times 4$ micro tiles, output $2 times 2$ pixel quads)
  - 但是面对 Nanite 这种几何精细到近乎等同于像素的情况，基于扫描线算法的光栅化就变得非常低效，加上前面说的 Quad Overdraw 的问题就更费
  #grid(
    columns: (31%, 17%, 52%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-24-22-31-49.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-23-06-49.png"),
    fig("/public/assets/CG/GAMES104/2025-04-24-23-06-07.png")

  )
- *Software Rasterization*
    - 为此 Nanite 提出了自己的 Software Rasterization 方法，与 Hardware Rasterization 配合使用，右上图中，#bluet[蓝]为 SW、#redt[红]为 HW
    - Nanite 以 cluster 为粒度进行 software / hardware 的选择，由于 Nanite 知道 cluster 的边、面积等信息，可以算出所占 pixels 数量，当大于 $18$ 时采用硬件光栅化，否则采用软件光栅化。具体做法是，通过 compute shader 的通用计算能力，自行插值出每个像素的信息、重建 `ddx` `ddy` 信息、自行实现 Z-Test……
  - 当然 NVIDIA, AMD 看到这种趋势肯定会坐不住的，未来把这种操纵搬到硬件上原生支持几乎是板上钉钉 (NVIDIA Micro-Mesh?)
    - 这也体现出一种发展范式：软件灵活探索新的想法，之后硬件再进行固化

当然，Nanite 作为基于 visibility buffer 的实现，最后还是先渲染到 G-Buffer，跟传统 Deferred Rendering 结合。毕竟 Nanite 虽然精细，但还是有很多限制，比如不支持带有骨骼动画、材质中包含顶点变换或者 Mask 的模型（目前大部分 mesh 还是基于传统 pipeline 的）。

- *Imposters for Tiny Instances*
  - 传统 LoD 的经典做法，在现代高级几何管线中还是有实战用处（虽然也随时有可能被替换为更新的技术）。
  - 模糊方向量化，在 atlas 上存储 $12 times 12$ view directions，用 octahedral map 做映射
  - 每个方向使用 $12 times 12$ pixels 表达，同样使用 octahedral map 做映射，存储 $8 bit$ Depth, $8 bit$ TriangleID
  - 从 instance culling pass 直接画到 G-Buffer，不经过复杂的 Nanite 管线

- *Rasterizer Overdraw*
  - 不使用 per triangle culling，也不使用 hardware Hi-Z culling pixels
  - 使用基于上一帧的 software HZB，剔除 clusters 而不是 pixels，其分辨率取决于 cluster screen size
  - 依然会有大量 overdraws，来自：
    - Large clusters
    - Overlapping clusters
    - Aggregates（小三角形堆叠到同一像素）
    - Fast motion
  - Overdraw 对不同大小的 triangle 的影响不同
    - Small triangles: Vertex transform and triangle setup bound
    - Medium triangles: Pixel coverage test bound
    - Large triangles: Atomic bound

=== Nanite Deferred Material
前面介绍过 Visibility Buffer 的原理，在着色计算阶段的一种实现是维护一个全局材质表（存储材质参数以及相关贴图的索引），根据每个像素的 MaterialID 找到对应材质并解析，利用 Virtual Texture 等方案获取对应数据。对于简单的材质系统这是可行的，但是 UE 包含了一套极其复杂的材质系统，每种材质有不同的 Shading Model，同种 Shading Model 下各个材质参数还可以通过材质编辑器进行复杂的连线计算……简单来说，Nanite 想要支持完全由 artist 创建的 fragment shader。

为了保证每种材质的 shader code 仍然能基于材质编辑器动态生成，每种材质的 fragment shader 至少要执行一次，这样复杂的材质系统显然无法用上述方案实现（Not Cache-friendly，所用材质在内存中跳来跳去）。Nanite 的材质 shader 是在 Screen Space 执行的，以此将可见性计算和材质参数计算解耦，这也是 Deferred Material 名字的由来。

- *Material Classify*
  - Nanite 为每种材质赋予一个唯一的 material depth，每个材质都用一个 full screen quad 去绘制，深度检测函数采用 “等于通过”
  - 早期 Nanite 就是这么做的，看起来很费但实际上只会对真正耗时的着色进行屏幕像素数量次，大部分的绘制被深度检测跳过。但是当场景中的材质动辄成千上万，其带宽压力 (so unnecessary drawing instructions) 还是很大
  - 想要避免全屏渲染，很自然的思路就是引入 *tile-based* 方案，从而可以用 compute shader 扫一遍产生 Material Tile Remap Table
    - 根据屏幕分辨率决定 tile 数量，每 $32$ 个 tile 打包成一组，`MaterialRemapCount` 表示组的数量
    - 每个 tile 内用每个 bit 来记录 material 的存在性，每个 material 可以在绘制时跳过不包含它的 tile
    #tbl(
      columns: 7,
      bdiagbox[Tile Group][Material Slot],[0],[1],[2],[3],[...],[`MaterialRemapCount` - 1],
      [0],[\<32 bits\>],[],[],[],[],[],
      [1],[],[],[],[],[],[],
      [...],[],[],[],[],[],[],
      [`MaterialSlotCount` - 1],[],[],[],[],[],[]
    )
  - future work: 跟 virtual texture 结合，进一步减少材质的带宽压力

=== Nanite Shadows
Lumen 在做 GI 主要处理的是低频的间接光照，所以可以用 low-res 的 screen space probe 作为光照的代理；但 Nanite 作为一个精细几何的表达，其阴影将会十分高频（阴影比光照高频，这也是为什么 UE 里让二者协同工作）。

并且，Nanite 作为如此复杂的几何表达，硬件上的 Ray Trace 是无法处理的，因此我们还是诉诸于传统而广泛的 Cascaded Shadow Map，看能否将其一步步改造为 Nanite 所用方法。

- *Cascaded Shadow Map*
  - 试图通过远近分辨率的调整来控制 shadow map 中一个 texel 对应光空间区域的大小 (vie dependent sampling)
  - 属于相对 coarse 的 LoD 控制，如果想要达到较高的阴影质量需要显著的存储开销
  #grid(
    columns: (30%, 68%),
    column-gutter: 2em,
    fig("/public/assets/CG/GAMES104/2025-04-26-19-46-24.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-19-45-55.png")
  )
- *Sample Distribution Shadow Maps*
  - CSM 实际上很多地方是无效的（尤其是远处的区域），浪费大量的 resolution，Sample Distribution Shadow Maps 试图通过分析屏幕像素深度的范围，提供更佳的覆盖
  - 当我们这样想的时候，实际上也揭示了 shadow map 的本质：*根据相机视空间的精度去采样光空间*。shadow map 的 alias 也正是因为*相机空间对几何的采样跟几何在光空间对光的可见性采样频率不同*；shadow map 需要加 bias 也正是因为这个采样很不准确，需要加上一点容错
  - 不过，Sample Distribution Shadow Maps对于 LoD 的控制依旧比较粗糙
- *Virtual Shadow Map*
  - 在这些思想基础上更进一步，是对采样问题的本质解决（非常 elegant，很有可能是取代 CSM 的未来主流方案）
  - 把相机视空间划分为 clipmaps，每个 clipmap 划分一块 shadow map
    - 但 shadow map 的精度不是根据 world space 的大小决定，而是根据在 view space 占据像素数量决定，同样完成了根据相机视空间大小分配精度的目的
    - 并且 clipmap 的很大一个好处在于，一旦构建完毕，当光不变、相机移动时，只有部分区域需要更新（尤其对于不动的主光而言非常高效）
  - Nanite 为每一个光源分配了 $16k times 16k$ 的 virtual shadow map，不同的 light type 有不同的划分
  #grid(
    columns: (50%, 50%),
    column-gutter: 4pt,
    fig("/public/assets/CG/GAMES104/2025-04-26-20-01-43.png"),
    fig("/public/assets/CG/GAMES104/2025-04-26-20-01-58.png")
  )
  - tile 划分？Shadow Page Table and Physical Pages Pool？这里感觉完全没讲清楚，以后再来看吧

=== Streaming and Compression
#grid(
  columns: (60%, 35%),
  column-gutter: 2em,
  [
    这部分又是原作者大谈特谈的部分，但王希老师认为实际上是比较自然的细节。

    当我们构建好几何表示和 BVH 结构后，根据 page 的划分和类似 virtual texture 一样随用随加载的方式就很自然了，从而可以构建开放世界的 streaming。

    另外 Nanite 这样精细的几何表达必然开销很大，那么进行压缩也是非常自然的。包括使用定点数等方法 (quantization)，以及对于 Disk Representation 使用 LZ decompression 等等非常多的细节。
  ],
  fig("/public/assets/CG/GAMES104/2025-04-26-20-04-34.png")
)

- 额外参考资料
  + #link("https://zhuanlan.zhihu.com/p/382687738")[UE5渲染技术简介：Nanite篇]