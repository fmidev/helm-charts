# RPM Repository API

This chart provides an https endpoint that can be used to upload rpm packages to FMI rpm repository. Basic authentication is used to protect the endpoint from unauthorized use.

Endpoints are used by github actions running from public git repositories.

Every directory in the rpm repository (for example: x86_64, debug, srpm) is a separate endpoint.

# Chart Configuration

| Parameter | Description | Default |
|---|---|---|
| resources.nginx.limits.cpu | Nginx CPU limit| 500m |
| resources.nginx.limits.memory | Nginx memory limit| 512Mi |
| resources.nginx.requests.cpu | Nginx CPU request| 500m |
| resources.nginx.requests.memory | Nginx memory request | 512Mi |
| resources.yumapi.limits.cpu | yumapi CPU limit| 500m |
| resources.yumapi.limits.memory | yumapi memory limit| 512Mi |
| resources.yumapi.requests.cpu | yumapi CPU request| 500m |
| resources.yumapi.requests.memory | yumapi memory request | 256Mi |
| repo.path | Relative path to repository directory on disk | |
| repo.host | Hostname of the exposed api (no protocol) | |


# Installing the Chart

This chart requires privileges that are granted by the sysadmin:

* Permission to do nfs-mounts
* Permission to run using a specific group id (1888)

Example repository:

* name: myrepo
* distribution: rhel8
* directory: x86_64



```
# create project
oc new-project myproject

# create password authentication
htpasswd -c auth <USERNAME>
oc create secret generic auth --from-file=auth

# install chart
helm install myrepo-rhel8 -f values.yaml --set repo.path=path/to/myrepo/rhel/8/x86_64 --set repo.host=myrepo-rhel8-api.out.ock.fmi.fi .
```

# Using the API

```
curl -u USER:PASS -F file=@/path/to/some.rpm \ 
     https://myrepo-rhel8-api.out.ock.fmi.fi/api/upload
```
