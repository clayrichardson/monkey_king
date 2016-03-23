# MonkeyKing

Monkey king is a tool which is initially designed for generating deployment manifests for a bosh deployment based on an existing deployment, and it could also be used for other purposes like performing functions on keys/values in yaml files based on yaml tags.

Here is some scenarios about how it works:

## Using secret generation
The `!MK:secret(<password_length>)` directive generates a random secret with the lenght specified in the parameter

Before

```
---
meta:
  secret: !MK:secret(12) replace_me
  another_secret: !MK:secret replace_me
  not_secret: not_secret
```

After
```
---
meta:
  secret: !MK:secret(12) SomeRandomPass
  another_secret: !MK:secret() AnotherRandomPass
  not_secret: not_secret
```

## Using environment variables
The `!MK:env(<variable_name>)` directive pulls values from environment variables and replaces the tagged keys/values

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
  - id1: !MK:env(id1) id1_before
  - layer2:
    - id2: !MK:env(id2) id2_before
  - !MK:env(id1) id3: !MK:env:id1 id1_before
```

After:
```
---
meta1:
  not_secret: not_secret
  layer1:
  - id1: !MK:env(id1) id1_from_env
  - layer2:
    - id2: !MK:env(id2) id2_from_env
  - !MK:env(id1) id1_from_env: !MK:env:id1 id1_from_env    
```

## Using Read and Write
The `!MK:read(<variable_name>)` and `!MK:write(<variable_name>,<value>)` directive is used to save the generated value and use it later.

Before
```
---
meta:
  secret: !MK:write(nat_secret,secret(12)) replace_me
  same_secret_again: !MK:read(nat_secret) replace_me
```

After
```
---
meta:
  secret: !MK:write(nat_secret,secret(12)) SAME_PASSWORD_HERE
  same_secret_again: !MK:read(nat_secret) SAME_PASSWORD_HERE
```

## Using string format
The `!MK:format(<variable_1,variable_2>,...)` directive can be used to format the string given in the yaml field.

Given:
```
export NAT_HOST=10.10.0.6
```

Before
```
---
meta:
  nat_url: !MK:format(env(NAT_HOST)) https://%s
```

After
```
---
meta:
  nat_url: !MK:format(env(NAT_HOST)) https://10.10.0.6
```

## Combine them all
You can combine the directive in a LISP-like syntax to create more poweful usages:

####Example:

Given:
```
export NAT_USER=nats_user
export NAT_HOST=10.10.0.6
```

Before

```
meta1:
  not_secret: not_secret
  layer1:
  - nat_user: !MK:write(NATS_USER,env(NATS_USER)) replaceme
  - nat_host: !MK:write(NATS_HOST,env(NATS_HOST)) replaceme
  - nat_password: !MK:write(NATS_PASSWORD,secret(12)) replaceme
  layer2:
  - nat_connection: !MK:write(NATS_STRING,format(read(NATS_USER),read(NATS_PASSWORD),read(NATS_HOST))) https://%s:%s@%s
  - info_endpoint: !MK:format(read(NATS_STRING)) '%s/info'
```


After

```
meta1:
  not_secret: not_secret
  layer1:
  - nat_user: !MK:write(NATS_USER,env(NATS_USER)) nats_user
  - nat_host: !MK:write(NATS_HOST,env(NATS_HOST)) 10.10.0.6
  - nat_password: !MK:write(NATS_PASSWORD,secret(12)) SOMEPASSWORD
  layer2:
  - nat_connection: !MK:write(NATS_STRING,format(read(NATS_USER),read(NATS_PASSWORD),read(NATS_HOST))) https://nats_user:SOMEPASSWORD@10.10.0.6
  - info_endpoint: !MK:format(read(NATS_STRING)) https://nats_user:SOMEPASSWORD@10.10.0.6/info
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
    
**Or if you want the cutting edge**

```
git clone https://github.com/pivotal-cloudops/monkey_king.git
cd monkey_king
bundle exec mk
```

## Try it Out:

You can create a yaml file (example: demo.yml in ~/tmp) with the 'MK' yaml tags as described earlier.

Then run:

```
cd monkey_king
bundle exec mk demo ~/tmp/demo.yml
``` 


## Full Usage
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

