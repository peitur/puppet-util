# puppet-utils
Misc puppet tools hacked togeather for fun and profit ... 

## puppet_install : a simple hack, quick puppet installer
A simple puppet autoinstaller for rpm based systems, implemented in ruby (simplified)

## encadm 
The admin command used to manage the different profiles through the command line.
One command is used to administer the hosts and profiles from the command line.

```
bin/encadm help
encadm <task> <options>
Supported task are [add|del|mod|list|fetch|bind|help]

Tasks:
        add     Add a prfile and filename       Requires:[profile,file]
        del     Delete a profile                Requires:[profile]
        mod     Modify existing profile         Requires:[profile, file]
        list    List available profiles         Requires:[]
        fetch   Fetch a profile content         Requires:[profile]
        bind    Bind a host to a profile        Requires:[host,profile]
        
Options:
        --help          -h      This help
        --debug         -d      Enable debugging
        --profile       -p      Profile name
        --file          -i      Filename to use as source
        --host          -H      Host (cert) name        
```



### Adding profile

First, prepare a input file to add. Use JSON format to describe the configuration.
```
cat example.json
{
  "ntp": [
        "time11.domain.com",
        "time12.domain.com"
  ]
}
```

Use the file 
```
encadm add --profile default --file example.json
```

### Binding host to a profile
```
encadm bind --host test.example.com --profile default
```

### Deleting profile

Deleting a profile
```
encadm del --profile default
```

Deleting a host binding
```
encadm del --host test.example.com
```


### Listing profiles and hosts
Lists both profiles and 
```
encadm list
```



## enc : a puppet host management tool(kit)

### etc/enc.json
Configuration is a json hash in the file etc/enc.json. 
- enc.env   : Type of environment, e.g. production/testing/devel
- enc.ctype : Configuration type (when not specified in profile)
- enc.debug : Enable debugging. This should not be used in production. All output is done to STDERR. [true|false]
- enc.match : Strictly use registered host names or enable a default profile for hosts that have not matched any names. [strict|default]
- db.engine : What lookup engine should be used, currently only supporting [dir]
- dir.db    : The engine profile path, i.e. the path to the profiles.

Example

```
{
  "enc.debug" : "false",
  "enc.match" : "strict",
  "enc.env"   : "production",
  "enc.ctype" : "parameters",
  "db.engine" : "dir",
  "dir.db" : "/ect/puppet/enc"
}
```

All engines must have a default profile. 

### dir

Each enc profile is placed as a sepparate file in the directory specified in the dir.db setting.
Each file should contain a json hash that is speciffic for the host. Fileending should be ".json".

Inclusion between profiles is possible though the "include: <profile>" setting.

Example, defalt:
```
{
  "hostname":"test1.domain.com",
  "ntp": [
  	"time11.domain.com",
	"time12.domain.com"
  ]
}
```

Example, dev.domain.com:
```
{
    "hostname": "test00.test.com",
    "include": "default"
}
```

Result will be:
```
---
parameters:
  hostname: test00.test.com
  ntp:
  - time11.domain.com
  - time12.domain.com
environment: production
```

To mix classes and parameters in the same definition just specify each one. Include operations are not supported yet.
```
{
    "parameters": {
        "hostname": "dd.test.com"
    },
    "classes" : {
        "ntp": [
                "time1.domain.com",
                "time2.domain.com"
            ]
    }
}
```

Results will be
```
---
parameters:
  hostname: dd.test.com
classes:
  ntp:
  - time1.domain.com
  - time2.domain.com
environment: production
```