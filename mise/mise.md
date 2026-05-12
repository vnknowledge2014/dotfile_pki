# mise

- mise as next generation of asdf, can manage everything from python, node, 

- <https://betterstack.com/community/guides/scaling-nodejs/mise-vs-asdf/>
    - mise started as asdf's spiritual successor but diverged into something different. It matches asdf's core functionality while adding environment variable management, task running, and built-in support for popular languages. The tool aims to replace not just asdf, but also direnv and make
    - The tool maintains compatibility with asdf's plugin ecosystem
    - mise goes beyond version switching. It replaces direnv for environment variable management and provides a task runner for common project commands



- sample command - mise ko cần add plugin và use được luôn

```bash
mise ls-remote node
# Install Node directly (no plugin needed)
mise use --global node@20.10.0

# Or for the current project
mise use node@20.10.0

# Install and set in one command
cd my-project
mise use node@20.10.0 python@3.11
```

- file .tool-versions

```bash
nodejs 20.10.0
ruby 3.2.2
python 3.11.0
terraform 1.6.0
```

- thay thế .envrc

```bash
# You need a separate tool like direnv
$ cat .envrc
export DATABASE_URL="postgresql://localhost/myapp"
export API_KEY="secret-key-here"
export NODE_ENV="development"

# With direnv configured
$ cd my-project
direnv: loading ~/my-project/.envrc
direnv: export +DATABASE_URL +API_KEY +NODE_ENV
```



```bash
# .mise.toml
[tools]
node = "20.10.0"

[env]
DATABASE_URL = "postgresql://localhost/myapp"
NODE_ENV = "development"
_.file = ".env"  # Load from .env file
_.path = "/usr/local/bin"  # Add to PATH

# Or use inline in .tool-versions
# mise env add API_KEY=secret
```

- mise includes a built-in task runner

- mise native support cho node, python, ruby, java, go, ... ko cần install plugins. Có thể install asdh plugins nếu cần


```bash
# Built-in support for major languages
$ mise use python@3.11  # No plugin needed

# asdf plugins work too
$ mise plugin install elixir https://github.com/asdf-vm/asdf-elixir
$ mise install elixir@1.15.0

# List plugins
$ mise plugins ls
elixir      https://github.com/asdf-vm/asdf-elixir
```

- dùng với cloud tool

```bash
mise use gcloud@latest
mise use scaleway@latest
```
