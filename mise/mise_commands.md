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
# spark 4.1.1 might be too new to be install
mise use --global spark@4.1.0

mise plugin install spark https://github.com/mise-plugins/mise-spark



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
spark           4.1.0    ~/.config/mise/config.toml  4.1.0
terraform       1.15.2   ~/.config/mise/config.toml  latest
uv              0.11.13  ~/.config/mise/config.toml  0.11.13
```