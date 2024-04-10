# Info

```sh
./download_tools.sh

podman build -t web-terminal-tooling:local .
podman run -it --rm -v $(pwd):/data:z web-terminal-tooling:local /bin/bash
```
