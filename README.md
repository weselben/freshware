# Frosh Plugin Install Command

Following command Installs and enables all so called "Frosh" Plugins.

```sh
bin/console plugin:list | grep 'Frosh' | awk '{print $1}' | xargs -I{} bin/console plugin:install -a {}
```
