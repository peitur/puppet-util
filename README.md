# puppet-utils
Misc puppet tools hacked togeather for fun and profit ... 

## puppet_install : a simple hack, quick puppet installer
A simple puppet autoinstaller for rpm based systems, implemented in ruby (simplified)


## enc : a puppet host management tool(kit)

### etc/enc.json
Configuration is a json hash in the file etc/enc.json. 
- enc.debug : Enable debugging. This should not be used in production. All output is done to STDERR. [true|false]
- enc.match : Strictly use registered host names or enable a default profile for hosts that have not matched any names. [strict|default]
- db.engine : What lookup engine should be used, currently only supporting [dir]
- dir.db    : The engine profile path, i.e. the path to the profiles.

Example

```
{
  "enc.debug" : "false",
  "enc.match" : "strict",
  "db.engine" : "dir",
  "dir.db" : "/ect/puppet/enc"
}
```

All engines must have a default profile. 

### dir

Each enc profile is placed as a sepparate file in the directory specified in the dir.db setting.
Each file should contain a json hash that is speciffic for the host. Fileending should be ".json".

Inclusion between profiles is possible though the "include: <profile>" setting.

Example:
```
{
  "hostname":"test1.domain.com",
  "ntp": [
  	"time11.domain.com",
	"time12.domain.com"
  ]
}
```






