# Boston Cares

> Boston Cares is the largest volunteer agency in New England, a member of the Points of Light Global Network, and an award-winning leader in the volunteer engagement sector. Filling more than 25,000 volunteer spots annually in support of more than 180 Greater Boston schools and non-profit agencies, we offer a wide array of programs and opportunities that make it simple for you to volunteer no matter how busy your schedule. We believe volunteers transform communities through service and civic engagement.

This repo contains metadata for the Salesforce org used by Boston Cares staff.

## How to contribute

We are still in the process of pulling down missing metadata,
so that developers can use simple `sfdx` commands to spin up a scratch org
for immediate development.

```sh
# Create a scratch org
sfdx force:org:create -f config/project-scratch-def.json -s

# Push source to the scratch org
sfdx force:source:push
```
