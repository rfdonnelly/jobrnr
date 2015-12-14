# JobRnr

JobRnr runs jobs.  Jobs can be dependent on other jobs.  Jobs are run in parallel when possible.  Jobs can be repeated with different random seeds.  Additional functionality can be added via a plugin system.

## Example

The following job description describes a single compilation job and a single simulation job that is dependent on the compilation job.  The simulation job will not be executed until the compilation job completes successfully.  After the compile job completes successfully, 50 instances of the simulation job will be executed.  Each instance will execute with a random value for SEED.  The simulation job instances will be run in parallel.  The maximum number of job instances run in parallel is user configurable.

```ruby
job :compile do
  execute 'make compile'
end

job :simulate, :compile do
  execute 'make simulate SEED=__SEED%x__'
  repeat 50
end
```
