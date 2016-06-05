# Jobrnr

[![Build Status](https://travis-ci.org/rfdonnelly/jobrnr.svg?branch=master)](https://travis-ci.org/rfdonnelly/jobrnr)

Jobrnr runs jobs.

* A job can have prerequisite jobs.
* A job can be repeated many times.
* A job can be passed a random seed.
* Jobs are run simultaneously where possible.
* Additional functionality can be added via plug-ins.

## Example

```ruby
job :compile do
  execute 'make compile'
end

job :simulate, :compile do
  execute 'make simulate SEED=__SEED%x__'
  repeat 50
end
```

This job description specifies a single compilation job and a single simulation
job.  The compilation job is a prerequisite for the simulation job.  The
simulation job will not be executed until the compilation job completes
successfully.  After the compile job completes successfully, 50 instances of
the simulation job will be executed.  Each instance will execute with a random
value for SEED.  The simulation job instances will be run simultaneously.
