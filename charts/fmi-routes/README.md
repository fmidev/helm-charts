# fmi-routes

This chart helps you to add routes to your service.

## Example values.yaml

Let's assume that the project name is `project-name`.

```
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
        insecureEdgeTerminationPolicy: Allow
      type: external
```

## Configuration

Parameter configuration prefix in the `values.yaml` is assumed to be `fmi-routes.routes.project-name-default`

| Parameter       | Description                                        | Default |
| --------------- | -------------------------------------------------- | ------- |
| `enabled`       | Is the route enabled?                              | false   |
| `annotations`   | Custom annotations to Openshift                    | ""      |
| `host`          | Host name of the service. More documentation below | ""      |
| `targetPort`    | Port of the service which should be exposed        |         |
| `targetService` | Service name which should be exposed               |         |
| `tls`           | TLS settings, more documentation below             |         |
| `type`          |                                                    |         |

### host

TODO explain host settings

### tls

TODO explain tls settings

### type

TODO explain type settings
