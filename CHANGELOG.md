# Change Log

All notable changes to this project will be documented in this file.
This project adheres to [Semantic Versioning](http://semver.org/).

## [Unreleased]

## [0.3.0] - 2016-07-28

- VCR cassette format is now handled by [vcr-archive](https://github.com/everypolitician/vcr-archive), leaving this gem to handle wrapping VCR and saving to git.
- Git interactions are now done with [ruby-git](https://github.com/schacon/ruby-git) rather than shelling out where possible.

## [0.2.0] - 2016-07-27

- Working version of persisting using VCR.

## 0.1.0 - 2016-07-27

- Initial release

[Unreleased]: https://github.com/everypolitician/vcr-archive/compare/v0.3.0
[0.3.0]: https://github.com/everypolitician/vcr-archive/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/everypolitician/vcr-archive/compare/v0.1.0...v0.2.0
