import { defineCollection, z } from 'astro:content';

const collection1 = defineCollection({
    type: 'content',
    schema: z.object({
        title: z.string().optional(),
        author: z.string().optional(),
        desc: z.any().optional(),
        date: z.any().optional(),
        order: z.number().optional(),
        hide: z.boolean().optional(),
    })
});

export const collections = { // 这里定义了 collections 的类型和它们的顺序
    'Courses': collection1,
    'Languages': collection1,
    'Math': collection1,
    'CG': collection1,
    'CV': collection1,
    'AI': collection1,
    'Reading': collection1,
    '其它': collection1,
};
