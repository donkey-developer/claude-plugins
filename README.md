# Donkey-Developer Code Review Plugin

## Description

A comprehensive Code Review Plugin for [Claude](https://claude.ai).
This code review allows generalist software engineers to extend their capability to supporting functions such as Architecture, Security, Site Reliability and Data Engineering.

## Features

- Comprehensive code review for Architecture, Security, SRE and Data Engineering practices
- Critical hygiene warnings
- Progressive level reporting, allowing you to focus on the next-best-action
- Summary roll up reporting for leadership to have high level oversight of the health and maturity of a system.

## Installation

Prerequisites: Assumes that [Claude Code](https://code.claude.com/docs/en/overview) is installed.

Add the marketplace
```bash
/plugin marketplace add https://github.com/donkey-developer/code-review-plugin.git
```

Install the plugin
```bash
/plugin install code-review@donkey-developer-code-review-plugin
```

## Usage

When using Claude Code, you can use the slash-commands to perform a code review.

You can perform a comprehensive code review with
```bash
/donkey-developer:review-all
```

This will trigger all of the other code reviews to occur, and generate a summary report with it.

To run a sub-set of the code-reviews use one of the specfic code reviews: review-sec, review-sre, review-arch, review-data e.g.

```bash
/donkey-developer:review-sre
```

## Configuration

Describe any configuration options here.

## Development

**TODO**

## Testing

**TODO**

## Contributing

Guidelines for contributing to this project.

## License

[Choose a license]

## Authors

- Lee Campbell [LeeCampbell.com](https://leecampbell.com)

## Support

How to get help or report issues.
