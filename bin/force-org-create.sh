#!/bin/zsh
sfdx force:org:create -f config/project-scratch-def.json -s || exit 1
sfdx force:source:deploy -m InstalledPackage:HOC || exit 1
sfdx force:source:push || exit 1
