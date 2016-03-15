# MonkeyKing

Monkey king is a tool which is initially designed for generating deployment manifests for a bosh deployment based on an existing deployment, and it could also be used for other purposes like performing functions on keys/values in yaml files based on yaml tags.


Here is some scenarios about how it works:
## Using secret generation
The `!MK:secret` directive generates a random secret of the same length as the value it replaces.
BEFORE
```
---
meta:
  secret: !MK:secret old_secret
  another_secret: !MK:secret old_secret
  not_secret: not_secret
```

AFTER
```
---
meta:
  secret: !MK:secret new_secret
  another_secret: !MK:secret new_secret
  not_secret: not_secret
```

## Using environment variables
The `!MK:env:<variable_name>` directive pulls values from environment variables and replaces the tagged keys/values

Given:

```
export id1=id1_from_env
export id2=id2_from_env
```

Before:
```
---
meta1:
  not_secret: not_secret
  layer1:
  - id1: !MK:env:id1 id1_before
  - layer2:
    - id2: !MK:env:id2 id2_before
  - !MK:env:id1 id3: !MK:env:id1 id1_before
```

After:
```
---
meta1:
  not_secret: not_secret
  layer1:
  - id1: !MK:env:id1 id1_from_env
  - layer2:
    - id2: !MK:env:id2 id2_from_env
  - !MK:env:id1 id1_from_env: !MK:env:id1 id1_from_env
```


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'monkey_king'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install monkey_king

## Usage
```
$ mk help
Commands:
  help [COMMAND]   	Help!
  clone REPO DIR...	Clone the repo and replace secret and env annotation
  replace GLOBS... 	Replace secret and env annotation for existing directory
```
```
$ mk help clone
Clone the repo and replace secret and env annotation

Usage: clone REPO DIR...

Options:
      --dir DIR
      --repo REPO
```
```
$ mk help replace
Replace secret and env annotation for existing directory

Usage: replace GLOBS...

Options:
      --globs GLOBS
```

Example 1: clone the repo and replace all the manifest under bosh-init directory.

```
$ mk clone --repo git@github.com:[USERNAME]/[DEPLOYMENT].git bosh-init
Cloning into '[DEPLOYMENT]'...
remote: Counting objects: 346, done.
remote: Total 346 (delta 0), reused 0 (delta 0), pack-reused 346
Receiving objects: 100% (346/346), 179.86 KiB | 0 bytes/s, done.
Resolving deltas: 100% (157/157), done.
Checking connectivity... done.
Transforming [DEPLOYMENT]/bosh-init/bosh-init.yml...
Done.
```

Example 2: replace all the manifest under bosh-init directory.

```
$ mk replace deployment0/bosh-init/*.yml
Transforming deployment0/bosh-init/bosh-init.yml...
Done.
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/monkey_king. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

