# fmi-routes

This chart helps you to add routes to your service.

## Example values.yaml

Let's assume that the project name is `project-name`.

```yaml
fmi-routes:
  routes:
    project-name-default:
      enabled: true
      annotations:
        haproxy.router.openshift.io/timeout: 90s
      host: project-name.out.ock.fmi.fi
      targetPort: project-name-port
      targetService: project-name-service
      tls:
        termination: edge
        insecureEdgeTerminationPolicy: Redirect
      type: external
```

## Configuration

Parameter configuration prefix in the `values.yaml` is assumed to be `fmi-routes.routes.project-name-default`

| Parameter       | Description                                        | Default |
| --------------- | -------------------------------------------------- | ------- |
| `enabled`       | Is the route enabled?                              | false   |
| `annotations`   | Custom annotations to Openshift                    | ""      |
| `host`          | Host name of the service. More documentation below | ""      |
| `targetPort`    | Port of the service which should be exposed        | ""      |
| `targetService` | Service name which should be exposed               | ""      |
| `tls`           | TLS settings, more documentation below             | ""      |
| `type`          | TODO what is this?                                 | ?       |

### `host`

Openshift is configured to parse the host variable as follows. The parameter `host` must be given in form `project-name.[out|apps].[ock|ocp].fmi.fi` where

- `out`: the route is visible to the internet
- `apps`: the rout is visible only to FMI network and no to the internet
- `ock`: the route is in ock (development) cluster
- `ocp`: the route is in ocp (production) cluster

### `tls`

#### `tls.termination`

This settings configures how HTTPS traffic will be handled:

- `tls.termination: edge`: Terminate TLS in Openshift's haproxy(?). It means that pod will get the traffic in HTTP and won't have to terminate TLS itself
- `tls.termination: somethingelse`: The traffic to the pod will be HTTP and the application has to terminate TLS itself

#### `tls.insecureEdgeTerminationPolicy`

This setting configures what to do when the application gets HTTP traffic

- `tls.insecureEdgeTerminationPolicy: redirect`: Makes a redirect so that all HTTP -> HTTPS
- `tls.insecureEdgeTerminationPolicy: allow`: Allows HTTP traffic

### `type`

- `type: external`: TODO what is this and what are the other options?
