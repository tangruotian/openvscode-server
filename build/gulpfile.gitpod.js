/*!--------------------------------------------------------
* Copyright (C) Gitpod. All rights reserved.
*--------------------------------------------------------*/

'use strict';

const promisify = require('util').promisify;
const cp = require('child_process');
const argv = require('yargs').argv;
const vsce = require('vsce');
const gulp = require('gulp');
const path = require('path');
const es = require('event-stream');
const util = require('./lib/util');
const task = require('./lib/task');
const rename = require('gulp-rename');
const ext = require('./lib/extensions');

gulp.task(task.define('watch-init', require('./lib/compilation').watchTask('out', false)));

const extensionsPath = path.join(path.dirname(__dirname), 'extensions');
const marketplaceExtensions = ['gitpod-remote'];
const outMarketplaceExtensions = 'out-gitpod-marketplace';
const cleanMarketplaceExtensions = task.define('clean-gitpod-marketplace-extensions', util.rimraf(outMarketplaceExtensions));
const bumpMarketplaceExtensions = task.define('bump-marketplace-extensions', () => {
	if ('new-version' in argv && argv['new-version']) {
		const newVersion = argv['new-version'];
		console.log(newVersion);
		return Promise.allSettled(marketplaceExtensions.map(async extensionName => {
			const { stderr } = await promisify(cp.exec)(`yarn version --new-version ${newVersion} --cwd ${path.join(extensionsPath, extensionName)} --no-git-tag-version`, { encoding: 'utf8' });
			if (stderr) {
				throw new Error('failed to bump up version: ' + stderr);
			}
		}));
	}
});

const bundlePortsWebview = task.define('bundle-remote-ports-webview', async () => {
	await promisify(cp.exec)(`yarn --cwd ${path.join(extensionsPath, 'gitpod-remote')} run build:webview`, { encoding: 'utf8' });
	gulp.src([`${path.join(extensionsPath, 'gitpod-remote')}/public/**/*`]).pipe(gulp.dest(path.join(outMarketplaceExtensions, 'gitpod-remote/public/')));
});
gulp.task(bundlePortsWebview);
for (const extensionName of marketplaceExtensions) {
	const cleanExtension = task.define('gitpod:clean-extension:' + extensionName, util.rimraf(path.join(outMarketplaceExtensions, extensionName)));
	const bumpExtension = task.define('gitpod:bump-extension:' + extensionName, async () => {
		if ('new-version' in argv && argv['new-version']) {
			const newVersion = argv['new-version'];
			const { stderr } = await promisify(cp.exec)(`yarn version --new-version ${newVersion} --cwd ${path.join(extensionsPath, extensionName)} --no-git-tag-version`, { encoding: 'utf8' });
			if (stderr) {
				throw new Error('failed to bump up version: ' + stderr);
			}
		}
	});
	const bundleExtension = task.define('gitpod:bundle-extension:' + extensionName, task.series(
		cleanExtension,
		bumpExtension,
		() =>
			ext.minifyExtensionResources(
				ext.fromLocal(path.join(extensionsPath, extensionName), false)
					.pipe(rename(p => p.dirname = `${extensionName}/${p.dirname}`))
			).pipe(gulp.dest(outMarketplaceExtensions))
	));
	gulp.task(bundleExtension);
	const publishExtension = task.define('gitpod:publish-extension:' + extensionName, task.series(
		bundleExtension,
		bundlePortsWebview,
		() => vsce.publish({
			cwd: path.join(outMarketplaceExtensions, extensionName)
		})
	));
	gulp.task(publishExtension);
	const packageExtension = task.define('gitpod:package-extension:' + extensionName, task.series(
		bundleExtension,
		bundlePortsWebview,
		() => vsce.createVSIX({
			cwd: path.join(outMarketplaceExtensions, extensionName)
		})
	));
	gulp.task(packageExtension);
}
