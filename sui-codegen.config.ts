import type { SuiCodegenConfig } from '@mysten/codegen';

const config: SuiCodegenConfig = {
    output: './src/generated',
    generateSummaries: true,
    prune: true,
    packages: [
        {
            package: '@local-pkg/sui_gacha',
            path: './',
        },
    ],
};

export default config;

