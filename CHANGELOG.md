# Changelog

## [2.3.3](https://github.com/guillaume5th/cairn/compare/v2.3.2...v2.3.3) (2026-11-14)


### Bug Fixes

* feeds with a structured &lt;author&gt; were rejected as "not a feed" (Google Cloud blog) ([6f6a644](https://github.com/guillaume5th/cairn/commit/6f6a6447502a5845ebc19f86a6ff8672782b6278))

## [2.3.2](https://github.com/guillaume5th/cairn/compare/v2.3.1...v2.3.2) (2026-11-14)


### Code Refactoring

* native DisclosureGroup for the summary box ([abb5bd0](https://github.com/guillaume5th/cairn/commit/abb5bd021cfb75a30deab3af5059d1d08075b7cc))

## [2.3.1](https://github.com/guillaume5th/cairn/compare/v2.3.0...v2.3.1) (2026-11-14)


### Bug Fixes

* launch crash of the DMG build: dyld rejected the ad-hoc signed Sparkle.framework ([cb5a6fa](https://github.com/guillaume5th/cairn/commit/cb5a6fa0025dba09c4df77cd02dc52713bce94ed))
* update originHash and add sparkle dependency in Package.resolved ([06a0e39](https://github.com/guillaume5th/cairn/commit/06a0e393f85b7d2e52257522d9017125a44838b1))

## [2.3.0](https://github.com/guillaume5th/cairn/compare/v2.2.0...v2.3.0) (2026-11-14)


### Features

* app updates with Sparkle ([0c1f950](https://github.com/guillaume5th/cairn/commit/0c1f95076e23fb1a850fceffe2d1783d29859549))
* Aujourd'hui view in the sidebar ([79a520e](https://github.com/guillaume5th/cairn/commit/79a520edb0d93a371b5328294eb93d7170d7067b))
* configurable retention and article order ([6741b5b](https://github.com/guillaume5th/cairn/commit/6741b5b71ff957a82e6dfdb0697e9740d6fe4eef))
* export a cairn as Markdown ([44523fa](https://github.com/guillaume5th/cairn/commit/44523fa99640548392ceecd296b30b3a39ca7390))
* feeds protected by a login ([2874001](https://github.com/guillaume5th/cairn/commit/28740019d9d908bf93461d4582e8a049aa9c1e94))
* kept articles in Spotlight ([4fba62f](https://github.com/guillaume5th/cairn/commit/4fba62f694123d018966b77ad14dcb0c0ae197d1))
* listen to podcast episodes ([1e5a9f4](https://github.com/guillaume5th/cairn/commit/1e5a9f43173ec70d78afdfbd29c95918b7cc7cf8))
* notify new articles per subscription ([ea5d654](https://github.com/guillaume5th/cairn/commit/ea5d654b9a2044618e6f9da7b1ba61b7299ee8eb))
* open feed: links ([89ef389](https://github.com/guillaume5th/cairn/commit/89ef3899dcf864b4b1f366854dd80201d3d979f6))
* rename a subscription, rename merge or delete a tag ([8ba4c31](https://github.com/guillaume5th/cairn/commit/8ba4c31d0267b72abcd7e281cec70d0d5b613dff))
* Space or N opens the next unread article ([451aa7c](https://github.com/guillaume5th/cairn/commit/451aa7cea8d09f9dda9956e446ee9e7613923d67))

## [2.2.0](https://github.com/guillaume5th/cairn/compare/v2.1.0...v2.2.0) (2026-11-13)


### Features

* daily backup to a chosen folder, and restore ([b4c4080](https://github.com/guillaume5th/cairn/commit/b4c4080651196b3e81023e9b2923ff59a5a5948e))
* icons in context menus and the Article menu ([56f293b](https://github.com/guillaume5th/cairn/commit/56f293b2ced350d288cc55184b70b3ef63a218d6))
* notes and tags of a kept article in an inspector ([a3b5f87](https://github.com/guillaume5th/cairn/commit/a3b5f8720ff75f8b6a6175796d439d0ddf5370e4))


### Bug Fixes

* keep the Add menu and the search field when the sidebar is hidden ([5d7cba4](https://github.com/guillaume5th/cairn/commit/5d7cba41bc848b590181c07ce1c9a605fb6fc4ae))

## [2.1.0](https://github.com/guillaume5th/cairn/compare/v2.0.0...v2.1.0) (2026-11-13)


### Features

* add an Article menu, Copy Link and Mark All as Read on feeds and folders ([2f786a2](https://github.com/guillaume5th/cairn/commit/2f786a2cabf2c292a7fa3b00d9e189eaa2eb18f3))
* add default notification style to Info.plist and project.yml ([a7055f6](https://github.com/guillaume5th/cairn/commit/a7055f6ffd18fed39aa4a2e2c6bfd92d77f84267))
* inline reset icon for text size in settings ([c210a2c](https://github.com/guillaume5th/cairn/commit/c210a2caf314eb52925fc3bd28de378eec70b382))
* put the selection's actions in the reader toolbar ([8a37b5c](https://github.com/guillaume5th/cairn/commit/8a37b5c852ac74693edbcb4c13316879751f57e8))
* refresh feeds automatically and show the unread count on the Dock icon ([d4640ff](https://github.com/guillaume5th/cairn/commit/d4640ff0cb7233ceedfcba6a5310d0f4cb9459fc))
* share one ticked article and toggle read state from the reader toolbar ([76cdc0c](https://github.com/guillaume5th/cairn/commit/76cdc0c8925f4cd83859f65f2f7bf13aaacd0133))
* stop selecting the first article by default ([3cd3915](https://github.com/guillaume5th/cairn/commit/3cd3915cfa4fff46514a433632d0315de4a297b1))
* turn the automatic daily digest on or off ([124958b](https://github.com/guillaume5th/cairn/commit/124958b3d722d921fdec2e692d3393b3db75bf8f))

## [2.0.0](https://github.com/guillaume5th/cairn/compare/v1.4.0...v2.0.0) (2026-11-13)


### ⚠ BREAKING CHANGES

* Cairn no longer builds for iPhone and iPad.

### Features

* focus on the Mac app, drop the iPhone and iPad app ([#13](https://github.com/guillaume5th/cairn/issues/13)) ([a987a3d](https://github.com/guillaume5th/cairn/commit/a987a3d25a93706410a765305ee810b848eb3d07))

## [1.4.0](https://github.com/guillaume5th/cairn/compare/v1.3.0...v1.4.0) (2026-11-12)


### Features

* share, feed discovery, full articles and background digest ([#11](https://github.com/guillaume5th/cairn/issues/11)) ([af7bc4c](https://github.com/guillaume5th/cairn/commit/af7bc4c65de64e01e441612ccfd74874d696cebe))

## [1.3.0](https://github.com/guillaume5th/cairn/compare/v1.2.0...v1.3.0) (2026-11-12)


### Features

* align the interface across Mac, iPhone and iPad ([#8](https://github.com/guillaume5th/cairn/issues/8)) ([0579dc8](https://github.com/guillaume5th/cairn/commit/0579dc862c45d4d0e4d2a548fdd8b26c697ce53f))

## [1.2.0](https://github.com/guillaume5th/cairn/compare/v1.1.0...v1.2.0) (2026-11-12)


### Features

* add an iPhone and iPad app ([#6](https://github.com/guillaume5th/cairn/issues/6)) ([38ab89c](https://github.com/guillaume5th/cairn/commit/38ab89c909ebd0d894fa478036462aaa06c26412))

## [1.1.0](https://github.com/guillaume5th/cairn/compare/v1.0.0...v1.1.0) (2026-11-12)


### Features

* update DMG creation command to use diskutil for improved compatibility ([f51ea2c](https://github.com/guillaume5th/cairn/commit/f51ea2c26dbf32cfe012fe129401a090bf4066a7))


### Bug Fixes

* keep running when the window is closed ([#5](https://github.com/guillaume5th/cairn/issues/5)) ([9e35a07](https://github.com/guillaume5th/cairn/commit/9e35a07d1734d59e5225b68cff7df29ba5f45280))

## [1.0.0](https://github.com/guillaume5th/cairn/compare/v0.1.0...v1.0.0) (2026-11-12)


### Features

* Add a refresh button to the article list toolbar ([e0ff53f](https://github.com/guillaume5th/cairn/commit/e0ff53fd38ca91de966f3620a002f70410605c86))
* Add a subscription from the sidebar section header ([f6c9020](https://github.com/guillaume5th/cairn/commit/f6c90209bda5d229d54688063866bc320c5b5fdb))
* Add initial implementation of Cairn macOS app with core functionality ([c2e7e0b](https://github.com/guillaume5th/cairn/commit/c2e7e0b5145aaf76426e67718fd266e0c36a0091))
* Add support for deleting orphan articles and update UI icons ([485d9ad](https://github.com/guillaume5th/cairn/commit/485d9ada28097d9e6b8cec1bed1f93907d00ee92))
* Add support for displaying site icons in feeds with caching and periodic refresh ([ea82a8b](https://github.com/guillaume5th/cairn/commit/ea82a8ba0ecd5a538995da6820490bb1a6ce640e))
* Add support for feed icons and site URLs ([b68b067](https://github.com/guillaume5th/cairn/commit/b68b067cc32fbd9bb1ce3e3a5eacdecff0c4a0b2))
* Adjust the reading text size and hide list icons from the View menu ([03b8df3](https://github.com/guillaume5th/cairn/commit/03b8df356f3ded3309b58827e8784a3c0fb3cd17))
* daily ai digest ([76a5e7c](https://github.com/guillaume5th/cairn/commit/76a5e7c5f285da41cdcb25ffabe864a6dc788a95))
* Enhance article summary view with scroll handling and "Read more" button ([62ad914](https://github.com/guillaume5th/cairn/commit/62ad91406a5f04ce24c783dd07324b4e0697137c))
* Enhance sidebar with native menu for adding subscriptions and folders ([2190f45](https://github.com/guillaume5th/cairn/commit/2190f45c571cd8cfdb931abcfc29111634ad2103))
* Highlight the search term in the article list and the reader ([2a3fd54](https://github.com/guillaume5th/cairn/commit/2a3fd5448deacf589270f27af56486dd6e48c15e))
* Implement article summarization feature with AI, including UI updates and error handling ([d852197](https://github.com/guillaume5th/cairn/commit/d852197bb3bd7ff8d9062323fb2acee838cf2d68))
* Implement multi-selection functionality for articles, summaries, and subscriptions ([b0f8644](https://github.com/guillaume5th/cairn/commit/b0f8644f0e3d7b56ef23c846b98937a0d273225b))
* Implement support for displaying site icons in article lists and sidebar ([56adfa3](https://github.com/guillaume5th/cairn/commit/56adfa33a3a4cd1326729ecbf6fbd5cb78b41d2e))
* init openspec ([fb6170a](https://github.com/guillaume5th/cairn/commit/fb6170ae6410063ccf47e966b058b9ecd01ce500))
* Initial commit for Cairn v1 macOS application ([ab6e1bb](https://github.com/guillaume5th/cairn/commit/ab6e1bb9ade853154f74fa575822991271d97384))
* Keep articles in several named cairns ([8897fa7](https://github.com/guillaume5th/cairn/commit/8897fa78364643b1b82e92f27f44726b8d4bd50a))
* Keep or unkeep an article from its context menu ([6ca07f1](https://github.com/guillaume5th/cairn/commit/6ca07f1dab53523de85a394581cd8db6c0be7d44))
* Organize subscriptions into folders ([8361f62](https://github.com/guillaume5th/cairn/commit/8361f622cfb4aac04356dd1c73815d04001a60a3))
* Replace read indicator with UnreadDot component for improved UI consistency ([a9cfac4](https://github.com/guillaume5th/cairn/commit/a9cfac4b2ddbbd609d380683ba7ae5e445dedee0))
* Restyle the tag editor as a wrapping token field ([51a203a](https://github.com/guillaume5th/cairn/commit/51a203a6d13e7993f4e84d35a443408f941773ce))
* Search the article list in every sidebar view ([5a514d3](https://github.com/guillaume5th/cairn/commit/5a514d3b2a15ea38e370ece23bf4b220f92bd53e))
* Select the first article by default and remember the selection per sidebar entry ([44e0a8b](https://github.com/guillaume5th/cairn/commit/44e0a8b4ff9ce5e9f9ee9153d7fe6751643cf985))
* Show a blue dot instead of a bold title for unread articles ([229a5ad](https://github.com/guillaume5th/cairn/commit/229a5adec3ce208952a90af568712d28fe59183e))
* Show the unread count of all articles in the sidebar ([1b5e6f4](https://github.com/guillaume5th/cairn/commit/1b5e6f4bf155b01bc99ab53e91578b5ee13d55fd))
* Summarize the day's articles with a local AI ([e45e454](https://github.com/guillaume5th/cairn/commit/e45e4541df0fa189c8032780bc334e6da2007788))
* Update settings view for daily digest configuration and improve UI elements ([6c2a3de](https://github.com/guillaume5th/cairn/commit/6c2a3de43ea197748bb736984b8472a271d8264c))
* Update terminology to "Résumés quotidiens" for consistency across the application ([93d09bc](https://github.com/guillaume5th/cairn/commit/93d09bccbfa59f699e27be2a5d32e6922ddef01d))


### Bug Fixes

* Adjust positions of elements in SVG assets ([6c3ced5](https://github.com/guillaume5th/cairn/commit/6c3ced53f6e295f0169d906b57e55fa10ded039f))
* Line up the sidebar add button with the unread counters ([552a21d](https://github.com/guillaume5th/cairn/commit/552a21dba0e08fa16d4bce1b6f93e3452c158d8b))
* Return drop result from sidebar drop destinations ([6113a8f](https://github.com/guillaume5th/cairn/commit/6113a8f784d93f7efbaa2acb85dac9bf1bde74b3))
* Spin the refresh icon instead of swapping it for a spinner ([70ba72b](https://github.com/guillaume5th/cairn/commit/70ba72bd148127c3d57b927d1700cc2faa43710e))


### Miscellaneous Chores

* set up release-please and local DMG release script ([#2](https://github.com/guillaume5th/cairn/issues/2)) ([aa366c9](https://github.com/guillaume5th/cairn/commit/aa366c97f1df69363247ec42ab43aee0341035fe))
