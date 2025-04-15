## Auto-Install
Project **Auto-Install** aim to create an ISO image for easy **unattended installation** of [archlinux](https://archlinux.org)

This project creates ISO image which is suitable for installation in cloud environment and environments requiring unattended installation.

---

### Usage
- Fork this repo or clone it.
    - If cloning
    ```bash
    git clone https://github.com/0xguava/auto-install.git
    cd auto-install
    ```
    - Or else fork it.

- Put the user credentials and hostname in the `config.json` file.

Eg.
```json
{
        "hostname": "arch",
        "adduser": "y",
        "credentials": {
                "username": "lol",
                "password": "lol",
                "rootpassword": "lol"
        }
}
```
**NOTE: adduser can be only set to `y/n` indicating whether to add a normal user or not. If not willing to add user then leave `username` and `password` blank.**

- Do not forget to add root password in `config.json`

- Next create a git tag

`git tag autoins.lolconfig`

`lolconfig` can be different in your case keep it as you like but do not change the `autoins.` part.

- Now push the just created git tag.

`git push origin autoins.lolconfig`

**NOTE: By using git tag you can have your custom unattended installation iso in releases section for easy download**

- Simply add, commit and push `config.json`

---

### Contributer
- [0xguava](https://0xgauva.github.io/)
- [shivjeet1](https://shivjeet1.github.io)


