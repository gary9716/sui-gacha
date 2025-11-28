import type { SuiCodegenConfig } from '@mysten/codegen';

const config: SuiCodegenConfig = {
    output: './src/generated',
    prune: true,
    packages: [
        {
            package: '@local-pkg/gacha',
            path: './',
        },
    ],
};

export default config;

