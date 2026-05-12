# mise commands that I use

```bash
mise use python@3.14.4
mise use uv@latest


mise use --global java@21
mise use --global terraform@latest

mise ls-remote awscli
mise use --global awscli@latest
mise ls-remote databricks-cli
mise use --global databricks-cli@latest
mise use -g node@latest

mise use --global spark@4.1.1

MISE_HTTP_TIMEOUT=600 mise use --global spark@4.1.1

mise plugin install spark https://github.com/mise-plugins/mise-spark

mise uninstall spark@3.5.1

source ~/.zshrc
```

- current tool


```bash
mise ls

Tool            Version  Source                      Requested
awscli          2.34.45  ~/.config/mise/config.toml  latest
databricks-cli  0.299.1  ~/.config/mise/config.toml  latest
java            21.0.2   ~/.config/mise/config.toml  21
node            26.1.0   ~/.config/mise/config.toml  latest
python          3.14.4   ~/.tool-versions            3.14.4
terraform       1.15.2   ~/.config/mise/config.toml  latest
uv              0.11.13  ~/.config/mise/config.toml  0.11.13
```