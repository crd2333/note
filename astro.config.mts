import { defineConfig } from "astro/config";
import { type AstroIntegration } from "astro";
import { typst } from 'astro-typst';
import playformCompress from "@playform/compress";
import terser from '@rollup/plugin-terser';
import swup from '@swup/astro';
import SwupScrollPlugin from '@swup/scroll-plugin';
import SwupParallelPlugin from '@swup/parallel-plugin';

// https://astro.build/config
export default defineConfig({
    devToolbar: {enabled: false},
    site: 'https://crd2333.github.io',
    base: '/note',
    integrations: [
        typst({
            options: {
                remPx: 14
            },
            target: (id: string) => {
                console.debug(`Detecting ${id}`);
                if (id.endsWith('.html.typ') || id.includes('/html/'))
                    return "html";
                return "svg";
            }
        }),
        terser({
            compress: true,
            mangle: true,
        }),
        swup({
            plugins: [new SwupScrollPlugin(), new SwupParallelPlugin()],
            containers: ["#swup"]
        }),
        playformCompress()
    ],
    vite: {
        ssr: {
            external: ["@myriaddreamin/typst-ts-node-compiler"]
        }
    },
});
