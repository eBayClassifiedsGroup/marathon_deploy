![Travis Build Status](https://travis-ci.org/joncolby/marathon_deploy.svg?branch=master)

# Marathon Deploy

A [Marathon](https://mesosphere.github.io/marathon/) command-line deployment tool in Ruby.  Takes a json or yaml file describing an application and pushes it to the Marathon [REST API](https://mesosphere.github.io/marathon/docs/rest-api.html)

### Feature Summary
* Deploy a single application descriptor to multiple marathon endpoints
* Checks for existing deployment of application before starting new deployment
* Polls for Healthcheck results after deployment
* Proper exit codes for easier integration with Jenkins automated pipelines
* Deploy file macro substitution using values from locally set environment (ENV) variables (macros have the format %%MACRO_NAME%% and must match the environment variable name)
* Inject environment variables into a deployment when local environment variables with the format: MARATHON_DEPLOY_FOO=BAR  are set (MARATHON_DEPLOY prefix will be removed in final json payload).
* PRODUCTION / PREPRODUCTION modes (specified with --environment)
* Rolling upgrade deployment strategy (Marathon default)


### Roadmap Features
* Record actions and json payload to a database (for rollback, history, auditing)
* Deploy a deployment descriptor containing multiple applications
* Specify deployment strategy (using minimumHealthCapacity) as an option. See [Marathon Deployment document](https://mesosphere.github.io/marathon/docs/deployments.html)


## Installation

Ensure Ruby (1.9+) and gem are installed on you system, then run:

```
$ gem install marathon_deploy
```

Executables from this gem:

    $ marathon_deploy  (client program executable, automatically added to $PATH)
    $ extra/json2yaml (convenience utility for converting json to yaml)
    $ extra/expand_macros (expands all macros in the form %%MACRO%% with value of ENV[MACRO])


## Usage

### Help
```
>marathon_deploy -h
Usage: bin/marathon_deploy [options]
    -u, --url MARATHON_URL(S)        Default: ["http://localhost:8080"]
    -l, --logfile LOGFILE            Default: STDOUT
    -d, --debug                      Run in debug mode
    -v, --version                    Version info
    -f, --force                      Force deployment when sending same deploy JSON to Marathon
    -n, --noop                       No action. Just display what would be performed.
    -e, --environment ENVIRONMENT    Default: PREPRODUC
```

### Example Deployfile
By default, a file called 'deploy.yml' is searched for in the current directory where deploy.rb is run from.  An alternative file name can be provided with the -f parameter.

The file format must conform to the [Marathon API specification](https://mesosphere.github.io/marathon/docs/rest-api.html#post-/v2/apps)

Minimalistic example (using Docker container):

```
id: python-example-stable
cmd: echo python stable `hostname` > index.html; python3 -m http.server 8080
mem: 16
cpus: 0.1
instances: 5
container:
  type: DOCKER
  docker:
    image: ubuntu:14.04
    network: BRIDGE
    portMappings:
    - containerPort: 8080
      hostPort: 0
      protocol: tcp
env:
  SERVICE_TAGS: python,webapp,http,weight=100
  SERVICE_NAME: python
healthChecks:
- portIndex: 0
  protocol: TCP
  gracePeriodSeconds: 30
  intervalSeconds: 10
  timeoutSeconds: 30
  maxConsecutiveFailures: 3
- path: "/"
  portIndex: 0
  protocol: HTTP
  gracePeriodSeconds: 30
  intervalSeconds: 10
  timeoutSeconds: 30
  maxConsecutiveFailures: 3
```

### JSON to YAML file conversion

As a convenience, the provided json2yaml.rb script can convert a JSON file to the arguably more human-readable YAML format:

```
$json2yaml marathon-webapp.json  > marathon-webapp.yaml
```

### Parsing a file with macro expansion from ENV variables

A helper script which takes a file and replaces all macros having the format %%MACRO%% with the values from ENV variables.  Script will fail if there are no ENV values for macro names contained in the template.

```
$expand_macros -h
Usage: bin/expand_macros.rb [options]
    -o, --outfile OUTFILE            Default: STDOUT
    -l, --logfile LOGFILE            Default: STDOUT
    -d, --debug                      Run in debug mode
    -v, --version                    Version info
    -f, --force                      force overwrite of existing OUTFILE
    -t, --template TEMPLATE_FILE     Input file. Default: dockerfile.tpl
    -h, --help                       Show this message
```

## Contributing

1. Fork it ( https://github.com/[my-github-username]/marathon_deploy/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
