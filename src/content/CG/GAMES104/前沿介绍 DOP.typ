#metadata(
  (
    order: 9,
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
#counter(heading).update(19)

= 面向数据编程与任务系统
== Parallel Programming 并行编程
- *Basics of Parallel Programming*
  + 摩尔定律的终结
  + 多核
  + 进程和线程
  + 多任务类型：Preemptive / Non-Preemptive
  + Thread Context Switch $->$ expensive
  + Embarrassingly Parallel Problem v.s. Non-embarrassingly Parallel Problem
    - 前者是理想情况，任务之间没有依赖关系，互不影响，容易并行化，最简单的例子就是蒙特卡洛采样，丢到多个线程各自执行；后者是真实情况下经常出现的情形，任务之间有各种 dependency
  + Data Race in Parallel Programming
    - Blocking Algorithm - Locking Primitives，都是操作系统里的基本概念
      - Issues with Locks: Deadlock Caused by Thread Crash, Priority Inversion
    - Lock-free Programming - Atomic Operations
      - Lock Free vs. Wait Free: 后者对整个系统做到 $100%$ 利用几乎难以达到，但对某个具体数据结构的完全利用还是有相应解法的
  + Compiler Reordering Optimizations
    - 编译器指令重排优化了性能，但存在打乱并行编程执行顺序的风险，硬件上的乱序执行也会导致类似问题
    - Cpp11 允许显式禁止编译器重排，但代价是性能下降
    - 程序开发一般有 debug 版本和 release 版本，debug 版本下基本可以认为执行顺序是严格的，release 版本下则不一定
- *Parallel Framework of Game Engine*
  - *Fixed Multi-thread*
    - 最简单的解法，把游戏引擎的各个模块分到不同的线程中去，e.g. Render, Simulation, Logic etc.
    - 1. 进程之间产生木桶效应，最慢的进程决定整体性能；2. 并且很难通过把一个模块拆分的方式解决，因为会出现 data racing 问题，且没有利用好 locality；3. 再者，每个模块的负载是动态变化而无法预先定义的，而用动态分配的方式会产生更多的 bug；4. 最后，玩家所用设备的芯片数五花八门，除非对每种数量预设都做过优化，否则部分核心直接闲置
  - *Thread Fork-Join*
    - 将引擎中一致性高、计算量大的任务（如动画运算、物理模拟）fork 出多个子任务，分发到预先定义的 work thread 中去执行，最后再将结果汇总
    - 显而易见这种 pattern 也会有许多核的闲置，但一般比 fixed 方法好，且鲁棒性更强，是 Unity, UE 等引擎的做法
    - 以 UE 为例，它显式地区分了 Named Thread (Game, Render, RHI, Audio, Stats...) 以及一系列 Worker Thread
  - *Task graph*
    - 把任务总结成有向无环图，节点表示任务，边表示依赖关系；把这个图丢给芯片，自动根据 dependency 决定执行顺序与并行化
    - dependency 的定义可以很淳朴，不断往每个 task 的 prerequest list 中 add 即可；问题在于，很多任务无法简单地划分，而且在运行过程中又可能产生新的任务、新的依赖，而这些在早期的 Task Graph 这样一个静态结构里没有相应的表述

== Job System 任务系统
- *Coroutine 协程*
  - 一个轻量级的执行上下文，允许在执行过程中 yield 出去，并在之后的某个时刻 resume 回来（被 invoke）
  - 跟 Thread 概念比较，它的切换由程序员控制，不需要 kernel switch 的开销，始终在同一个 thread 中执行
  - 两种 Coroutine
    - Stackful Coroutine: 拥有独立的 runtime stack，yield 后再回来能够恢复上下文，跟函数调用非常类似
    - Stackless Coroutine: 没有独立的 stack，切换成本更低，但对使用者而言更复杂（需要程序员自己显式保存需要恢复的数据）；并且只有 top-level routine 可以 yield，subroutine without stack 不知道返回地址而不能 yield
    - 两种方式无所谓高下，需要根据具体情况选择
  - 另外还有一个难点在于 Coroutine 在部分操作系统、编程语言中没有原生支持或支持机制各不相同
- *Fiber-based Job System*（可以参考 #link("https://zhuanlan.zhihu.com/p/594559971")[Fiber-based Job System 开发日志1]）
  - Fiber 也是一个轻量级的执行上下文，它跟 Coroutine 一样，也不需要 kernel switch 的开销，非常类似于 User Space Thread（某种程度上更像）。但不同在于，它的调度交由用户自定义的 scheduler 来完成，而不是像 Coroutine 那样 yield 来 resume 回去
    - 个人总结：Fiber 比 Thread 更灵活、轻量，比 Coroutine 更具系统性
    - 并且，对比这种通过调度方式分配和 Thread Fork-Join 方式分配，显然设定一个 scheduler 时时刻刻把空闲填满的方式更高效
  - Fiber-based Job System 中，Thread 是执行单元，跟 Logic Core 构成 1:1 关系以减少 context switch 开销；每个 Fiber 都属于一个 Thread，一个 Thread 可以有多个 Fibers 但同时只能执行一个，它们之间的协作是 cooperative 而非线程那样 preemptive 的
  - 通过创建 jobs 而不是线程来实现多任务处理（jobs 之间可以设置 dependency, priority），然后塞到 Fiber 中（类似于一个 pool），job 在执行过程中可以像 Coroutine 那样 yield 出去
  #fig("/public/assets/CG/GAMES104/2025-04-12-15-50-15.png", width: 50%)
  - *Job Scheduler*
    - Schedule Model
      - LIFO / FIFO Mode
      - 一般是 Last in First Out 更好，因为在多数情况下，job 执行过程中产生新的 job 和 dependency (tree like)，这些新的任务应该被优先解决
    - Job Dependency: job 产生新的依赖后 yield 出去，移到 waiting queue 中，由 scheduler 调度何时重启
    - Job Stealing: jobs 的执行时间难以预测准确，当某一 work thread 空闲，scheduler 从其他 work thread 中 steal jobs 分配给它
  - *总结*
    - 优点
      + 容易实现任务的调度和依赖关系处理
      + 每个 job stack 相互独立
      + 避免了频繁的 context switch
      + 充分利用了芯片，基本不会有太多空闲（随着未来芯片核数的增加，Fiber-based Job System 很有可能成为主流）
    - 缺点
      + Cpp 不支持原生 Fiber，且在不同操作系统上的实现不同，需要实现者对并行编程非常熟悉（一般是会让团队里基础最扎实、思维最缜密的成员负责搭建基座，其它成员只负责上层的脚本）
      + 且这种涉及到内存的底层实现系统非常难以 debug

== Data-Oriented Programming (DOP)
- *Programming Paradigms*
  - 存在各种各样的编程范式，不同编程语言又不局限于某一种范式
  - 游戏引擎这样复杂的系统往往需要几种的结合
  #fig("/public/assets/CG/GAMES104/2025-04-12-16-28-44.png", width: 80%)
  - 早期编程使用 Procedural Oriented Programming (POP) 就足够，后来随着复杂度增加，Object-Oriented Programming (OOP) 成为主流
- *Problems of OOP*
  + Where to Put Codes: 一个最简单的攻击逻辑，放在 Attacker 类里还是 Vectim 类里？存在二义性，不同程序员有不同的写法
  + Method Scattering in Inheritance Tree: 难以在深度继承树中找到方法的实现（甚至有时候还是组合实现的），并且同样存在二义性
  + Messy Based Class: Base Class 过于杂乱，包含很多不需要的功能
  + Performance: 内存分散不符合 locality，加上 virtual functions 问题更甚
  + Testability: 为了测试某一个功能要把整个对象创建出来，不符合 unit test 的原则
- *Data-Oriented Programming (DOP)*
  - 一些概念引入
    - Processor-Memory Performance Gap，直接导致 DOP 思想的产生
    - The Evolution of Memory - Cache & Principle of Locality
    - SIMD
    - LRU & its Approximation (Random Replace)
    - Cache Line & Cache Hit / Miss
  - DOP 的几个原则
    + Data is all we have 一切都是数据
    + Instructions are data too 指令也是数据
    + Keep both code and data small and process in bursts when you can 尽量保持代码和数据在 cache 中临近（内存中可以分开）
- *Performance-Sensitive Programming 性能敏感编程*
  - Reducing Order Dependency: 减少顺序依赖，例如变量一旦初始化后尽量不修改，从而允许更多 part 能够并行
  - False Sharing in Cache Line: 确保高频更新的变量对其 thread 保持局部（减少两个线程的交集），避免两个 threads 同时读写某一 cache line（cache contension，为了保持一致性需要 sync 到内存再重新读到 cache）
  - Branch prediction: 分支预测一旦出错，开销会很大。为了尽量避免 mis-prediction，会把用作判断的数组排个序来减少分支切换次数，或是干脆分到不同的容器里执行来砍掉分支判断 (Existential Processing)
- *Performance-Sensitive Data Arrangements 性能敏感数据组织*
  - Array of Structure vs. Structure of Array
  - SOA 效率更高，例如 vertices 的存储，它把 positions, normals, colors 等分开共同存储

== Entity Component System (ECS)
过去基于 OOP 的 Component-based Design，患有 OOP 的一系列毛病；而 ECS 则是 DOP 的一种实现方式，实际上就是之前讲过的概念的集合。

- *ECS 组成*
  - Entity: 实体，通常就是一个指向一组 componet 的 ID
  - Component: 组件，不同于 Component-based Design，ECS 中的 component 仅是一段数据，没有任何逻辑行为
  - System: 系统，包含一组逻辑行为，对 component 进行读写，逻辑相对简单方便并行化
  - 即把过去离散的 GO 全部打散，把数据和逻辑分开，数据按照 SOA 的方式整合存储为 Component，逻辑通过 System 来处理，只保留 Entity ID 作为索引
- *Unity ECS*
  - 采用 Unity Data-Oriented Tech Stack (DOTS)，分为三个组成部分
    + Entity Component System (ECS): 提供 DOP framework
    + C\# Job System: 提供简单的产生 multithreaded code 的方式
    + Burst Compiler: 自定义编译器，绕开 C\# 运行在虚拟机上的低效限制，直接产生快速的 native code
  - Unity ECS
    - Archetype: 对 Entities 的分组，即 type of GO
    - Data Layout: 每种 archetype 的 components 打包在一起，构成 chunks (with fixed size, e.g. 16KB)
      - 这样能够提供比单纯的所有 components 放在一起更细粒度的管理。比如是把所有 GO（包括角色、载具、道具）的 tranform 全堆在一起，还是把所有角色的、所有载具的、所有道具的 tranform 分开再存在一起？显然后者更好
    #fig("/public/assets/CG/GAMES104/2025-04-12-18-46-36.png", width: 70%)
    - System: 逻辑相对简单，拿到不同的 component 做某种运算
  - Unity C\# Job System
    - 允许用户以简单方式编写 multithreaded code，编写各种 jobs 且可以设置 dependency
    - jobs 需要 native containers 来存储数据、输出结果（绕开 C\# 虚拟机的限制，变为裸指针分配的与内存一一对应的一段空间），也因此需要做 safety check，需要 manully dispose（又回到老老实实写 Cpp 的感觉，也算是一开始使用 C\# 带来的恶果吧）
    - Safety System 提供越界、死锁、数据竞争等检查（jobs 操作的都是 copy of data，消除数据竞争问题）
  - Unity Burst Compiler
    - High-Performance C\# (HPC\#) 让用户以 C\#-like 的语法写 Cpp-like 代码，并编译成高效的 native code（很伟大的工作）
    - 摈弃了大多数的 standard library，不再允许 allocations, reflection, the garbage collection and virtual calls
- *Unreal Mass Framework —— MassEntity*
  - Entity: 跟 Unity 的 Entity 一样，都是一个 ID
  - Component
    - 跟 Unity 一样有 Archetype，由 fragments 和 tags 组成，fragments 就是数据，tags 是一系列用于过滤不必要处理的 bool 值
    - fragment 这个名字取得就比 Unity 好，既跟传统的 component 做出区分，又表示内存中一小块碎片、数据
  - System
    - UE 里叫 Processors，这个名字也起得比较切贴，用于处理数据
    - 提供两大核心功能 `ConfigureQueries()` and `Execute()`
  - Fragment Query
    - Processor 初始化完成后运行 `ConfigureQueries()`，筛选满足 System 要求的 Entities 的 Archetype，拿到所需的 fragments
    - 缓存筛选后的 Archetype 以加速未来执行
  - Execute
    - Query 后拿到的是 fragments 的引用（而不是真的搬过来，因为也是按照 trunk 存储、处理），Execute 时将相应 fragments chunk 搬运并执行相应操作

然而游戏是个很复杂、很 dependent 的系统，很难把所有逻辑按 ECS 架构组织，这可能也是为什么 ECS 在现今还未成为主流（有 “好看不好用” 的评价）。做游戏引擎千万不要有执念，关键是在什么场合把什么技术用对。

- Everything You Need Know About Performance（对着这张图进行优化）
  #fig("/public/assets/CG/GAMES104/2025-04-12-19-47-59.png", width: 90%)
