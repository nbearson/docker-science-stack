# science-stack-docker
mostly for automated builds, but the cheatsheat for non-automated:
```bash
docker build -t nbearson/science-stack .
docker run -t -i nbearson/science-stack /bin/bash
docker run -it --rm -v "$PWD":/workspace -w /workspace nbearson/science-stack /bin/bash
docker push nbearson/science-stack
```
