# Ingtester

Doctests for kubernetes ingresses

## Usage

Add asserts or refutes to an `*.ingress.yaml` file
``` yaml
# assert: /api/foo
# assert: /api/foo/bar
# refute: /api/v1/foo
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: api-ingress
spec:
  rules:
  - host: example.com
    http:
      paths:
      - path: /api/foo
        backend:
          serviceName: api
          servicePort: 80
---
```

Run: 

``` bash
ingtester test
```

##  Developing

You need Esy, you can install the beta using [npm][]:

    % npm install -g esy

Then you can install the project dependencies using:

    % esy install

Then build the project dependencies along with the project itself:

    % esy build

Now you can run your editor within the environment (which also includes merlin):

    % esy $EDITOR
    % esy vim

After you make some changes to source code, you can re-run project's build
using:

    % esy build

And test compiled executable:

    % esy ./_build/default/bin/ingtester.exe

Shell into environment:

    % esy shell
