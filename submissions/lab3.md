# Lab 3 submission

# I CHOOSE GITHUB ACTIONS PATH

## 1.2
### a

ubuntu-24.04 is a sertain, stable, LTS version of OS. It's been out for several years, therefore, tests've been done, vulnerabilities - fixed. This label will run the same OS every run. No random unknown changes. Meanwhile, ubuntu-latest can be changed to some new, not tested OS ad can break anything at any moment

### b

Split -> runs in paralel -> faster. Also, much more clear, as I can see, witch point caused failure. In united job afret first failure other checks woun't be done at all.

### c

An attacker can, possibly, change the version tag and make VM execude someone other's code. By pinning exact commit I make CI use exact checked commit, therefore there wouldn't be such vulnearbility.

### d

Permission shows what GH workflow can do with repository. Principle - least priveledge. It means, that is someone can do their job without some priveledge - this someone shouldn't have this priveledge. 

![branch rulset updated](image.png)

## Bad commit screenshot

![alt text](image-1.png)

## Logs

![alt text](image-3.png)

## Fix commit screenshot

![alt text](image-2.png)

![link to good commit] (https://github.com/Long1Tail/DevOps-Intro/pull/3/changes/61ce79952dde9ed59597353acb487e23c208eb24)

