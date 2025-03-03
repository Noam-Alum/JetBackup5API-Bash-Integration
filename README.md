# JetBackup5API Bash integration

![made-with-bash](https://img.shields.io/badge/Made%20with-Bash-1f425f.svg)

JetBackup5API-Bash-Library is a Bash library that provides full access to the [JetBackup 5 API](https://docs.jetbackup.com/v5.3/api/).

![Hero](https://docs.jetbackup.com/v5.3/images/jetbackup_solid_navbar.png)

### How to use

**You can either source via `curl`:**
```bash
#!/bin/bash
source <(curl -LS "https://raw.githubusercontent.com/Noam-Alum/JetBackup5API-Bash-Integration/refs/heads/main/jb5_integration.bash")

jb5api::listAccounts --request '.data.accounts[-1].username'
.
.
```

**Or download it and source directly:**
```bash
#!/bin/bash
source jb5_integration.bash

jb5api::listAccounts --request '.data.accounts[-1].username'
.
.
```

### Simple example of usage:

![img](examples/create_backup/create_backup.gif)

Click here for full documentation:

[![Documentation Button](https://readme-components.vercel.app/api?component=button&text=Documentation)](docs/README.md)

---

> [!TIP]
> Click [here](https://docs.jetbackup.com/v5.3/api/) for JetBackup5APIs documentation.