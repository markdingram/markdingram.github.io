---
title: Docker Volumes on host with SELinux
categories: [blog]
tags: [docker, selinux]
---


(A reminder for next time I end up scratching my head on this)

When mounting a Volume on a host with SELinux enabled use the add a trailing `:Z` to the volume syntax, e.g.:

```
docker run -v /var/db:/var/db:Z rhel7 /bin/sh
```

This will label the mounted directory to allow access from the container - read more here:

<http://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux>
